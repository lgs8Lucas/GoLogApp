import 'package:get/get.dart';
import 'package:gologapp/data/model/occurrence.dart';
import 'package:sqflite/sqflite.dart';
import 'sql_service.dart';

class OccurrenceSqlService extends GetxService {
  final Database _db = Get.find<SqlService>().db;

  Future<int> insertOccurrence(
    Occurrence occurrence, {
    Transaction? txn,
  }) async {
    if (txn != null)
      return await txn.insert(Occurrence.tableName, occurrence.toDb());
    return await _db.insert(Occurrence.tableName, occurrence.toDb());
  }

  Future<List<Occurrence>> get(String? where, List<dynamic>? whereArgs) async {
    final List<Map<String, dynamic>> rows = await _db.query(
      Occurrence.tableName,
      where: where,
      whereArgs: whereArgs,
    );
    return rows.map((row) => Occurrence.fromDb(row)).toList();
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
  Future<int> updateOccurrence(
    Map<String, dynamic> values,
    String where,
    List<dynamic> whereArgs, {
    Transaction? txn,
  }) async {
    if (txn != null) {
      return await txn.update(
        Occurrence.tableName,
        values,
        where: where,
        whereArgs: whereArgs,
      );
    }

    return await _db.update(
      Occurrence.tableName,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<void> markAsSynced(Occurrence occurrence) async {
    await updateOccurrence(
      {Occurrence.columnIsSynced: 1},
      '${Occurrence.columnLocalId} = ?',
      [occurrence.localId],
    );
  }
}
