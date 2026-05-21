import 'package:get/get.dart';
import 'package:gologapp/data/model/occurrence.dart';
import 'package:sqflite/sqflite.dart';
import 'sql_service.dart';

class OccurrenceSqlService extends GetxService {
  final Database _db = Get.find<SqlService>().db;

  Future<int> insertOccurrence(Map<String, dynamic> row, {Transaction? txn}) async {
    if (txn != null) return await txn.insert(Occurrence.tableName, row);
    return await _db.insert(Occurrence.tableName, row);
  }

  Future<List<Map<String, dynamic>>> getAllOccurrences() async {
    return await _db.query(Occurrence.tableName);
  }

  Future<int> deleteOccurrence(String deliveryId, {Transaction? txn}) async {
    if (txn != null) {
      return await txn.delete(
        Occurrence.tableName,
        where: '${Occurrence.columnDeliveryId} = ?',
        whereArgs: [deliveryId],
      );
    }

    return await _db.delete(
      Occurrence.tableName,
      where: '${Occurrence.columnDeliveryId} = ?',
      whereArgs: [deliveryId],
    );
  }

  Future<int> deleteAllOccurrences({Transaction? txn}) async {
    if (txn != null) return await txn.delete(Occurrence.tableName);
    return await _db.delete(Occurrence.tableName);
  }

  // Atualiza usando o deliveryId como referência
  Future<int> updateOccurrence(Map<String, dynamic> row, {Transaction? txn}) async {
    if (txn != null) {
      return await txn.update(
        Occurrence.tableName,
        row,
        where: '${Occurrence.columnDeliveryId} = ?',
        whereArgs: [row[Occurrence.columnDeliveryId]],
      );
    }

    return await _db.update(
      Occurrence.tableName,
      row,
      where: '${Occurrence.columnDeliveryId} = ?',
      whereArgs: [row[Occurrence.columnDeliveryId]],
    );
  }
}