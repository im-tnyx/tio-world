import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_app/app/profile/profile_avatar_upload.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

/// Records what the upload boundary was asked to do, and lets a case decide
/// when — or whether — the upload future completes.
class _FakeAvatarRepository implements ProfileAvatarRepository {
  _FakeAvatarRepository({this.completer, this.failWith});

  /// When set, the upload only finishes once the case completes it. That is
  /// what makes "no message before the upload resolves" provable rather than
  /// merely likely.
  final Completer<String>? completer;
  final Object? failWith;

  final uploads = <({String fileName, List<int> bytes})>[];
  var deleteCalls = 0;

  @override
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  }) async {
    uploads.add((fileName: fileName, bytes: bytes));
    if (failWith != null) throw failWith!;
    if (completer != null) return completer!.future;
    return 'https://example.test/$fileName';
  }

  @override
  Future<void> deleteAvatarImage() async => deleteCalls++;
}

/// Hosts the helper in a real widget so `context.mounted`, the
/// `ScaffoldMessenger` lookup and the snack bar all behave as they do in the
/// app, rather than being stubbed away.
class _Host extends ConsumerWidget {
  const _Host({required this.source, this.onError});

  final TioImageSource source;
  final void Function(Object error)? onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await pickAndUploadProfileImage(
                ref: ref,
                context: context,
                source: source,
              );
            } catch (error) {
              onError?.call(error);
            }
          },
          child: const Text('Pick'),
        ),
      ),
    );
  }
}

/// Mutable so a case can read the count *after* acting. Returning a plain int
/// would hand back a snapshot taken before the tap, which cannot observe an
/// invalidation at all.
class _BuildCounter {
  var value = 0;
}

Future<_BuildCounter> _pumpHost(
  WidgetTester tester, {
  required ProfileImagePicker picker,
  required ProfileAvatarRepository repository,
  TioImageSource source = TioImageSource.gallery,
  void Function(Object error)? onError,
}) async {
  // Counts how many times the profile stream was rebuilt, which is how
  // invalidation is observed without reaching into Riverpod internals.
  final profileBuilds = _BuildCounter();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileImagePickerProvider.overrideWithValue(picker),
        profileAvatarRepositoryProvider.overrideWithValue(repository),
        profileDataProvider.overrideWith((ref) {
          profileBuilds.value++;
          return Stream<ProfileSetupData?>.value(null);
        }),
      ],
      child: MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Consumer(
          builder: (context, ref, _) {
            // Watched so the override actually runs and invalidation rebuilds.
            ref.watch(profileDataProvider);
            return _Host(source: source, onError: onError);
          },
        ),
      ),
    ),
  );
  await tester.pump();

  return profileBuilds;
}

ProfileImagePicker _picks(String fileName) =>
    (source) async => (fileName: fileName, bytes: const [1, 2, 3]);

Future<PickedProfileImage?> _cancels(TioImageSource source) async => null;

