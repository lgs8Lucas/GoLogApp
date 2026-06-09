import 'package:get/get.dart';
import 'package:gologapp/data/model/coordinate.dart';
import 'package:sqflite/sqflite.dart';
import 'sql_service.dart';

class CoordinateSqlService extends GetxService {
  final Database _db = Get.find<SqlService>().db;

  Future<int> insertCoordinate(Coordinate coord, {Transaction? txn}) async {
    if (txn != null)
      return await txn.insert(Coordinate.tableName, coord.toDb());
    return await _db.insert(Coordinate.tableName, coord.toDb());
  }

  Future<List<Coordinate>> get(String? where, List<dynamic>? whereArgs) async {
    final List<Map<String, dynamic>> rows = await _db.query(
      Coordinate.tableName,
      where: where,
      whereArgs: whereArgs,
    );
    return rows.map((row) => Coordinate.fromDb(row)).toList();
  }

  Future<int> deleteCoordinate(String equipamentId, {Transaction? txn}) async {
    if (txn != null) {
      return await txn.delete(
        Coordinate.tableName,
        where: '${Coordinate.columnEquipamentId} = ?',
        whereArgs: [equipamentId],
      );
    }

    return await _db.delete(
      Coordinate.tableName,
      where: '${Coordinate.columnEquipamentId} = ?',
      whereArgs: [equipamentId],
    );
  }

  Future<int> deleteAllCoordinates({Transaction? txn}) async {
    if (txn != null) return await txn.delete(Coordinate.tableName);
    return await _db.delete(Coordinate.tableName);
  }

  Future<int> updateCoordinate(
    Map<String, dynamic> values,
    String where,
    List<dynamic> whereArgs, {
    Transaction? txn,
  }) async {
    if (txn != null) {
      return await txn.update(
        Coordinate.tableName,
        values,
        where: where,
        whereArgs: whereArgs,
      );
    }

    return await _db.update(
      Coordinate.tableName,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<void> markAsSynced(Coordinate coordinate) async {
    await updateCoordinate(
      {Coordinate.columnIsSynced: 1},
      '${Coordinate.columnEquipamentId} = ? AND ${Coordinate.columnDateTime} = ?',
      [
        coordinate.equipamentId,
        coordinate.dateTime.toIso8601String(),
      ],
    );
  }
}
