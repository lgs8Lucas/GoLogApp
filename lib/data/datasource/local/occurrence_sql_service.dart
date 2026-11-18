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

  /// Remove ocorrências já enviadas há mais de [olderThan], exceto as das
  /// entregas em [keepDeliveryIds]. Quem chama decide o que manter com base
  /// na lista que acabou de vir do servidor (ver RouteRepository).
  Future<int> purgeSynced(
    Duration olderThan, {
    required Set<String> keepDeliveryIds,
  }) async {
    final cutoff = DateTime.now().subtract(olderThan).toIso8601String();
    final rows = await _db.query(
      Occurrence.tableName,
      columns: [Occurrence.columnLocalId, Occurrence.columnDeliveryId],
      where:
          '${Occurrence.columnIsSynced} = 1 AND ${Occurrence.columnDateTime} < ?',
      whereArgs: [cutoff],
    );
    final ids = [
      for (final r in rows)
        if (!keepDeliveryIds.contains(r[Occurrence.columnDeliveryId]))
          r[Occurrence.columnLocalId] as int,
    ];
    var deleted = 0;
    const chunk = 500;
    for (var i = 0; i < ids.length; i += chunk) {
      final part = ids.sublist(i, (i + chunk).clamp(0, ids.length));
      deleted += await _db.delete(
        Occurrence.tableName,
        where:
            '${Occurrence.columnLocalId} IN (${List.filled(part.length, '?').join(',')})',
        whereArgs: part,
      );
    }
    return deleted;
  }
}
