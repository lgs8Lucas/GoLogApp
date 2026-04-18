import 'package:get/get.dart';
import 'package:gologapp/data/model/user.dart';
import 'package:sqflite/sqflite.dart';
import 'sql_service.dart';

class UserSqlService extends GetxService {
  final Database _db = Get.find<SqlService>().db;

  Future<int> insertUser(Map<String, dynamic> row, {Transaction? txn}) async {
    if (txn != null) return await txn.insert(User.tableName, row);
    return await _db.insert(User.tableName, row);
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return await _db.query(User.tableName);
  }

  Future<int> deleteUser(int id, {Transaction? txn}) async {
    if (txn != null)
      return await txn.delete(
        User.tableName,
        where: '${User.columnId} = ?',
        whereArgs: [id],
      );

    return await _db.delete(
      User.tableName,
      where: '${User.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateUser(Map<String, dynamic> row, {Transaction? txn}) async {
    if (txn != null)
      return await txn.update(
        User.tableName,
        row,
        where: '${User.columnId} = ?',
        whereArgs: [row[User.columnId]],
      );

    return await _db.update(
      User.tableName,
      row,
      where: '${User.columnId} = ?',
      whereArgs: [row[User.columnId]],
    );
  }
}
