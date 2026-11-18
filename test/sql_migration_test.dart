import 'package:flutter_test/flutter_test.dart';
import 'package:golog/data/datasource/local/credential_store.dart';
import 'package:golog/data/datasource/local/sql_service.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MemoryCredentials extends CredentialStore {
  String? token;
  String? password;
  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> saveToken(String t) async => token = t;
  @override
  Future<String?> getPassword() async => password;
  @override
  Future<void> savePassword(String p) async => password = p;
}

/// Cria um banco no formato da v8 (versão anterior às mudanças).
Future<void> _createV8(String path) async {
  final db = await openDatabase(
    path,
    version: 8,
    onCreate: (db, _) async {
      await db.execute(
        'CREATE TABLE user (id TEXT PRIMARY KEY, name TEXT, token TEXT, '
        'keepConnected INTEGER, email TEXT, password TEXT)',
      );
      await db.execute(
        'CREATE TABLE coordinate (dateTime TEXT, latitude TEXT, '
        'longitude TEXT, speed REAL, alert TEXT, data1 TEXT, data2 TEXT, '
        'device TEXT, equipamentId TEXT, isSynced INTEGER)',
      );
      await db.execute(
        'CREATE TABLE occurrence (type TEXT, description TEXT, '
        'attachment TEXT, deliveryId TEXT, transportId TEXT, '
        'isSynced INTEGER, senderId TEXT, dateTime TEXT, '
        'localId INTEGER PRIMARY KEY AUTOINCREMENT)',
      );
      await db.execute('CREATE TABLE delivery (id TEXT, shedulind TEXT)');
      await db.execute('CREATE TABLE transport (id TEXT PRIMARY KEY)');
    },
  );
  await db.insert('user', {
    'id': 'u1',
    'name': 'Motorista',
    'token': 'tok',
    'keepConnected': 1,
    'email': 'a@b.c',
    'password': 'segredo',
  });
  await db.insert('coordinate', {
    'dateTime': '2026-11-17T10:00:00.000',
    'latitude': '-23.5',
    'longitude': '-46.6',
    'speed': 10.0,
    'device': 'GoLogApp',
    'equipamentId': 'e1',
    'isSynced': 0,
  });
  await db.insert('occurrence', {
    'type': 'Fim',
    'description': 'x',
    'attachment': '',
    'deliveryId': 'd1',
    'transportId': 't1',
    'isSynced': 0,
    'senderId': 'u1',
    'dateTime': '2026-11-17T10:00:00.000',
  });
  await db.close();
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('upgrade v8 -> v10 preserva pendentes e move credenciais', () async {
    final path = join(await getDatabasesPath(), 'migration_test.db');
    await databaseFactory.deleteDatabase(path);
    await _createV8(path);

    final creds = _MemoryCredentials();
    final sql = await SqlService(creds, dbName: 'migration_test.db').init();
    final db = sql.db;

    expect(creds.token, 'tok');
    expect(creds.password, 'segredo');

    final user = (await db.query('user')).single;
    expect(user['id'], 'u1');
    expect(user.containsKey('password'), isFalse);
    expect(user.containsKey('token'), isFalse);

    final coord = (await db.query('coordinate')).single;
    expect(coord['equipmentId'], 'e1');
    expect(coord['localId'], isNotNull);
    expect(coord['isSynced'], 0);
    // v10: colunas novas existem e ficam nulas nos pontos antigos.
    expect(coord.containsKey('transportId'), isTrue);
    expect(coord['transportId'], isNull);
    expect(coord['shipmentId'], isNull);

    expect(await db.query('occurrence'), hasLength(1));
    expect(await db.query('delivery'), isEmpty);

    await db.close();
    await databaseFactory.deleteDatabase(path);
  });

  test('instalação nova cria o schema v10', () async {
    final path = join(await getDatabasesPath(), 'migration_test.db');
    await databaseFactory.deleteDatabase(path);
    final sql = await SqlService(
      _MemoryCredentials(),
      dbName: 'migration_test.db',
    ).init();
    expect(await sql.db.getVersion(), 10);
    await sql.db.insert('delivery', {'id': 'd1', 'transportId': 't1'});
    await sql.db.insert('delivery', {'id': 'd1', 'transportId': 't2'});
    expect(await sql.db.query('delivery'), hasLength(2));
    await sql.db.close();
    await databaseFactory.deleteDatabase(path);
  });

  test(
    'upgrade v9 -> v10 adiciona transportId/shipmentId sem perder pontos',
    () async {
      final path = join(await getDatabasesPath(), 'migration_test.db');
      await databaseFactory.deleteDatabase(path);
      // Banco no formato da v9.
      final v9 = await openDatabase(
        path,
        version: 9,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE user (id TEXT PRIMARY KEY, name TEXT, email TEXT, '
            'keepConnected INTEGER)',
          );
          await db.execute(
            'CREATE TABLE coordinate (localId INTEGER PRIMARY KEY '
            'AUTOINCREMENT, dateTime TEXT, latitude TEXT, longitude TEXT, '
            'speed REAL, alert TEXT, data1 TEXT, data2 TEXT, device TEXT, '
            'equipmentId TEXT, isSynced INTEGER)',
          );
        },
      );
      await v9.insert('coordinate', {
        'dateTime': '2026-11-17T10:00:00.000',
        'latitude': '-22.3',
        'longitude': '-47.3',
        'equipmentId': 'e1',
        'isSynced': 0,
      });
      await v9.close();

      final sql = await SqlService(
        _MemoryCredentials(),
        dbName: 'migration_test.db',
      ).init();
      expect(await sql.db.getVersion(), 10);
      final coord = (await sql.db.query('coordinate')).single;
      expect(coord['equipmentId'], 'e1');
      expect(coord['isSynced'], 0);
      expect(coord['transportId'], isNull);
      expect(coord['shipmentId'], isNull);

      await sql.db.update('coordinate', {
        'transportId': 't1',
        'shipmentId': 's1',
      });
      expect((await sql.db.query('coordinate')).single['shipmentId'], 's1');
      await sql.db.close();
      await databaseFactory.deleteDatabase(path);
    },
  );
}
