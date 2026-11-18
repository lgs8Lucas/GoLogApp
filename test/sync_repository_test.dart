import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:golog/data/datasource/local/coordinate_sql_service.dart';
import 'package:golog/data/datasource/local/credential_store.dart';
import 'package:golog/data/datasource/local/occurrence_sql_service.dart';
import 'package:golog/data/datasource/local/sql_service.dart';
import 'package:golog/data/datasource/local/user_sql_service.dart';
import 'package:golog/data/datasource/remote/api_service.dart';
import 'package:golog/data/model/occurrence.dart';
import 'package:golog/data/repository/sync_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MemoryCredentials extends CredentialStore {
  String? token = 'tok';
  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> saveToken(String t) async => token = t;
  @override
  Future<String?> getPassword() async => null;
}

Occurrence _occ(String deliveryId) => Occurrence(
  type: OccurrenceType.Fim.name,
  description: '',
  attachment: '',
  deliveryId: deliveryId,
  transportId: 't1',
  senderId: 'u1',
  isSynced: false,
  dateTime: DateTime.now(),
);

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late SqlService sql;
  late OccurrenceSqlService occurrences;
  late _MemoryCredentials credentials;

  setUp(() async {
    final path = join(await getDatabasesPath(), 'sync_test.db');
    await databaseFactory.deleteDatabase(path);
    credentials = _MemoryCredentials();
    sql = await SqlService(credentials, dbName: 'sync_test.db').init();
    occurrences = OccurrenceSqlService(sql.db);
  });

  tearDown(() => sql.db.close());

  SyncRepository repo(MockClientHandler handler) {
    final api = ApiService(
      credentials,
      UserSqlService(sql.db),
      MockClient(handler),
    );
    return SyncRepository(
      api,
      credentials,
      occurrences,
      CoordinateSqlService(sql.db),
    );
  }

  test('envia ocorrência pendente', () async {
    await occurrences.insertOccurrence(_occ('d1'));
    final sent = <String>[];
    final r = repo((req) async {
      sent.add(req.url.path);
      return http.Response('{}', 201);
    });

    expect(await r.sync(), SyncResult.done);
    expect(sent, ['/occurrence']);
    expect(await occurrences.countUnsynced(), 0);
  });

  test('ocorrência criada durante um envio sai na mesma chamada', () async {
    await occurrences.insertOccurrence(_occ('d1'));
    late SyncRepository r;
    var requests = 0;
    r = repo((req) async {
      requests++;
      if (requests == 1) {
        // Motorista registra outra entrega enquanto a 1ª está subindo.
        await occurrences.insertOccurrence(_occ('d2'));
        unawaited(r.sync());
      }
      return http.Response('{}', 201);
    });

    await r.sync();
    expect(requests, 2);
    expect(await occurrences.countUnsynced(), 0);
  });

  test(
    'sem conexão: resultado offline e ocorrência continua pendente',
    () async {
      await occurrences.insertOccurrence(_occ('d1'));
      await occurrences.insertOccurrence(_occ('d2'));
      var requests = 0;
      final r = repo((req) async {
        requests++;
        throw const SocketException('sem rede');
      });

      expect(await r.sync(), SyncResult.offline);
      expect(requests, 1, reason: 'não deve esperar timeout de cada item');
      expect(await occurrences.countUnsynced(), 2);
    },
  );

  test(
    'rejeição do servidor mantém pendente e segue para as próximas',
    () async {
      await occurrences.insertOccurrence(_occ('d1'));
      await occurrences.insertOccurrence(_occ('d2'));
      var requests = 0;
      final r = repo((req) async {
        requests++;
        return http.Response('{}', requests == 1 ? 400 : 201);
      });

      expect(await r.sync(), SyncResult.done);
      expect(await occurrences.countUnsynced(), 1);
    },
  );

  test('sem usuário logado não envia nada', () async {
    credentials.token = null;
    await occurrences.insertOccurrence(_occ('d1'));
    var requests = 0;
    final r = repo((req) async {
      requests++;
      return http.Response('{}', 201);
    });

    expect(await r.sync(), SyncResult.skipped);
    expect(requests, 0);
  });

  group('limpeza de ocorrências enviadas', () {
    Future<int> insert(
      String deliveryId, {
      required bool synced,
      int daysAgo = 10,
    }) => occurrences.insertOccurrence(
      Occurrence(
        type: OccurrenceType.Fim.name,
        description: '',
        attachment: '',
        deliveryId: deliveryId,
        transportId: 't1',
        senderId: 'u1',
        isSynced: synced,
        dateTime: DateTime.now().subtract(Duration(days: daysAgo)),
      ),
    );

    test('mantém as de entregas ainda não finalizadas no servidor', () async {
      await insert('aberta', synced: true);
      await insert('fechada', synced: true);
      final deleted = await occurrences.purgeSynced(
        const Duration(days: 7),
        keepDeliveryIds: {'aberta'},
      );
      expect(deleted, 1);
      final left = await occurrences.get(null, null);
      expect(left.single.deliveryId, 'aberta');
    });

    test('nunca apaga pendentes nem recentes', () async {
      await insert('d1', synced: false);
      await insert('d2', synced: true, daysAgo: 1);
      final deleted = await occurrences.purgeSynced(
        const Duration(days: 7),
        keepDeliveryIds: {},
      );
      expect(deleted, 0);
    });
  });
}
