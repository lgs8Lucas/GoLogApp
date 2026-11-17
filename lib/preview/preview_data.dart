import 'package:golog/data/model/delivery.dart';
import 'package:golog/data/model/transport.dart';

/// Dados fictícios usados apenas pelos `@Preview`. Nada aqui é lido em
/// tempo de execução no app real.
class PreviewData {
  static Delivery delivery({
    int sequence = 1,
    String status = DeliveryStatus.pending,
    bool isPickup = false,
    String address = 'Av. Paulista, 1578, São Paulo, SP, 01310-200',
    String recipient = 'Mercado Bom Preço LTDA',
    Duration offset = const Duration(hours: 2),
  }) {
    return Delivery(
      id: 'delivery-$sequence',
      weight: 120,
      volume: 2,
      scheduledDate: DateTime(2026, 11, 11, 9, 30).add(offset),
      routePlanned: '',
      routeCompleted: '',
      status: status,
      deliverySequence: sequence,
      deliveryTypeId: 'type',
      transportId: 'transport-1',
      destinationAddress: address,
      recipientName: recipient,
      isPickup: isPickup,
      destinationLat: -23.561,
      destinationLng: -46.656,
    );
  }

  static List<Delivery> deliveries() => [
    delivery(
      sequence: 1,
      status: DeliveryStatus.finished,
      isPickup: true,
      address: 'R. Vergueiro, 3185, São Paulo, SP, 04101-300',
      recipient: 'Centro de Distribuição Sul',
      offset: Duration.zero,
    ),
    delivery(
      sequence: 2,
      status: DeliveryStatus.started,
      offset: const Duration(hours: 1, minutes: 15),
    ),
    delivery(
      sequence: 3,
      address: 'R. Augusta, 2690, , SP, ',
      recipient: '',
      offset: const Duration(hours: 3),
    ),
    delivery(
      sequence: 4,
      address: 'Av. Brigadeiro Faria Lima, 4440, São Paulo, SP, 04538-132',
      recipient: 'Farmácia Saúde & Vida',
      offset: const Duration(hours: 4, minutes: 40),
    ),
  ];

  static Transport transport({
    int code = 1,
    String plate = 'BRA2E19',
    List<Delivery>? deliveries,
  }) {
    final list = deliveries ?? PreviewData.deliveries();
    return Transport(
      id: 'transport-$code',
      codeTransport: code,
      routePlanned: '',
      routeCompleted: '',
      deliveryQuantity: list.length,
      timeStopped: 0,
      totalTime: 0,
      driverId: 'driver',
      transporterId: 'transporter',
      equipmentGroupId: 'group',
      equipmentId: 'equipment',
      plate: plate,
    )..deliveries = list;
  }

  static List<Transport> transports() => [
    transport(code: 1),
    transport(
      code: 2,
      plate: 'QWE4R56',
      deliveries: [
        delivery(sequence: 1, offset: const Duration(days: 1)),
        delivery(sequence: 2, offset: const Duration(days: 1, hours: 2)),
      ],
    ),
    transport(
      code: 17,
      plate: '',
      deliveries: [
        delivery(sequence: 1, status: DeliveryStatus.finished),
        delivery(sequence: 2, status: DeliveryStatus.finished),
      ],
    ),
  ];
}
