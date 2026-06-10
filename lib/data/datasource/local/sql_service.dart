import 'package:gologapp/data/model/coordinate.dart';
import 'package:gologapp/data/model/delivery.dart';
import 'package:gologapp/data/model/occurrence.dart';
import 'package:gologapp/data/model/transport.dart';
import 'package:gologapp/data/model/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';

class SqlService extends GetxService {
  static final List<String> tables = [
    User.tableName,
    Coordinate.tableName,
    Occurrence.tableName,
    Delivery.tableName,
    Transport.tableName,
  ];
  static SqlService get to => Get.find();

  late Database _db;
  final String _dbName = "golog.db";
  final int _version = 8;

  Database get db => _db;

  @override
  void onInit() async {
    super.onInit();
    _db = await initDB();
  }

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _version,
      onConfigure: _configureDB,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _configureDB(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${User.tableName} (
        ${User.columnId} TEXT PRIMARY KEY,
        ${User.columnName} TEXT,
        ${User.columnToken} TEXT,
        ${User.columnKeepConnected} INTEGER,
        ${User.columnEmail} TEXT,
        ${User.columnPassword} TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${Coordinate.tableName} (
        ${Coordinate.columnDateTime} TEXT,
        ${Coordinate.columnLatitude} TEXT,
        ${Coordinate.columnLongitude} TEXT,
        ${Coordinate.columnSpeed} REAL,
        ${Coordinate.columnAlert} TEXT,
        ${Coordinate.columnData1} TEXT,
        ${Coordinate.columnData2} TEXT,
        ${Coordinate.columnDevice} TEXT,
        ${Coordinate.columnEquipamentId} TEXT,
        ${Coordinate.columnIsSynced} INTEGER
      )
    ''');
    await db.execute('''
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${Delivery.tableName} (
        ${Delivery.columnId} TEXT,
        ${Delivery.columnWeight} REAL,
        ${Delivery.columnVolume} REAL,
        ${Delivery.columnScheduledCollection} TEXT,
        ${Delivery.columnScheduledDelivery} TEXT,
        ${Delivery.columnRoutePlanned} TEXT,
        ${Delivery.columnRouteCompleted} TEXT,
        ${Delivery.columnStatus} TEXT,
        ${Delivery.columnDeliverySequence} INTEGER,
        ${Delivery.columnDeliveryTypeId} TEXT,
        ${Delivery.columnTransportId} TEXT,
        ${Delivery.columnDestinationAddress} TEXT,
        ${Delivery.columnRecipientName} TEXT,
        ${Delivery.columnDestinationLat} REAL,
        ${Delivery.columnDestinationLng} REAL,
        ${Delivery.columnIsPickup} INTEGER
      )
    ''');
    await db.execute('''
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
        ${Transport.columnEquipamentGroupId} TEXT,
        ${Transport.columnEquipmentId} TEXT,
        ${Transport.columnPlate} TEXT
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      for (var tbl in tables) {
        await db.execute("DROP TABLE IF EXISTS $tbl");
      }
      await _createDB(db, newVersion);
    }
  }
}