void main() {
  final message = find.text(profileImageUpdatedMessage);

  group('successful upload confirms', () {
    for (final source in TioImageSource.values) {
      testWidgets('$source upload shows the confirmation', (tester) async {
        final repository = _FakeAvatarRepository();
        await _pumpHost(
          tester,
          picker: _picks('avatar.jpg'),
          repository: repository,
          source: source,
        );

        await tester.tap(find.text('Pick'));
        await tester.pumpAndSettle();

        expect(repository.uploads, hasLength(1));
        expect(message, findsOneWidget);
      });
    }

    testWidgets('replacing an existing image shows the same confirmation',
        (tester) async {
      final repository = _FakeAvatarRepository();
      await _pumpHost(
        tester,
        picker: _picks('replacement.jpg'),
        repository: repository,
      );

      // Replace is the same entry point run twice; the second upload has to
      // confirm just like the first.
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(repository.uploads, hasLength(2));
      expect(repository.uploads.last.fileName, 'replacement.jpg');
      expect(message, findsOneWidget);
    });

    testWidgets('the picked file reaches the upload boundary unchanged',
        (tester) async {
      final repository = _FakeAvatarRepository();
      await _pumpHost(
        tester,
        picker: _picks('holiday.png'),
        repository: repository,
      );

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(repository.uploads.single.fileName, 'holiday.png');
      expect(repository.uploads.single.bytes, const [1, 2, 3]);
    });
  });

  group('no confirmation without a successful upload', () {
    testWidgets('picker cancel uploads nothing and says nothing',
        (tester) async {
      final repository = _FakeAvatarRepository();
      await _pumpHost(
        tester,
        picker: _cancels,
        repository: repository,
      );

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(repository.uploads, isEmpty);
      expect(message, findsNothing);
    });

    testWidgets('a failed upload says nothing and surfaces the error',
        (tester) async {
      Object? captured;
      final repository = _FakeAvatarRepository(
        failWith: const SocketException('offline'),
      );
      await _pumpHost(
        tester,
        picker: _picks('avatar.jpg'),
        repository: repository,
        onError: (error) => captured = error,
      );

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(repository.uploads, hasLength(1));
      expect(captured, isA<SocketException>());
      expect(message, findsNothing);
    });

    testWidgets('a missing avatar repository says nothing', (tester) async {
      Object? captured;
      var pickerCalls = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileImagePickerProvider.overrideWithValue((source) async {
              pickerCalls++;
              return (fileName: 'avatar.jpg', bytes: const [1]);
            }),
            profileAvatarRepositoryProvider.overrideWithValue(null),
            profileDataProvider.overrideWith(
              (ref) => Stream<ProfileSetupData?>.value(null),
            ),
          ],
          child: MaterialApp(
            builder: (context, child) =>
                TioTheme(child: child ?? const SizedBox.shrink()),
            home: _Host(
              source: TioImageSource.gallery,
              onError: (error) => captured = error,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(pickerCalls, 1);
      expect(captured, isA<StateError>());
      expect(message, findsNothing);
    });
  });

  group('ordering', () {
    testWidgets('the confirmation waits for the upload future to complete',
        (tester) async {
      final completer = Completer<String>();
      final repository = _FakeAvatarRepository(completer: completer);
      await _pumpHost(
        tester,
        picker: _picks('avatar.jpg'),
        repository: repository,
      );

      await tester.tap(find.text('Pick'));
      await tester.pump();

      // Upload started, has not resolved. Nothing may be promised yet.
      expect(repository.uploads, hasLength(1));
      expect(message, findsNothing);

      completer.complete('https://example.test/avatar.jpg');
      await tester.pumpAndSettle();

      expect(message, findsOneWidget);
    });
  });

  group('profile refresh', () {
    testWidgets('a successful upload still invalidates the profile',
        (tester) async {
      final repository = _FakeAvatarRepository();
      final builds = await _pumpHost(
        tester,
        picker: _picks('avatar.jpg'),
        repository: repository,
      );
      final before = builds.value;

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      // The stream provider was rebuilt, which is the existing refresh
      // behaviour this slice must not quietly drop.
      expect(builds.value, greaterThan(before));
      expect(message, findsOneWidget);
    });

    testWidgets('a cancelled pick does not invalidate the profile',
        (tester) async {
      final repository = _FakeAvatarRepository();
      final builds = await _pumpHost(
        tester,
        picker: _cancels,
        repository: repository,
      );
      final before = builds.value;

      await tester.tap(find.text('Pick'));
      await tester.pumpAndSettle();

      expect(repository.uploads, isEmpty);
      expect(builds.value, before);
      expect(message, findsNothing);
    });
  });

  group('every entry point goes through the shared helper', () {
    // A source check rather than three route harnesses: the contract that
    // matters is that no composition rebuilds the pick/upload sequence
    // locally, which is exactly what would let one of them drift again.
    const entryPoints = [
      'lib/app/router.dart',
      'lib/app/profile/profile_settings_route.dart',
    ];

    test('no upload composition builds its own picker or upload call', () {
      for (final path in entryPoints) {
        final source = File(path).readAsStringSync();
        expect(
          source.contains('ImagePicker('),
          isFalse,
          reason: '$path should delegate picking to pickAndUploadProfileImage',
        );
        expect(
          source.contains('uploadAvatarImage('),
          isFalse,
          reason: '$path should delegate upload to pickAndUploadProfileImage',
        );
        expect(
          source.contains('pickAndUploadProfileImage('),
          isTrue,
          reason: '$path should use the shared helper',
        );
      }
    });

    test('only the shared helper emits the confirmation', () {
      final matches = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.readAsStringSync().contains(profileImageUpdatedMessage)) {
          matches.add(entity.path.replaceAll(r'\', '/'));
        }
      }

      expect(matches, hasLength(1));
      expect(matches.single, endsWith('profile/profile_avatar_upload.dart'));
    });
  });
}
