import 'package:golog/data/datasource/local/delivery_sql_service.dart';
import 'package:golog/data/model/transport.dart';
import 'package:sqflite/sqflite.dart';

class TransportSqlService {
  final Database _db;
  final DeliverySqlService _deliverySqlService;

  TransportSqlService(this._db, this._deliverySqlService);

  Future<int> insertTransport(Transport row, {Transaction? txn}) =>
      (txn ?? _db).insert(
        Transport.tableName,
        row.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<List<Transport>> getAll() async {
    final rows = await _db.query(Transport.tableName);
    final transports = <Transport>[];
    for (final row in rows) {
      final transport = Transport.fromDb(row);
      transport.deliveries = await _deliverySqlService.getByTransport(
        transport.id,
      );
      transports.add(transport);
    }
    return transports;
  }

  Future<int> deleteAllTransports({Transaction? txn}) =>
      (txn ?? _db).delete(Transport.tableName);
}
