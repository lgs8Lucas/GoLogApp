import 'package:flutter_test/flutter_test.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/data/model/occurrence.dart';
import 'package:golog/data/repository/route_repository.dart';

Occurrence _occ(String deliveryId, OccurrenceType type, {String t = 't1'}) =>
    Occurrence(
      type: type.name,
      description: '',
      attachment: '',
      deliveryId: deliveryId,
      transportId: t,
      senderId: 'u1',
      isSynced: false,
      dateTime: DateTime(2026),
    );

Map<String, dynamic> _shipment(String id, String transportId, {int seq = 1}) =>
    {
      'id': id,
      'status': '',
      'transport': {'id': transportId, 'codeTransport': 1},
      'routeStop': {'sequenceOrder': seq},
    };

void main() {
  group('parseShipments', () {
    test('agrupa entregas por transporte', () {
      final list = RouteRepository.parseShipments([
        _shipment('d1', 't1'),
        _shipment('d2', 't1', seq: 2),
        _shipment('d3', 't2'),
      ]);
      expect(list, hasLength(2));
      expect(list.firstWhere((t) => t.id == 't1').deliveries, hasLength(2));
    });

    test('ignora registros inválidos sem perder os demais', () {
      final list = RouteRepository.parseShipments([
        'lixo',
        {'id': 'sem-transporte'},
        {
          'id': 'd1',
          'transport': {'id': 't1'},
          'routeStop': 'formato errado',
        },
        _shipment('d2', 't1'),
      ]);
      expect(list.single.deliveries.map((d) => d.id), contains('d2'));
    });
  });

  group('applyLocalOccurrences', () {
    test('Fim local finaliza, mesmo após Início', () {
      final transports = RouteRepository.parseShipments([
        _shipment('d1', 't1'),
      ]);
      RouteRepository.applyLocalOccurrences(transports, [
        _occ('d1', OccurrenceType.Inicio),
        _occ('d1', OccurrenceType.Fim),
      ]);
      expect(transports.single.deliveries.single.isFinished, isTrue);
    });

    test('Fim registrado antes de Início também finaliza', () {
      final transports = RouteRepository.parseShipments([
        _shipment('d1', 't1'),
      ]);
      RouteRepository.applyLocalOccurrences(transports, [
        _occ('d1', OccurrenceType.Fim),
        _occ('d1', OccurrenceType.Inicio),
      ]);
      expect(transports.single.deliveries.single.isFinished, isTrue);
    });

    test('Início local marca como iniciado', () {
      final transports = RouteRepository.parseShipments([
        _shipment('d1', 't1'),
      ]);
      RouteRepository.applyLocalOccurrences(transports, [
        _occ('d1', OccurrenceType.Inicio),
      ]);
      expect(
        transports.single.deliveries.single.status,
        DeliveryStatus.started,
      );
    });

    test('ocorrência de outro transporte não afeta a entrega', () {
      final transports = RouteRepository.parseShipments([
        _shipment('d1', 't1'),
      ]);
      RouteRepository.applyLocalOccurrences(transports, [
        _occ('d1', OccurrenceType.Fim, t: 't2'),
      ]);
      expect(transports.single.deliveries.single.isFinished, isFalse);
    });
  });
}
