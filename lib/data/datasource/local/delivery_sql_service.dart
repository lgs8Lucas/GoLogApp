import 'package:get/get.dart';
import 'package:gologapp/data/model/delivery.dart'; // Ajuste o caminho conforme seu projeto
import 'package:sqflite/sqflite.dart';
import 'sql_service.dart';

class DeliverySqlService extends GetxService {
  final Database _db = Get.find<SqlService>().db;

  Future<int> insertDelivery(
    Delivery row, {
    Transaction? txn,
  }) async {
    if (txn != null) return await txn.insert(Delivery.tableName, row.toDb());
    return await _db.insert(Delivery.tableName, row.toDb());
  }

  Future<List<Delivery>> get({String? where, List<dynamic>? whereArgs}) async {
    final List<Map<String, dynamic>> rows = await _db.query(
      Delivery.tableName,
      where: where,
      whereArgs: whereArgs,
    );
    return rows.map((row) => Delivery.fromDb(row)).toList();
  }

  Future<int> deleteDelivery(String id, {Transaction? txn}) async {
    if (txn != null) {
      return await txn.delete(
        Delivery.tableName,
        where: '${Delivery.columnId} = ?',
        whereArgs: [id],
      );
    }

    return await _db.delete(
      Delivery.tableName,
      where: '${Delivery.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllDeliveries({Transaction? txn}) async {
    if (txn != null) return await txn.delete(Delivery.tableName);
    return await _db.delete(Delivery.tableName);
  }

  Future<int> updateDelivery(
    Map<String, dynamic> values,
    String where,
    List<dynamic> whereArgs, {
    Transaction? txn,
  }) async {
    if (txn != null) {
      return await txn.update(
        Delivery.tableName,
        values,
        where: where,
        whereArgs: whereArgs,
      );
    }

    return await _db.update(
      Delivery.tableName,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }
}
