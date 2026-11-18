import 'package:golog/data/model/delivery.dart';

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
      id: json['id']?.toString() ?? '',
      codeTransport: (json['codeTransport'] as num?)?.toInt() ?? 0,
      routePlanned: json['routePlanned']?.toString() ?? '',
      routeCompleted: json['routeCompleted']?.toString() ?? '',
      deliveryQuantity: (json[columnDeliveryQuantity] as num?)?.toInt() ?? (json['deliveryQuantity'] as num?)?.toInt() ?? 0,
      timeStopped: (json['timeStopped'] as num?)?.toDouble() ?? 0.0,
      totalTime: (json['totalTime'] as num?)?.toDouble() ?? 0.0,
      driverId: json['driver'] != null ? json['driver']['id']?.toString() ?? '' : '',
      transporterId: json['transporter'] != null
          ? json['transporter']['id']?.toString() ?? ''
          : '',
      equipamentGroupId: equipmentGroup?['id']?.toString() ?? '',
      equipmentId: truck?['id']?.toString() ?? '',
      plate: truck?["plate"]?.toString() ?? '',
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
      id: db[columnId]?.toString() ?? '',
      codeTransport: (db[columnCodeTransport] as num?)?.toInt() ?? 0,
      routePlanned: db[columnRoutePlanned]?.toString() ?? '',
      routeCompleted: db[columnRouteCompleted]?.toString() ?? '',
      deliveryQuantity: (db[columnDeliveryQuantity] as num?)?.toInt() ?? 0,
      timeStopped: (db[columnTimeStopped] as num?)?.toDouble() ?? 0.0,
      totalTime: (db[columnTotalTime] as num?)?.toDouble() ?? 0.0,
      driverId: db[columnDriverId]?.toString() ?? '',
      transporterId: db[columnTransporterId]?.toString() ?? '',
      equipamentGroupId: db[columnEquipamentGroupId]?.toString() ?? '',
      equipmentId: db[columnEquipmentId]?.toString() ?? '',
      plate: db[columnPlate]?.toString() ?? '',
    );
  }
}
