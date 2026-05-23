import 'package:gologapp/data/model/delivery.dart';

class Transport {
  static final String tableName = 'transport';
  static final String columnId = 'id';
  static final String columnRouteReturnPlanned = 'routeReturnPlanned';
  static final String columnRouteReturnCompleted = 'routeReturnCompleted';
  static final String columnDeliveryQuantity = 'deliveryQuantity';
  static final String columnTimeStopped = 'timeStopped';
  static final String columnTotalTime = 'totalTime';

  static final String columnDriverId = 'driverId';
  static final String columnTransporterId = 'transporterId';
  static final String columnEquipamentGroupId = 'equipamentGroupId';

  final String id;
  final String routeReturnPlanned;
  final String routeReturnCompleted;
  final int deliveryQuantity;
  final double timeStopped;
  final double totalTime;

  final String driverId;
  final String transporterId;
  final String equipamentGroupId;
  final String equipmentId;
  final String plate;

  late List<Delivery> deliveries;

  Transport({
    required this.id,
    required this.routeReturnPlanned,
    required this.routeReturnCompleted,
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
      routeReturnPlanned: json['routeReturnPlanned'] ?? '',
      routeReturnCompleted: json['routeReturnCompleted'] ?? '',
      deliveryQuantity: json['deliveryQuantity'] ?? 0,
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
      'routeReturnPlanned': routeReturnPlanned,
      'routeReturnCompleted': routeReturnCompleted,
      'deliveryQuantity': deliveryQuantity,
      'timeStopped': timeStopped,
      'totalTime': totalTime,
    };
  }

  Map<String, dynamic> toDb() {
    return {
      columnId: id,
      columnRouteReturnPlanned: routeReturnPlanned,
      columnRouteReturnCompleted: routeReturnCompleted,
      columnDeliveryQuantity: deliveryQuantity,
      columnTimeStopped: timeStopped,
      columnTotalTime: totalTime,
      columnDriverId: driverId,
      columnTransporterId: transporterId,
      columnEquipamentGroupId: equipamentGroupId,
    };
  }

  factory Transport.fromDb(Map<String, dynamic> db) {
    return Transport(
      id: db[columnId],
      routeReturnPlanned: db[columnRouteReturnPlanned],
      routeReturnCompleted: db[columnRouteReturnCompleted],
      deliveryQuantity: db[columnDeliveryQuantity],
      timeStopped: db[columnTimeStopped],
      totalTime: db[columnTotalTime],
      driverId: db[columnDriverId] ?? '',
      transporterId: db[columnTransporterId] ?? '',
      equipamentGroupId: db[columnEquipamentGroupId] ?? '',
      equipmentId: '',
      plate: '',
    );
  }
}
