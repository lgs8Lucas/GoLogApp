import 'package:get/get.dart';
import 'package:golog/data/datasource/local/credential_store.dart';
import 'package:golog/data/model/coordinate.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/data/model/occurrence.dart';
import 'package:golog/data/model/transport.dart';
import 'package:golog/data/model/user.dart';
import 'package:golog/util/log.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Dono da conexão SQLite. Deve ser registrado com
/// `await Get.putAsync(() => SqlService(...).init())` para que [db] já
/// esteja aberto quando os demais serviços forem criados.
class SqlService extends GetxService {
  static const int _version = 10;

  final CredentialStore _credentialStore;
  late final Database db;

  /// Nome do arquivo do banco. Só muda nos testes, para que rodem em
  /// paralelo sem compartilhar o mesmo arquivo.
  final String dbName;

  SqlService(this._credentialStore, {this.dbName = 'golog.db'});

  Future<SqlService> init() async {
    final path = join(await getDatabasesPath(), dbName);
    db = await openDatabase(
      path,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) => _createSchema(db),
      onUpgrade: _upgradeDB,
    );
    return this;
  }

  // ---------------------------------------------------------------------
  // Schema atual (v10)
  // ---------------------------------------------------------------------

  static Future<void> _createSchema(DatabaseExecutor db) async {
    await _createUser(db);
    await _createCoordinate(db);
    await _createOccurrence(db);
    await _createDelivery(db);
    await _createTransport(db);
    await _createIndexes(db);
  }

  static Future<void> _createUser(DatabaseExecutor db, [String? name]) =>
      db.execute('''
      CREATE TABLE IF NOT EXISTS ${name ?? User.tableName} (
        ${User.columnId} TEXT PRIMARY KEY,
        ${User.columnName} TEXT,
        ${User.columnEmail} TEXT,
        ${User.columnKeepConnected} INTEGER
      )
    ''');

  static Future<void> _createCoordinate(DatabaseExecutor db, [String? name]) =>
      db.execute('''
      CREATE TABLE IF NOT EXISTS ${name ?? Coordinate.tableName} (
        ${Coordinate.columnLocalId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${Coordinate.columnDateTime} TEXT,
        ${Coordinate.columnLatitude} TEXT,
        ${Coordinate.columnLongitude} TEXT,
        ${Coordinate.columnSpeed} REAL,
        ${Coordinate.columnAlert} TEXT,
        ${Coordinate.columnData1} TEXT,
        ${Coordinate.columnData2} TEXT,
        ${Coordinate.columnDevice} TEXT,
        ${Coordinate.columnEquipmentId} TEXT,
        ${Coordinate.columnIsSynced} INTEGER,
        ${Coordinate.columnTransportId} TEXT,
        ${Coordinate.columnShipmentId} TEXT
      )
    ''');

  static Future<void> _createOccurrence(DatabaseExecutor db) => db.execute('''
      CREATE TABLE IF NOT EXISTS ${Occurrence.tableName} (
        ${Occurrence.columnType} TEXT,
        ${Occurrence.columnDescription} TEXT,
        ${Occurrence.columnAttachment} TEXT,
        ${Occurrence.columnDeliveryId} TEXT,
        ${Occurrence.columnTransportId} TEXT,
        ${Occurrence.columnIsSynced} INTEGER,
        ${Occurrence.columnSenderId} TEXT,
        ${Occurrence.columnDateTime} TEXT,
        ${Occurrence.columnLocalId} INTEGER PRIMARY KEY AUTOINCREMENT
      )
    ''');

  static Future<void> _createDelivery(DatabaseExecutor db) => db.execute('''
      CREATE TABLE IF NOT EXISTS ${Delivery.tableName} (
        ${Delivery.columnId} TEXT NOT NULL,
        ${Delivery.columnWeight} REAL,
        ${Delivery.columnVolume} REAL,
        ${Delivery.columnScheduledDate} TEXT,
        ${Delivery.columnRoutePlanned} TEXT,
        ${Delivery.columnRouteCompleted} TEXT,
        ${Delivery.columnStatus} TEXT,
        ${Delivery.columnDeliverySequence} INTEGER,
        ${Delivery.columnDeliveryTypeId} TEXT,
        ${Delivery.columnTransportId} TEXT NOT NULL,
        ${Delivery.columnDestinationAddress} TEXT,
        ${Delivery.columnRecipientName} TEXT,
        ${Delivery.columnDestinationLat} REAL,
        ${Delivery.columnDestinationLng} REAL,
        ${Delivery.columnIsPickup} INTEGER,
        PRIMARY KEY (${Delivery.columnId}, ${Delivery.columnTransportId})
      )
    ''');

  static Future<void> _createTransport(DatabaseExecutor db) => db.execute('''
      CREATE TABLE IF NOT EXISTS ${Transport.tableName} (
        ${Transport.columnId} TEXT PRIMARY KEY,
        ${Transport.columnRoutePlanned} TEXT,
        ${Transport.columnRouteCompleted} TEXT,
        ${Transport.columnDeliveryQuantity} INTEGER,
        ${Transport.columnTimeStopped} REAL,
        ${Transport.columnTotalTime} REAL,
        ${Transport.columnCodeTransport} INTEGER,
        ${Transport.columnDriverId} TEXT,
        ${Transport.columnTransporterId} TEXT,
        ${Transport.columnEquipmentGroupId} TEXT,
        ${Transport.columnEquipmentId} TEXT,
        ${Transport.columnPlate} TEXT
      )
    ''');

  static Future<void> _createIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_occurrence_synced '
      'ON ${Occurrence.tableName} (${Occurrence.columnIsSynced})',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_occurrence_delivery '
      'ON ${Occurrence.tableName} (${Occurrence.columnDeliveryId})',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_coordinate_synced '
      'ON ${Coordinate.tableName} (${Coordinate.columnIsSynced})',
    );
  }

  // ---------------------------------------------------------------------
  // Migrações
  // ---------------------------------------------------------------------
  //
  // Cada versão nova ganha um passo em [_migrations], executado em ordem.
  // Regra: `occurrence` e `coordinate` podem ter registros ainda não
  // sincronizados — nunca são apagadas, só migradas. `delivery` e
  // `transport` só espelham o servidor e podem ser recriadas.

  late final Map<int, Future<void> Function(DatabaseExecutor)> _migrations = {
    9: _migrateTo9,
    10: _migrateTo10,
  };

  // O sqflite já executa onUpgrade dentro de uma transação: se qualquer
  // passo falhar, o banco volta inteiro para a versão anterior.
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 8) await _legacyUpgrade(db);
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      final step = _migrations[v];
      if (step != null) await step(db);
    }
  }

  /// Comportamento das versões < 8: recriava as tabelas espelho e criava
  /// as demais se faltassem. Deixa o banco no formato da v8.
  Future<void> _legacyUpgrade(DatabaseExecutor txn) async {
    for (final tbl in ['user', 'delivery', 'transport']) {
      await txn.execute('DROP TABLE IF EXISTS $tbl');
    }
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS user (
        id TEXT PRIMARY KEY, name TEXT, token TEXT, keepConnected INTEGER,
        email TEXT, password TEXT
      )
    ''');
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS coordinate (
        dateTime TEXT, latitude TEXT, longitude TEXT, speed REAL, alert TEXT,
        data1 TEXT, data2 TEXT, device TEXT, equipamentId TEXT,
        isSynced INTEGER
      )
    ''');
    await _createOccurrence(txn);
  }

  /// v9: token/senha saem do SQLite para o armazenamento seguro;
  /// coordinate ganha chave primária; delivery ganha chave composta;
  /// renomeia colunas `equipament*` -> `equipment*`.
  Future<void> _migrateTo9(DatabaseExecutor txn) async {
    // 1. Credenciais -> CredentialStore, preservando o login atual.
    try {
      final rows = await txn.query('user', limit: 1);
      if (rows.isNotEmpty) {
        final token = rows.first['token'] as String?;
        final password = rows.first['password'] as String?;
        if (token != null && token.isNotEmpty) {
          await _credentialStore.saveToken(token);
        }
        if (password != null && password.isNotEmpty) {
          await _credentialStore.savePassword(password);
        }
      }
    } catch (e) {
      appLog('Migração v9: não foi possível mover credenciais: $e');
    }
    await _createUser(txn, 'user_v9');
    await txn.execute('''
      INSERT OR IGNORE INTO user_v9 (id, name, email, keepConnected)
      SELECT id, name, email, keepConnected FROM user
    ''');
    await txn.execute('DROP TABLE IF EXISTS user');
    await txn.execute('ALTER TABLE user_v9 RENAME TO user');

    // 2. Coordinate com localId. Se a cópia falhar, o original é
    //    preservado como coordinate_legacy em vez de ser apagado.
    await _createCoordinate(txn, 'coordinate_v9');
    try {
      await txn.execute('''
        INSERT INTO coordinate_v9 (dateTime, latitude, longitude, speed,
          alert, data1, data2, device, equipmentId, isSynced)
        SELECT dateTime, latitude, longitude, speed, alert, data1, data2,
          device, equipamentId, isSynced FROM coordinate
      ''');
      await txn.execute('DROP TABLE IF EXISTS coordinate');
    } catch (e) {
      appLog('Migração v9: cópia de coordenadas falhou: $e');
      await txn.execute('ALTER TABLE coordinate RENAME TO coordinate_legacy');
    }
    await txn.execute('ALTER TABLE coordinate_v9 RENAME TO coordinate');

    // 3. Tabelas espelho: recriadas (voltam na próxima busca).
    await txn.execute('DROP TABLE IF EXISTS delivery');
    await txn.execute('DROP TABLE IF EXISTS transport');
    await _createDelivery(txn);
    await _createTransport(txn);

    await _createIndexes(txn);
  }

  /// v10: coordinate guarda o transporte e o shipment em execução no
  /// momento da coleta. Pontos antigos ficam com os dois nulos.
  Future<void> _migrateTo10(DatabaseExecutor txn) async {
    // Bancos vindos da v8 já passam pela v9 com o schema novo de
    // coordinate; só adiciona as colunas que faltarem.
    final columns = {
      for (final c in await txn.rawQuery(
        'PRAGMA table_info(${Coordinate.tableName})',
      ))
        c['name'] as String,
    };
    for (final column in [
      Coordinate.columnTransportId,
      Coordinate.columnShipmentId,
    ]) {
      if (!columns.contains(column)) {
        await txn.execute(
          'ALTER TABLE ${Coordinate.tableName} ADD COLUMN $column TEXT',
        );
      }
    }
  }
}
