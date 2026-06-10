import 'package:gologapp/data/model/delivery.dart';

class Transport {
  static final String tableName = 'transport';
  static final String columnId = 'id';
  static final String columnRoutePlanned = 'routePlanned';
  static final String columnRouteCompleted = 'routeCompleted';
  static final String columnDeliveryQuantity = 'shipmentQuantity';
  static final String columnTimeStopped = 'timeStopped';
  static final String columnTotalTime = 'totalTime';
  static final String columnCodeTransport = 'codeTransport';

  static final String columnDriverId = 'driverId';
  static final String columnTransporterId = 'transporterId';
  static final String columnEquipamentGroupId = 'equipamentGroupId';
  static final String columnEquipmentId = 'equipmentId';
  static final String columnPlate = 'plate';


  final String id;
  final String routePlanned;
  final String routeCompleted;
  final int deliveryQuantity;
  final double timeStopped;
  final double totalTime;
  final int codeTransport;
  final String driverId;
  final String transporterId;
  final String equipamentGroupId;
  final String equipmentId;
  final String plate;

  late List<Delivery> deliveries;

  Transport({
    required this.id,
    required this.codeTransport,
    required this.routePlanned,
    required this.routeCompleted,
    required this.deliveryQuantity,
    required this.timeStopped,
    required this.totalTime,
    required this.driverId,
    required this.transporterId,
    required this.equipamentGroupId,
    required this.equipmentId,
    required this.plate,
  }) {
    deliveries = [];
  }

  factory Transport.fromJson(Map<String, dynamic> json) {
    var equipmentGroup = json['equipamentGroup'];
    var truck = equipmentGroup?["equipament1"];
    return Transport(
      id: json['id'] ?? '',
      codeTransport: json['codeTransport'] ?? 0,
      routePlanned: json['routePlanned'] ?? '',
      routeCompleted: json['routeCompleted'] ?? '',
      deliveryQuantity: json[columnDeliveryQuantity] ?? 0,
      timeStopped: json['timeStopped'] ?? 0,
      totalTime: json['totalTime'] ?? 0,
      driverId: json['driver'] != null ? json['driver']['id'] ?? '' : '',
      transporterId: json['transporter'] != null
          ? json['transporter']['id'] ?? ''
          : '',
      equipamentGroupId: json['equipamentGroup']['id'] ?? '',
      equipmentId: truck?['id'] ?? '',
      plate: truck?["plate"] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codeTransport': codeTransport,
      'routePlanned': routePlanned,
      'routeCompleted': routeCompleted,
      'deliveryQuantity': deliveryQuantity,
      'timeStopped': timeStopped,
      'totalTime': totalTime,
    };
  }

  Map<String, dynamic> toDb() {
    return {
      columnId: id,
      columnRoutePlanned: routePlanned,
      columnRouteCompleted: routeCompleted,
      columnDeliveryQuantity: deliveryQuantity,
      columnTimeStopped: timeStopped,
      columnTotalTime: totalTime,
      columnCodeTransport: codeTransport,
      columnDriverId: driverId,
      columnTransporterId: transporterId,
      columnEquipamentGroupId: equipamentGroupId,
      columnEquipmentId: equipmentId,
      columnPlate: plate,
    };
  }

  factory Transport.fromDb(Map<String, dynamic> db) {
    return Transport(
      id: db[columnId],
      codeTransport: db[columnCodeTransport],
      routePlanned: db[columnRoutePlanned],
      routeCompleted: db[columnRouteCompleted],
      deliveryQuantity: db[columnDeliveryQuantity],
      timeStopped: db[columnTimeStopped],
      totalTime: db[columnTotalTime],
      driverId: db[columnDriverId] ?? '',
      transporterId: db[columnTransporterId] ?? '',
      equipamentGroupId: db[columnEquipamentGroupId] ?? '',
      equipmentId: db[columnEquipmentId] ?? '',
      plate: db[columnPlate] ?? '',
    );
  }
}
