import 'package:get/get.dart';
import 'package:gologapp/data/model/transport.dart';
import 'package:sqflite/sqflite.dart';
import 'sql_service.dart';

class TransportSqlService extends GetxService {
  final Database _db = Get.find<SqlService>().db;

  Future<int> insertTransport(Map<String, dynamic> row, {Transaction? txn}) async {
    if (txn != null) return await txn.insert(Transport.tableName, row);
    return await _db.insert(Transport.tableName, row);
  }

  Future<List<Map<String, dynamic>>> getAllTransports() async {
    return await _db.query(Transport.tableName);
  }

  // Deleta o transporte usando o ID (String/UUID)
  Future<int> deleteTransport(String id, {Transaction? txn}) async {
    if (txn != null) {
      return await txn.delete(
        Transport.tableName,
        where: '${Transport.columnId} = ?',
        whereArgs: [id],
      );
    }

    return await _db.delete(
      Transport.tableName,
      where: '${Transport.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllTransports({Transaction? txn}) async {
    if (txn != null) return await txn.delete(Transport.tableName);
    return await _db.delete(Transport.tableName);
  }

  // Atualiza os dados do transporte usando o ID como base
  Future<int> updateTransport(Map<String, dynamic> row, {Transaction? txn}) async {
    if (txn != null) {
      return await txn.update(
        Transport.tableName,
        row,
        where: '${Transport.columnId} = ?',
        whereArgs: [row[Transport.columnId]],
      );
    }

    return await _db.update(
      Transport.tableName,
      row,
      where: '${Transport.columnId} = ?',
      whereArgs: [row[Transport.columnId]],
    );
  }
}