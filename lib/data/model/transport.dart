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
  final int timeStopped;
  final int totalTime;
  
  final String driverId;
  final String transporterId;
  final String equipamentGroupId;

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
  });

  factory Transport.fromJson(Map<String, dynamic> json) {
    return Transport(
      id: json['id'] ?? '',
      routeReturnPlanned: json['routeReturnPlanned'] ?? '',
      routeReturnCompleted: json['routeReturnCompleted'] ?? '',
      deliveryQuantity: json['deliveryQuantity'] ?? 0,
      timeStopped: json['timeStopped'] ?? 0,
      totalTime: json['totalTime'] ?? 0,
      driverId: json['driver'] != null ? json['driver']['id'] ?? '' : '',
      transporterId: json['transporter'] != null ? json['transporter']['id'] ?? '' : '',
      equipamentGroupId: json['equipamentGroup'] != null ? json['equipamentGroup']['id'] ?? '' : '',
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
    );
  }
}