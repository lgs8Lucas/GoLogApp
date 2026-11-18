import 'package:flutter_test/flutter_test.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/data/model/occurrence.dart';
import 'package:golog/data/model/transport.dart';
import 'package:golog/data/repository/route_repository.dart';

/// Shipment no formato real de `/shipment/list-personalized` (dados
/// fictícios). Observação: `routeStop.status` vem sempre `PENDENTE` do
/// backend; o status válido é o do shipment.
Map<String, dynamic> _apiShipment(String id, String status, {int seq = 1}) => {
  'id': id,
  'typeOperation': 'ENTREGA',
  'weight': 1.2,
  'volume': 0.02,
  'shedulind': '2026-11-19T12:00:00',
  'status': status,
  'shipmentType': {'id': 'tipo-1', 'name': 'Medicamentos'},
  'address': {
    'street': 'Rua Exemplo',
    'number': '100',
    'district': 'Centro',
    'city': 'Araras',
    'state': 'SP',
    'cep': '13600-000',
    'latitude': '-22.35',
    'longitude': '-47.38',
  },
  'customer': {'legalName': 'Cliente Teste'},
  'transport': {
    'id': 't1',
    'codeTransport': 25,
    'shipmentQuantity': 1,
    'timeStopped': null,
    'totalTime': null,
    'equipamentGroup': {
      'id': 'g1',
      'equipament1': {'id': 'e1', 'plate': 'AAA-0000'},
    },
  },
  'routeStop': {'sequenceOrder': seq, 'status': 'PENDENTE'},
};

Occurrence _local(String deliveryId, OccurrenceType type) => Occurrence(
  type: type.name,
  description: '',
  attachment: '',
  deliveryId: deliveryId,
  transportId: 't1',
  senderId: 'u1',
  isSynced: false,
  dateTime: DateTime(2026),
);

Delivery _parse(String status) => RouteRepository.parseShipments([
  _apiShipment('d1', status),
]).single.deliveries.single;

void main() {
  group('status vindo da API', () {
    test('valores reais do backend', () {
      expect(_parse('AGUARDANDO_INICIO').status, DeliveryStatus.pending);
      expect(_parse('INICIADO').status, DeliveryStatus.started);
      expect(_parse('FINALIZADO').status, DeliveryStatus.finished);
    });

    test('tolera variações de caixa e espaços', () {
      expect(_parse(' finalizado ').isFinished, isTrue);
      expect(_parse('Iniciado').isStarted, isTrue);
    });

    test('desconhecido ou ausente vira pendente', () {
      expect(_parse('QUALQUER_COISA').status, DeliveryStatus.pending);
      expect(DeliveryStatus.fromApi(null), DeliveryStatus.pending);
    });

    test('routeStop.status (sempre PENDENTE) é ignorado', () {
      expect(_parse('FINALIZADO').isFinished, isTrue);
    });

    test('endereço usa cep e bairro', () {
      expect(
        _parse('FINALIZADO').destinationAddress,
        'Rua Exemplo, 100, Centro, Araras, SP, 13600-000',
      );
    });

    test('cache gravado por versão anterior (valor cru) é normalizado', () {
      final d = _parse('FINALIZADO');
      final row = d.toDb()..[Delivery.columnStatus] = 'FINALIZADO';
      expect(Delivery.fromDb(row).isFinished, isTrue);
    });

    test('status sobrevive à ida e volta pelo cache local', () {
      final d = _parse('FINALIZADO');
      expect(Delivery.fromDb(d.toDb()).isFinished, isTrue);
    });
  });

  group('merge: API + registros locais', () {
    List<Transport> api(String status) =>
        RouteRepository.parseShipments([_apiShipment('d1', status)]);

    test('finalizada no aparelho prevalece sobre pendente da API', () {
      final t = api('AGUARDANDO_INICIO');
      RouteRepository.applyLocalOccurrences(t, [
        _local('d1', OccurrenceType.Fim),
      ]);
      expect(t.single.deliveries.single.isFinished, isTrue);
    });

    test('finalizada no aparelho prevalece sobre iniciada da API', () {
      final t = api('INICIADO');
      RouteRepository.applyLocalOccurrences(t, [
        _local('d1', OccurrenceType.Inicio),
        _local('d1', OccurrenceType.Fim),
      ]);
      expect(t.single.deliveries.single.isFinished, isTrue);
    });

    test('iniciada no aparelho prevalece sobre pendente da API', () {
      final t = api('AGUARDANDO_INICIO');
      RouteRepository.applyLocalOccurrences(t, [
        _local('d1', OccurrenceType.Inicio),
      ]);
      expect(t.single.deliveries.single.isStarted, isTrue);
    });

    test('finalizada na API não regride por registro local antigo', () {
      final t = api('FINALIZADO');
      RouteRepository.applyLocalOccurrences(t, [
        _local('d1', OccurrenceType.Inicio),
      ]);
      expect(t.single.deliveries.single.isFinished, isTrue);
    });

    test('sem registro local, vale o status da API', () {
      final t = api('FINALIZADO');
      RouteRepository.applyLocalOccurrences(t, []);
      expect(t.single.deliveries.single.isFinished, isTrue);
    });
  });
}
