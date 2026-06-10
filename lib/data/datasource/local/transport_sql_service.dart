import 'package:get/get.dart';
import 'package:gologapp/data/model/delivery.dart';
import 'package:gologapp/data/model/transport.dart';
import 'package:sqflite/sqflite.dart';
import 'delivery_sql_service.dart';
import 'sql_service.dart';

class TransportSqlService extends GetxService {
  final Database _db = Get.find<SqlService>().db;
  final DeliverySqlService _deliverySqlService = Get.find<DeliverySqlService>();

  Future<int> insertTransport(
    Transport row, {
    Transaction? txn,
  }) async {
    if (txn != null) return await txn.insert(Transport.tableName, row.toDb());
    return await _db.insert(Transport.tableName, row.toDb());
  }

  Future<List<Transport>> get({String? where, List<dynamic>? whereArgs}) async {
    final List<Map<String, dynamic>> rows = await _db.query(
      Transport.tableName,
      where: where,
      whereArgs: whereArgs,
    );

    List<Transport> transports = [];
    for (var row in rows) {
      Transport transport = Transport.fromDb(row);
      transport.deliveries = await _deliverySqlService.get(
        where: '${Delivery.columnTransportId} = ?',
        whereArgs: [transport.id],
      );
      transports.add(transport);
    }
    return transports;
  }

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

  Future<int> updateTransport(
    Map<String, dynamic> row, {
    Transaction? txn,
  }) async {
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
