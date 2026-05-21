import 'package:get/get.dart';
import 'package:gologapp/data/model/coordinate.dart';
import 'package:sqflite/sqflite.dart';
import 'sql_service.dart';

class CoordinateSqlService extends GetxService {
  final Database _db = Get.find<SqlService>().db;

  Future<int> insertCoordinate(Map<String, dynamic> row, {Transaction? txn}) async {
    if (txn != null) return await txn.insert(Coordinate.tableName, row);
    return await _db.insert(Coordinate.tableName, row);
  }

  Future<List<Map<String, dynamic>>> getAllCoordinates() async {
    return await _db.query(Coordinate.tableName);
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

  Future<int> updateCoordinate(Map<String, dynamic> row, {Transaction? txn}) async {
    if (txn != null) {
      return await txn.update(
        Coordinate.tableName,
        row,
        where: '${Coordinate.columnEquipamentId} = ?',
        whereArgs: [row[Coordinate.columnEquipamentId]],
      );
    }

    return await _db.update(
      Coordinate.tableName,
      row,
      where: '${Coordinate.columnEquipamentId} = ?',
      whereArgs: [row[Coordinate.columnEquipamentId]],
    );
  }
}