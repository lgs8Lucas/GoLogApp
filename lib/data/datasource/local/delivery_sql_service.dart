import 'package:golog/data/model/delivery.dart';
import 'package:sqflite/sqflite.dart';

class DeliverySqlService {
  final Database _db;

  DeliverySqlService(this._db);

  Future<int> insertDelivery(Delivery row, {Transaction? txn}) =>
      (txn ?? _db).insert(
        Delivery.tableName,
        row.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<List<Delivery>> getByTransport(String transportId) async {
    final rows = await _db.query(
      Delivery.tableName,
      where: '${Delivery.columnTransportId} = ?',
      whereArgs: [transportId],
    );
    return rows.map(Delivery.fromDb).toList();
  }

  Future<int> deleteAllDeliveries({Transaction? txn}) =>
      (txn ?? _db).delete(Delivery.tableName);

  Future<int> updateStatus(
    Delivery delivery,
    String status, {
    Transaction? txn,
  }) => (txn ?? _db).update(
    Delivery.tableName,
    {Delivery.columnStatus: status},
    where: '${Delivery.columnId} = ? AND ${Delivery.columnTransportId} = ?',
    whereArgs: [delivery.id, delivery.transportId],
  );
}
