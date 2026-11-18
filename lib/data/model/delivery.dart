import 'package:golog/data/model/delivery_status.dart';
import 'package:golog/util/json_parse.dart';

export 'package:golog/data/model/delivery_status.dart';

class Delivery {
  static const String tableName = 'delivery';
  static const String columnId = 'id';
  static const String columnWeight = 'weight';
  static const String columnVolume = 'volume';
  static const String columnScheduledDate = 'scheduledDate';
  static const String columnRoutePlanned = 'routePlanned';
  static const String columnRouteCompleted = 'routeCompleted';
  static const String columnStatus = 'status';
  static const String columnDeliverySequence = 'deliverySequence';
  static const String columnDeliveryTypeId = 'deliveryTypeId';
  static const String columnTransportId = 'transportId';
  static const String columnIsPickup = 'isPickup';
  static const String columnDestinationAddress = 'destinationAddress';
  static const String columnDestinationLat = 'destinationLat';
  static const String columnDestinationLng = 'destinationLng';
  static const String columnRecipientName = 'recipientName';

  final String id;
  final double weight;
  final double volume;

  /// Data/hora agendada da parada (campo `shedulind` no backend). Pode
  /// faltar — nesse caso a tela mostra "Não informado".
  final DateTime? scheduledDate;
  final String routePlanned;
  final String routeCompleted;
  String status;
  final int deliverySequence;
  final bool isPickup;

  final String deliveryTypeId;
  final String transportId;
  final String destinationAddress;
  final String recipientName;
  final double destinationLat;
  final double destinationLng;

  Delivery({
    required this.id,
    required this.weight,
    required this.volume,
    required this.scheduledDate,
    required this.routePlanned,
    required this.routeCompleted,
    required this.status,
    required this.deliverySequence,
    required this.deliveryTypeId,
    required this.transportId,
    required this.destinationAddress,
    required this.recipientName,
    required this.isPickup,
    required this.destinationLat,
    required this.destinationLng,
  });

  bool get isFinished => status == DeliveryStatus.finished;
  bool get isStarted => status == DeliveryStatus.started;

  factory Delivery.fromJson(Map<String, dynamic> json) {
    final routeStop = JsonParse.toMap(json['routeStop']);
    final customer = JsonParse.toMap(json['customer']);
    // Algumas respostas trazem o endereço só dentro de `customer`.
    final address =
        JsonParse.toMap(json['address']) ??
        JsonParse.toMap(customer?['address']);
    return Delivery(
      id: JsonParse.toStr(json['id']),
      weight: JsonParse.toDouble(json['weight']),
      volume: JsonParse.toDouble(json['volume']),
      scheduledDate: JsonParse.toDate(json['shedulind'] ?? json['schedulind']),
      routePlanned: JsonParse.toStr(
        routeStop?['routePlanned'] ?? json['routePlanned'],
      ),
      routeCompleted: JsonParse.toStr(json['routeCompleted']),
      status: DeliveryStatus.fromApi(json['status']),
      deliverySequence: JsonParse.toInt(
        routeStop?['sequenceOrder'] ?? json['deliverySequence'],
      ),
      deliveryTypeId: JsonParse.toStr(
        JsonParse.toMap(json['shipmentType'])?['id'],
      ),
      transportId: JsonParse.toStr(
        JsonParse.toMap(json['transport'])?['id'] ?? json['transportId'],
      ),
      destinationAddress: _addressFromJson(address),
      recipientName: JsonParse.toStr(customer?['legalName']),
      isPickup: json['typeOperation'] == 'COLETA',
      destinationLat: JsonParse.toDouble(address?['latitude']),
      destinationLng: JsonParse.toDouble(address?['longitude']),
    );
  }

  Map<String, dynamic> toDb() {
    return {
      columnId: id,
      columnWeight: weight,
      columnVolume: volume,
      columnScheduledDate: scheduledDate?.toIso8601String(),
      columnRoutePlanned: routePlanned,
      columnRouteCompleted: routeCompleted,
      columnStatus: status,
      columnDeliverySequence: deliverySequence,
      columnDeliveryTypeId: deliveryTypeId,
      columnTransportId: transportId,
      columnDestinationAddress: destinationAddress,
      columnRecipientName: recipientName,
      columnDestinationLat: destinationLat,
      columnDestinationLng: destinationLng,
      columnIsPickup: isPickup ? 1 : 0,
    };
  }

  factory Delivery.fromDb(Map<String, dynamic> db) {
    return Delivery(
      id: JsonParse.toStr(db[columnId]),
      weight: JsonParse.toDouble(db[columnWeight]),
      volume: JsonParse.toDouble(db[columnVolume]),
      scheduledDate: JsonParse.toDate(db[columnScheduledDate]),
      routePlanned: db[columnRoutePlanned] ?? '',
      routeCompleted: db[columnRouteCompleted] ?? '',
      // Normaliza também o cache: versões anteriores gravavam o valor cru
      // da API (ex: "FINALIZADO").
      status: DeliveryStatus.fromApi(db[columnStatus]),
      deliverySequence: JsonParse.toInt(db[columnDeliverySequence]),
      deliveryTypeId: db[columnDeliveryTypeId] ?? '',
      transportId: db[columnTransportId] ?? '',
      destinationAddress: db[columnDestinationAddress] ?? '',
      destinationLat: JsonParse.toDouble(db[columnDestinationLat]),
      destinationLng: JsonParse.toDouble(db[columnDestinationLng]),
      recipientName: db[columnRecipientName] ?? '',
      isPickup: db[columnIsPickup] == 1,
    );
  }

  static String _addressFromJson(Map<String, dynamic>? json) {
    if (json == null) return '';
    final street = JsonParse.toStr(json['street']);
    final number = JsonParse.toStr(json['number']);
    final district = JsonParse.toStr(json['district']);
    final city = JsonParse.toStr(json['city']);
    final state = JsonParse.toStr(json['state']);
    // A API manda `cep`; `zipCode` fica como alternativa.
    final zipCode = JsonParse.toStr(json['cep'] ?? json['zipCode']);
    return '$street, $number, $district, $city, $state, $zipCode';
  }

  /// Nova lista ordenada pela sequência da parada (não altera a original).
  static List<Delivery> sortedBySequence(List<Delivery> deliveries) {
    return [...deliveries]
      ..sort((a, b) => a.deliverySequence.compareTo(b.deliverySequence));
  }
}
