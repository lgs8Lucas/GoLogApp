import 'package:golog/data/model/delivery.dart';
import 'package:golog/data/model/occurrence.dart';
import 'package:sqflite/sqflite.dart';

class OccurrenceSqlService {
  final Database _db;

  OccurrenceSqlService(this._db);

  Future<int> insertOccurrence(Occurrence occurrence, {Transaction? txn}) =>
      (txn ?? _db).insert(Occurrence.tableName, occurrence.toDb());

  Future<List<Occurrence>> get(String? where, List<dynamic>? whereArgs) async {
    final rows = await _db.query(
      Occurrence.tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: Occurrence.columnLocalId,
    );
    return rows.map(Occurrence.fromDb).toList();
  }

  Future<List<Occurrence>> getUnsynced() =>
      get('${Occurrence.columnIsSynced} = ?', [0]);

  Future<int> countUnsynced() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery(
          'SELECT COUNT(*) FROM ${Occurrence.tableName} '
          'WHERE ${Occurrence.columnIsSynced} = 0',
        ),
      ) ??
      0;

  Future<void> markAsSynced(Occurrence occurrence) async {
    await _db.update(
      Occurrence.tableName,
      {Occurrence.columnIsSynced: 1},
      where: '${Occurrence.columnLocalId} = ?',
      whereArgs: [occurrence.localId],
    );
  }

  /// Remove ocorrências já enviadas há mais de [olderThan] cuja entrega não
  /// está mais na lista atual (as da lista ainda são usadas para calcular
  /// o status local em `RouteRepository`).
  Future<int> purgeSynced(Duration olderThan) {
    final cutoff = DateTime.now().subtract(olderThan).toIso8601String();
    return _db.delete(
      Occurrence.tableName,
      where:
          '${Occurrence.columnIsSynced} = 1 '
          'AND ${Occurrence.columnDateTime} < ? '
          'AND ${Occurrence.columnDeliveryId} NOT IN '
          '(SELECT ${Delivery.columnId} FROM ${Delivery.tableName})',
      whereArgs: [cutoff],
    );
  }
}
