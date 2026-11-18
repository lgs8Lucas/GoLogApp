import 'package:flutter_test/flutter_test.dart';
import 'package:golog/data/model/coordinate.dart';
import 'package:golog/data/model/delivery.dart';
import 'package:golog/data/model/transport.dart';

void main() {
  group('Transport.fromJson', () {
    test('aceita números inteiros em campos double', () {
      final t = Transport.fromJson({
        'id': 't1',
        'codeTransport': 7,
        'timeStopped': 0,
        'totalTime': 120,
        'equipamentGroup': {
          'id': 'g1',
          'equipament1': {'id': 'e1', 'plate': 'ABC1D23'},
        },
      });
      expect(t.timeStopped, 0.0);
      expect(t.totalTime, 120.0);
      expect(t.equipmentGroupId, 'g1');
      expect(t.equipmentId, 'e1');
      expect(t.plate, 'ABC1D23');
    });

    test('campos ausentes viram valores padrão', () {
      final t = Transport.fromJson({'id': 't1'});
      expect(t.codeTransport, 0);
      expect(t.plate, '');
      expect(t.deliveries, isEmpty);
    });
  });

  group('Delivery.fromJson', () {
    test('data ausente não derruba o parse', () {
      final d = Delivery.fromJson({'id': 'd1'});
      expect(d.scheduledDate, isNull);
      expect(d.destinationLat, 0.0);
    });

    test('latitude/longitude como número ou string', () {
      final asNumber = Delivery.fromJson({
        'id': 'd1',
        'address': {'latitude': -23.5, 'longitude': -46.6},
      });
      final asString = Delivery.fromJson({
        'id': 'd2',
        'address': {'latitude': '-23.5', 'longitude': '-46.6'},
      });
      expect(asNumber.destinationLat, -23.5);
      expect(asString.destinationLng, -46.6);
    });

    test('lê sequência, tipo de operação e data', () {
      final d = Delivery.fromJson({
        'id': 'd1',
        'shedulind': '2026-11-11T09:30:00',
        'typeOperation': 'COLETA',
        'routeStop': {'sequenceOrder': 3},
      });
      expect(d.scheduledDate, DateTime(2026, 11, 11, 9, 30));
      expect(d.isPickup, isTrue);
      expect(d.deliverySequence, 3);
    });

    test('ida e volta pelo banco preserva os dados', () {
      final d = Delivery.fromJson({
        'id': 'd1',
        'status': DeliveryStatus.started,
        'transport': {'id': 't1'},
        'shedulind': '2026-11-11T09:30:00',
      });
      final back = Delivery.fromDb(d.toDb());
      expect(back.id, 'd1');
      expect(back.transportId, 't1');
      expect(back.isStarted, isTrue);
      expect(back.scheduledDate, d.scheduledDate);
    });
  });

  test('sortedBySequence não altera a lista original', () {
    Delivery make(int seq) => Delivery.fromJson({
      'id': 'd$seq',
      'routeStop': {'sequenceOrder': seq},
    });
    final original = [make(3), make(1), make(2)];
    final sorted = Delivery.sortedBySequence(original);
    expect(sorted.map((d) => d.deliverySequence), [1, 2, 3]);
    expect(original.map((d) => d.deliverySequence), [3, 1, 2]);
  });

  group('Transport.ongoingDelivery', () {
    Transport route() {
      final t = Transport.fromJson({'id': 't1'});
      t.deliveries = [
        Delivery.fromJson({'id': 'aberta', 'status': 'INICIADO'}),
        Delivery.fromJson({'id': 'feita', 'status': 'FINALIZADO'}),
      ];
      return t;
    }

    test('devolve a parada em aberto', () {
      expect(route().ongoingDelivery('aberta')?.id, 'aberta');
    });

    test('parada finalizada, de outra rota ou nula não conta', () {
      expect(route().ongoingDelivery('feita'), isNull);
      expect(route().ongoingDelivery('outra-rota'), isNull);
      expect(route().ongoingDelivery(null), isNull);
    });
  });

  test('Coordinate preserva transportId/shipmentId no banco', () {
    final c = Coordinate(
      dateTime: DateTime(2026, 11, 17, 10),
      latitude: '-22.3',
      longitude: '-47.3',
      speed: null,
      alert: null,
      data1: null,
      data2: null,
      device: 'GoLogApp',
      equipmentId: 'e1',
      isSynced: false,
      transportId: 't1',
      shipmentId: 's1',
    );
    final back = Coordinate.fromDb({...c.toDb(), 'localId': 1});
    expect(back.transportId, 't1');
    expect(back.shipmentId, 's1');
    expect(c.toJson()['shipmentId'], 's1');
    expect(c.toJson()['transportId'], 't1');
  });
}
