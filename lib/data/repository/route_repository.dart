import 'dart:convert';
import 'package:gologapp/data/datasource/remote/api_service.dart';
import 'package:gologapp/data/model/delivery.dart';
import 'package:gologapp/data/model/transport.dart';

class RouteRepository {
  final ApiService _apiService;

  RouteRepository(this._apiService);

  Future<List<Transport>> getTransports() async {
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
}
