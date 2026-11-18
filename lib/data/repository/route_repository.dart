import 'package:golog/data/datasource/local/delivery_sql_service.dart';
import 'package:golog/data/datasource/local/occurrence_sql_service.dart';
import 'package:golog/data/datasource/local/sql_service.dart';
import 'package:golog/data/datasource/local/transport_sql_service.dart';
import 'package:golog/data/datasource/local/user_sql_service.dart';
import 'package:golog/data/datasource/remote/api_service.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/data/model/occurrence.dart';
import 'package:golog/data/model/transport.dart';
import 'package:golog/util/json_parse.dart';
import 'package:golog/util/log.dart';

class RouteRepository {
  /// Ocorrências já enviadas ficam no aparelho por este tempo (e enquanto
  /// o servidor ainda não mostrar a entrega como finalizada).
  static const Duration _keepSyncedOccurrences = Duration(days: 7);

  final ApiService _apiService;
  final TransportSqlService _transportSqlService;
  final DeliverySqlService _deliverySqlService;
  final SqlService _sqlService;
  final OccurrenceSqlService _occurrenceSqlService;
  final UserSqlService _userSqlService;

  RouteRepository(
    this._apiService,
    this._transportSqlService,
    this._deliverySqlService,
    this._sqlService,
    this._occurrenceSqlService,
    this._userSqlService,
  );

  /// Busca as rotas do motorista no servidor, aplica o que já foi
  /// registrado no aparelho e salva no cache. Se o servidor falhar, devolve
  /// o cache local.
  ///
  /// O status vem da API; uma ocorrência local mais recente que o servidor
  /// ainda não refletiu (ex: entrega finalizada offline) prevalece.
  Future<List<Transport>> getTransports() async {
    try {
      final transports = await fetchTransports();
      await _purgeOldOccurrences(transports);
      await mergeLocalData(transports);
      await saveTransports(transports);
    } catch (e) {
      appLog('Erro ao buscar transportes online: $e');
    }
    return _transportSqlService.getAll();
  }

  Future<List<Transport>> fetchTransports() async {
    // O backend identifica o motorista pelo id do usuário logado (não há
    // um "driverId" separado).
    final userId = await _userSqlService.getCurrentUserId();
    if (userId.isEmpty) throw StateError('Nenhum usuário logado.');

    final response = await _apiService.get(
      '/shipment/list-personalized',
      query: {'userId': userId},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao buscar transportes. Código: ${response.statusCode}',
      );
    }
    final decoded = ApiService.tryDecode(response.body);
    if (decoded == null) throw const FormatException('Resposta inválida');
    return parseShipments(decoded is List ? decoded : [decoded]);
  }

  /// Agrupa a lista de shipments (entregas) do backend por transporte.
  /// Um registro mal formado é descartado sem derrubar a lista toda.
  static List<Transport> parseShipments(List<dynamic> rawList) {
    final transportById = <String, Transport>{};
    for (final item in rawList) {
      try {
        final raw = JsonParse.toMap(item);
        final rawTransport = JsonParse.toMap(raw?['transport']);
        if (raw == null || rawTransport == null) continue;

        final parsed = Transport.fromJson(rawTransport);
        if (parsed.id.isEmpty) continue;
        final transport = transportById.putIfAbsent(parsed.id, () => parsed);

        final delivery = Delivery.fromJson(raw);
        if (delivery.id.isEmpty) continue;
        transport.deliveries.add(delivery);
      } catch (e) {
        appLog('Shipment ignorado por erro de parse: $e');
      }
    }
    return transportById.values.toList();
  }

  /// Apaga ocorrências antigas já enviadas que não fazem mais diferença:
  /// mantém as de entregas que o servidor ainda não mostra como
  /// finalizadas, pois são elas que corrigem o status no merge. Roda só
  /// com a lista recém-baixada (nunca com o cache vazio após logout).
  Future<void> _purgeOldOccurrences(List<Transport> fromServer) async {
    final keep = {
      for (final t in fromServer)
        for (final d in t.deliveries)
          if (!d.isFinished) d.id,
    };
    try {
      await _occurrenceSqlService.purgeSynced(
        _keepSyncedOccurrences,
        keepDeliveryIds: keep,
      );
    } catch (e) {
      appLog('Erro ao limpar ocorrências antigas: $e');
    }
  }

  Future<void> saveTransports(List<Transport> transports) async {
    await _sqlService.db.transaction((txn) async {
      await _transportSqlService.deleteAllTransports(txn: txn);
      await _deliverySqlService.deleteAllDeliveries(txn: txn);
      for (final transport in transports) {
        await _transportSqlService.insertTransport(transport, txn: txn);
        for (final delivery in transport.deliveries) {
          await _deliverySqlService.insertDelivery(delivery, txn: txn);
        }
      }
    });
  }

  /// Remove rotas/entregas em cache (usado no logout). Ocorrências e
  /// coordenadas pendentes são mantidas até serem sincronizadas.
  Future<void> clearCache() async {
    await _sqlService.db.transaction((txn) async {
      await _transportSqlService.deleteAllTransports(txn: txn);
      await _deliverySqlService.deleteAllDeliveries(txn: txn);
    });
  }

  Future<void> mergeLocalData(List<Transport> transports) async {
    final ids = transports
        .expand((t) => t.deliveries)
        .map((d) => d.id)
        .toSet()
        .toList();
    if (ids.isEmpty) return;

    // SQLite limita a quantidade de parâmetros por consulta: busca em lotes.
    const chunk = 500;
    final occurrences = <Occurrence>[];
    for (var i = 0; i < ids.length; i += chunk) {
      final part = ids.sublist(i, (i + chunk).clamp(0, ids.length));
      final placeholders = List.filled(part.length, '?').join(',');
      occurrences.addAll(
        await _occurrenceSqlService.get(
          '${Occurrence.columnDeliveryId} IN ($placeholders)',
          part,
        ),
      );
    }
    applyLocalOccurrences(transports, occurrences);
  }

  /// Ajusta o status das entregas conforme ocorrências registradas no
  /// aparelho que o servidor talvez ainda não conheça: Fim -> Finalizado,
  /// Início -> Iniciado. Nunca "regride" uma entrega já finalizada.
  static void applyLocalOccurrences(
    List<Transport> transports,
    List<Occurrence> occurrences,
  ) {
    final byDelivery = <String, List<Occurrence>>{};
    for (final o in occurrences) {
      (byDelivery[o.deliveryId] ??= []).add(o);
    }
    for (final transport in transports) {
      for (final delivery in transport.deliveries) {
        if (delivery.isFinished) continue;
        final list = byDelivery[delivery.id];
        if (list == null) continue;
        final related = list.where(
          (o) => o.transportId.isEmpty || o.transportId == transport.id,
        );
        if (related.any((o) => o.type == OccurrenceType.Fim.name)) {
          delivery.status = DeliveryStatus.finished;
        } else if (related.any((o) => o.type == OccurrenceType.Inicio.name)) {
          delivery.status = DeliveryStatus.started;
        }
      }
    }
  }
}
