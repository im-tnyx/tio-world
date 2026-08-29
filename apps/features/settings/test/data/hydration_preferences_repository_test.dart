import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  test('no row, set 250, read, update 300, clear remain account-scoped ml only',
      () async {
    final gateway = _Gateway();
    var user = 'user-a';
    final repository = _repository(gateway, () => user);
    expect(await repository.read(), isNull);
    for (final value in <int?>[250, 300, null]) {
      await repository.upsert(HydrationPreferences(defaultGlassSizeMl: value));
      expect(await repository.read(),
          HydrationPreferences(defaultGlassSizeMl: value));
      expect(gateway.writes.last.keys.toSet(),
          {'user_id', 'default_glass_size_ml'});
      expect(gateway.writes.last['user_id'], 'user-a');
    }
    await repository
        .upsert(const HydrationPreferences(defaultGlassSizeMl: 250));
    user = 'user-b';
    expect(await repository.read(), isNull);
    await repository
        .upsert(const HydrationPreferences(defaultGlassSizeMl: 500));
    user = 'user-a';
    expect((await repository.read())!.defaultGlassSizeMl, 250);
    expect(gateway.rows['user-b']!['default_glass_size_ml'], 500);
  });

  for (final user in <String?>[null, '', ' ']) {
    test('signed-out/empty identity $user cannot reach write gateway',
        () async {
      final gateway = _Gateway();
      final repository = _repository(gateway, () => user);
      expect(await repository.read(), isNull);
      await expectLater(
          repository.upsert(const HydrationPreferences()), throwsStateError);
      expect(gateway.reads, isEmpty);
      expect(gateway.writes, isEmpty);
    });
  }

  test('invalid writes rejected before any IO', () async {
    final gateway = _Gateway();
    final repository = _repository(gateway, () => 'user-a');
    for (final value in [40, 49, 55, 255, 2001, 2010]) {
      await expectLater(
          repository.upsert(HydrationPreferences(defaultGlassSizeMl: value)),
          throwsArgumentError);
    }
    expect(gateway.writes, isEmpty);
  });

  test('malformed rows fail rather than inventing unset/default/rounded values',
      () async {
    final gateway = _Gateway();
    final repository = _repository(gateway, () => 'user-a');
    for (final row in <Map<String, dynamic>>[
      {},
      for (final value in ['250', 250.0, 255, -10, 2010])
        {'default_glass_size_ml': value},
    ]) {
      gateway.rows['user-a'] = row;
      await expectLater(repository.read(), throwsFormatException);
    }
  });

  test('read/write errors remain failures and a later write can retry',
      () async {
    final gateway = _Gateway()..fail = true;
    final repository = _repository(gateway, () => 'user-a');
    await expectLater(repository.read(), throwsStateError);
    await expectLater(
        repository.upsert(const HydrationPreferences(defaultGlassSizeMl: 250)),
        throwsStateError);
    gateway.fail = false;
    await repository
        .upsert(const HydrationPreferences(defaultGlassSizeMl: 250));
    expect((await repository.read())!.defaultGlassSizeMl, 250);
  });

  test(
      'account switch while a read is in flight rejects the old account result',
      () async {
    var user = 'user-a';
    final gateway = _Gateway()..readGate = Completer<void>();
    final repository = _repository(gateway, () => user);
    final read = repository.read();
    final assertion = expectLater(read, throwsStateError);
    user = 'user-b';
    gateway.readGate!.complete();
    await assertion;
  });

  test(
      'actual Supabase gateway targets only hydration table with own-row filter/conflict',
      () async {
    final transport = _Transport();
    final client = SupabaseClient('https://example.invalid', 'test-public-key',
        httpClient: transport);
    addTearDown(client.dispose);
    final gateway = SupabaseHydrationPreferencesTableGateway(client);
    expect(await gateway.readRow('user-a'), {'default_glass_size_ml': 250});
    await gateway
        .upsertRow({'user_id': 'user-a', 'default_glass_size_ml': null});
    expect(transport.requests.map((r) => r.url.path),
        everyElement('/rest/v1/user_hydration_preferences'));
    expect(
        transport.requests.first.url.queryParameters['user_id'], 'eq.user-a');
    expect(transport.requests.first.url.queryParameters['select'],
        'default_glass_size_ml');
    expect(
        transport.requests.last.url.queryParameters['on_conflict'], 'user_id');
    expect(jsonDecode(transport.bodies.last),
        {'user_id': 'user-a', 'default_glass_size_ml': null});
  });

  test(
      'account switch during write cannot publish success or target the new account',
      () async {
    var user = 'user-a';
    final gateway = _Gateway()..writeGate = Completer<void>();
    final repository = _repository(gateway, () => user);
    final write =
        repository.upsert(const HydrationPreferences(defaultGlassSizeMl: 250));
    final assertion = expectLater(write, throwsStateError);
    user = 'user-b';
    gateway.writeGate!.complete();
    await assertion;
    expect(gateway.writes.single['user_id'], 'user-a');
    expect(gateway.rows.containsKey('user-b'), isFalse);
  });

  test('account-bound old editor cannot write after a new login', () async {
    var current = 'user-a';
    final gateway = _Gateway();
    final repository =
        _repository(gateway, () => current == 'user-a' ? 'user-a' : null);
    current = 'user-b';
    await expectLater(
        repository.upsert(const HydrationPreferences(defaultGlassSizeMl: 250)),
        throwsStateError);
    expect(gateway.writes, isEmpty);
  });
}

SupabaseHydrationPreferencesRepository _repository(
        _Gateway gateway, CurrentHydrationUserId userId) =>
    SupabaseHydrationPreferencesRepository(
        client: _UnusedClient(), gateway: gateway, currentUserId: userId);

class _UnusedClient extends Fake implements SupabaseClient {}

class _Gateway implements HydrationPreferencesTableGateway {
  final rows = <String, Map<String, dynamic>>{};
  final reads = <String>[];
  final writes = <Map<String, dynamic>>[];
  var fail = false;
  Completer<void>? readGate;
  Completer<void>? writeGate;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    reads.add(userId);
    await readGate?.future;
    if (fail) throw StateError('read failure');
    return rows[userId];
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    await writeGate?.future;
    if (fail) throw StateError('write failure');
    writes.add(Map.of(payload));
    rows[payload['user_id'] as String] = Map.of(payload);
  }
}

class _Transport extends http.BaseClient {
  final requests = <http.BaseRequest>[];
  final bodies = <String>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    bodies.add(await request.finalize().bytesToString());
    return http.StreamedResponse(
      Stream.value(utf8.encode(
          request.method == 'GET' ? '{"default_glass_size_ml":250}' : '')),
      request.method == 'GET' ? 200 : 201,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}
