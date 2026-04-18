import 'package:gologapp/data/model/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';

class SqlService extends GetxService {
  static final List<String> tables = [User.tableName];
  static SqlService get to => Get.find();

  late Database _db;
  final String _dbName = "golog.db";
  final int _version = 1;

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
        ${User.columnEmail} TEXT
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
