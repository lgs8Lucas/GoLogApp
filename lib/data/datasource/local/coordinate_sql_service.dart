import 'package:golog/data/model/coordinate.dart';
import 'package:sqflite/sqflite.dart';

class CoordinateSqlService {
  final Database _db;

  CoordinateSqlService(this._db);

  Future<int> insertCoordinate(Coordinate coord) =>
      _db.insert(Coordinate.tableName, coord.toDb());

  Future<List<Coordinate>> getUnsynced({int? limit}) async {
    final rows = await _db.query(
      Coordinate.tableName,
      where: '${Coordinate.columnIsSynced} = 0',
      orderBy: Coordinate.columnLocalId,
      limit: limit,
    );
    return rows.map(Coordinate.fromDb).toList();
  }

  Future<int> countUnsynced() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery(
          'SELECT COUNT(*) FROM ${Coordinate.tableName} '
          'WHERE ${Coordinate.columnIsSynced} = 0',
        ),
      ) ??
      0;

  Future<void> markAsSynced(Coordinate coordinate) async {
    await _db.update(
      Coordinate.tableName,
      {Coordinate.columnIsSynced: 1},
      where: '${Coordinate.columnLocalId} = ?',
      whereArgs: [coordinate.localId],
    );
  }

  /// Remove coordenadas já enviadas há mais de [olderThan].
  Future<int> purgeSynced(Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan).toIso8601String();
    return _db.delete(
      Coordinate.tableName,
      where:
          '${Coordinate.columnIsSynced} = 1 AND ${Coordinate.columnDateTime} < ?',
      whereArgs: [cutoff],
    );
  }
}
