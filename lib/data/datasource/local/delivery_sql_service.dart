import 'package:get/get.dart';
import 'package:gologapp/data/model/delivery.dart'; // Ajuste o caminho conforme seu projeto
import 'package:sqflite/sqflite.dart';
import 'sql_service.dart';

class DeliverySqlService extends GetxService {
  final Database _db = Get.find<SqlService>().db;

  Future<int> insertDelivery(Map<String, dynamic> row, {Transaction? txn}) async {
    if (txn != null) return await txn.insert(Delivery.tableName, row);
    return await _db.insert(Delivery.tableName, row);
  }

  Future<List<Map<String, dynamic>>> getAllDeliveries() async {
    return await _db.query(Delivery.tableName);
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

  Future<int> updateDelivery(Map<String, dynamic> row, {Transaction? txn}) async {
    if (txn != null) {
      return await txn.update(
        Delivery.tableName,
        row,
        where: '${Delivery.columnId} = ?',
        whereArgs: [row[Delivery.columnId]],
      );
    }

    return await _db.update(
      Delivery.tableName,
      row,
      where: '${Delivery.columnId} = ?',
      whereArgs: [row[Delivery.columnId]],
    );
  }
}