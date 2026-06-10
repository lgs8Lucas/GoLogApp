import 'dart:convert';
import 'package:gologapp/data/datasource/remote/api_service.dart';
import 'package:gologapp/data/model/delivery.dart';
import 'package:gologapp/data/model/occurrence.dart';
import 'package:gologapp/data/model/transport.dart';
import 'package:gologapp/data/datasource/local/transport_sql_service.dart';
import 'package:gologapp/data/datasource/local/delivery_sql_service.dart';
import 'package:gologapp/data/datasource/local/ocurrence_sql_service.dart';
import 'package:gologapp/data/datasource/local/sql_service.dart';

class RouteRepository {
  final ApiService _apiService;
  final TransportSqlService _transportSqlService;
  final DeliverySqlService _deliverySqlService;
  final SqlService _sqlService;
  final OccurrenceSqlService _occurrenceSqlService;

  RouteRepository(
    this._apiService,
    this._transportSqlService,
    this._deliverySqlService,
    this._sqlService,
    this._occurrenceSqlService,
  );

  Future<List<Transport>> getTransports() async {
    try {
      List<Transport> transports = [];
      transports = await fetchTransports();
      transports = await mergeLocalData(transports);
      await saveTransports(transports);
    } catch (e) {
      print("Erro ao buscar transportes Online: $e");
    }
    List<Transport> transports = await _transportSqlService.get();
    return transports;
  }

  Future<List<Transport>> fetchTransports() async {
    try {
      final response = await _apiService.get('/shipment/list-personalized');
      if (response.statusCode == 200) {
        var decodedJson = jsonDecode(response.body);
        final List<Map<String, dynamic>> rawList = decodedJson is List
            ? List.castFrom(decodedJson)
            : [decodedJson];
        Map<String, Transport> transportByUUID = {};
        for (var raw in rawList) {
          if (raw['transport'] == null) continue;

          Transport transport = Transport.fromJson(raw['transport']);
          if (transportByUUID[transport.id] != null)
            transport = transportByUUID[transport.id]!;
          else
            transportByUUID[transport.id] = transport;
          Delivery delivery = Delivery.fromJson(raw);
          transport.deliveries.add(delivery);
        }
        return transportByUUID.values.toList();
      } else {
        throw Exception(
          'Erro ao buscar transportes. Código: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Falha na comunicação com o servidor: $e');
    }
  }

  Future<void> saveTransports(List<Transport> transports) async {
    await _sqlService.db.transaction((txn) async {
      await _transportSqlService.deleteAllTransports(txn: txn);
      await _deliverySqlService.deleteAllDeliveries(txn: txn);
      for (var transport in transports) {
        await _transportSqlService.insertTransport(
          transport,
          txn: txn,
        );
        for (var delivery in transport.deliveries) {
          await _deliverySqlService.insertDelivery(delivery, txn: txn);
        }
      }
    });
  }

  Future<List<Transport>> mergeLocalData(List<Transport> transports) async {
    List<Delivery> deliveries = transports.expand((t) => t.deliveries).toList();
    List<Occurrence> occurrences = await _occurrenceSqlService.get(
      '${Occurrence.columnDeliveryId} IN (${deliveries.map((d) => "'${d.id}'").join(',')})',
      [],
    );
    Map<String, List<Occurrence>> occurrencesByShipmentId = {};
    for (var occurrence in occurrences) {
      occurrencesByShipmentId.putIfAbsent(occurrence.deliveryId, () => []);
      occurrencesByShipmentId[occurrence.deliveryId]!.add(occurrence);
    }
    for (var transport in transports) {
      for (var delivery in transport.deliveries) {
        if (delivery.status == 'Finalizado') continue;
        if (occurrencesByShipmentId.containsKey(delivery.id)) {
          for (var occurrence in occurrencesByShipmentId[delivery.id]!) {
            if (occurrence.type == OccurrenceType.Fim.name) {
              delivery.status = 'Finalizado';
              break;
            } else if (occurrence.type == OccurrenceType.Inicio.name) {
              delivery.status = 'Iniciado';
            }
          }
        }
      }
    }
    return transports;
  }
}
