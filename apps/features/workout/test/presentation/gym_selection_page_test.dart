import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

final class _DeferredGymRepository implements GymLocationRepository {
  final Map<String, Completer<List<GymLocation>>> responses = {};
  final List<String> queries = [];

  @override
  Future<List<GymLocation>> searchGyms({
    double? latitude,
    double? longitude,
    String? query,
    int? radiusMeters,
  }) {
    final key = query ?? '<initial>';
    queries.add(key);
    return responses.putIfAbsent(key, Completer<List<GymLocation>>.new).future;
  }
}

final class _EmptyGymRepository implements GymLocationRepository {
  @override
  Future<List<GymLocation>> searchGyms({
    double? latitude,
    double? longitude,
    String? query,
    int? radiusMeters,
  }) async =>
      const [];
}

final class _RecordingGymRepository implements GymLocationRepository {
  double? latitude;
  double? longitude;

  @override
  Future<List<GymLocation>> searchGyms({
    double? latitude,
    double? longitude,
    String? query,
    int? radiusMeters,
  }) async {
    this.latitude = latitude;
    this.longitude = longitude;
    return const [];
  }
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [TioColors.dark]),
      home: child,
    );

GymLocation _gym(String id, String name) => GymLocation(
      id: id,
      name: name,
      address: '$name address',
    );

Position _position() => Position(
      longitude: 77.5,
      latitude: 28.6,
      timestamp: DateTime.utc(2026, 11, 9),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  testWidgets('latest gym search wins over stale search and initial results',
      (tester) async {
    final repository = _DeferredGymRepository();
    await tester.pumpWidget(
      _wrap(
        GymSelectionPage(
          repository: repository,
          positionProvider: () async => null,
        ),
      ),
    );
    await tester.pump();

    final search = find.byKey(const ValueKey('gym-search-input'));
    await tester.enterText(search, 'Older');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(search, 'Newest');
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.queries, ['<initial>', 'Older', 'Newest']);
    repository.responses['Newest']!.complete([_gym('newest', 'Newest Gym')]);
    await tester.pumpAndSettle();

    repository.responses['Older']!.complete([_gym('older', 'Older Gym')]);
    repository.responses['<initial>']!
        .complete([_gym('initial', 'Initial Gym')]);
    await tester.pumpAndSettle();

    expect(find.text('Newest Gym'), findsOneWidget);
    expect(find.text('Older Gym'), findsNothing);
    expect(find.text('Initial Gym'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('location permission prompt is awaited beyond one second',
      (tester) async {
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    final permissionResult = Completer<Object?>();
    var permissionRequested = false;
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
          return 0;
        case 'requestPermission':
          permissionRequested = true;
          return permissionResult.future;
        case 'getCurrentPosition':
          return _position().toJson();
        default:
          throw PlatformException(code: 'unexpected_method');
      }
    });

    final repository = _RecordingGymRepository();
    await tester.pumpWidget(
      _wrap(
        GymSelectionPage(repository: repository),
      ),
    );
    await tester.pump();
    expect(permissionRequested, isTrue);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));

    expect(repository.latitude, isNull);
    expect(repository.longitude, isNull);

    permissionResult.complete(2);
    await tester.pumpAndSettle();

    expect(repository.latitude, 28.6);
    expect(repository.longitude, 77.5);
    expect(find.text('Nearby gyms'), findsNothing);
  });

  testWidgets('empty location results do not show fabricated nearby gyms',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        GymSelectionPage(
          repository: _EmptyGymRepository(),
          positionProvider: () async => _position(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home gym'), findsOneWidget);
    expect(find.text('Popular gyms'), findsNothing);
    expect(find.text('Nearby gyms'), findsNothing);
    expect(find.textContaining('Jaipur'), findsNothing);
  });

  testWidgets(
      'denied location permission shows Allow location option and retries',
      (tester) async {
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    var checkCalls = 0;
    var requestCalls = 0;
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
          checkCalls++;
          return 0; // denied until the user grants via requestPermission
        case 'requestPermission':
          requestCalls++;
          return requestCalls >= 2 ? 2 : 0;
        case 'getCurrentPosition':
          return _position().toJson();
        default:
          throw PlatformException(code: 'unexpected_method');
      }
    });

    final repository = _RecordingGymRepository();
    await tester.pumpWidget(
      _wrap(GymSelectionPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Allow location'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gym-location-permission-option')),
      findsOneWidget,
    );
    expect(repository.latitude, isNull);
    expect(requestCalls, 1);

    await tester
        .tap(find.byKey(const ValueKey('gym-location-permission-option')));
    await tester.pumpAndSettle();

    expect(requestCalls, 2);
    expect(checkCalls, greaterThanOrEqualTo(2));
    expect(repository.latitude, 28.6);
    expect(find.text('Allow location'), findsNothing);
  });

  testWidgets(
      'permanently denied location shows Open settings option', (tester) async {
    const channel = MethodChannel('flutter.baseflow.com/geolocator');
    var openedSettings = false;
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
          return 1; // deniedForever
        case 'openAppSettings':
          openedSettings = true;
          return true;
        default:
          throw PlatformException(code: 'unexpected_method');
      }
    });

    await tester.pumpWidget(
      _wrap(GymSelectionPage(repository: _EmptyGymRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open settings'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('gym-location-permission-option')));
    await tester.pumpAndSettle();
    expect(openedSettings, isTrue);
  });
}
