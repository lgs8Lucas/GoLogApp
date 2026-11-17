import 'package:golog/data/model/delivery.dart';
import 'package:golog/util/json_parse.dart';

class Transport {
  static const String tableName = 'transport';
  static const String columnId = 'id';
  static const String columnRoutePlanned = 'routePlanned';
  static const String columnRouteCompleted = 'routeCompleted';
  static const String columnDeliveryQuantity = 'shipmentQuantity';
  static const String columnTimeStopped = 'timeStopped';
  static const String columnTotalTime = 'totalTime';
  static const String columnCodeTransport = 'codeTransport';
  static const String columnDriverId = 'driverId';
  static const String columnTransporterId = 'transporterId';
  static const String columnEquipmentGroupId = 'equipmentGroupId';
  static const String columnEquipmentId = 'equipmentId';
  static const String columnPlate = 'plate';

  final String id;
  final String routePlanned;
  final String routeCompleted;
  final int deliveryQuantity;
  final double timeStopped;
  final double totalTime;
  final int codeTransport;
  final String driverId;
  final String transporterId;
  final String equipmentGroupId;
  final String equipmentId;
  final String plate;

  List<Delivery> deliveries = [];

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
    required this.equipmentGroupId,
    required this.equipmentId,
    required this.plate,
  });

  /// Paradas ainda não finalizadas.
  bool get hasPendingDeliveries => deliveries.any((d) => !d.isFinished);

  factory Transport.fromJson(Map<String, dynamic> json) {
    // As chaves `equipamentGroup`/`equipament1` seguem o contrato do backend.
    final equipmentGroup = JsonParse.toMap(json['equipamentGroup']);
    final truck = JsonParse.toMap(equipmentGroup?['equipament1']);
    return Transport(
      id: JsonParse.toStr(json['id']),
      codeTransport: JsonParse.toInt(json['codeTransport']),
      routePlanned: JsonParse.toStr(json['routePlanned']),
      routeCompleted: JsonParse.toStr(json['routeCompleted']),
      deliveryQuantity: JsonParse.toInt(json[columnDeliveryQuantity]),
      timeStopped: JsonParse.toDouble(json['timeStopped']),
      totalTime: JsonParse.toDouble(json['totalTime']),
      driverId: JsonParse.toStr(JsonParse.toMap(json['driver'])?['id']),
      transporterId: JsonParse.toStr(
        JsonParse.toMap(json['transporter'])?['id'],
      ),
      equipmentGroupId: JsonParse.toStr(equipmentGroup?['id']),
      equipmentId: JsonParse.toStr(truck?['id']),
      plate: JsonParse.toStr(truck?['plate']),
    );
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
      columnEquipmentGroupId: equipmentGroupId,
      columnEquipmentId: equipmentId,
      columnPlate: plate,
    };
  }

  factory Transport.fromDb(Map<String, dynamic> db) {
    return Transport(
      id: db[columnId] ?? '',
      codeTransport: JsonParse.toInt(db[columnCodeTransport]),
      routePlanned: db[columnRoutePlanned] ?? '',
      routeCompleted: db[columnRouteCompleted] ?? '',
      deliveryQuantity: JsonParse.toInt(db[columnDeliveryQuantity]),
      timeStopped: JsonParse.toDouble(db[columnTimeStopped]),
      totalTime: JsonParse.toDouble(db[columnTotalTime]),
      driverId: db[columnDriverId] ?? '',
      transporterId: db[columnTransporterId] ?? '',
      equipmentGroupId: db[columnEquipmentGroupId] ?? '',
      equipmentId: db[columnEquipmentId] ?? '',
      plate: db[columnPlate] ?? '',
    );
  }
}
