class Coordinate {
  static final String tableName = 'coordinate';
  static final String columnDateTime = 'dateTime';
  static final String columnLatitude = 'latitude';
  static final String columnLongitude = 'longitude';
  static final String columnSpeed = 'speed';
  static final String columnAlert = 'alert';
  static final String columnData1 = 'data1';
  static final String columnData2 = 'data2';
  static final String columnDevice = 'device';
  static final String columnEquipamentId = 'equipamentId';
  static final String columnIsSynced = 'isSynced';

  final DateTime dateTime;
  final String latitude;
  final String longitude;
  final double? speed;
  final String? alert;
  final String? data1;
  final String? data2;
  final String device;
  final String equipamentId;
  final bool isSynced;

  Coordinate({
    required this.dateTime,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.alert,
    required this.data1,
    required this.data2,
    required this.device,
    required this.equipamentId,
    required this.isSynced,
  });

  factory Coordinate.fromJson(Map<String, dynamic> json) {
    return Coordinate(
      dateTime: DateTime.parse(json['dateTime']),
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      speed: ((json['speed'] ?? 0) as num).toDouble(),
      alert: json['alert'] ?? '',
      data1: json['data1'] ?? '',
      data2: json['data2'] ?? '',
      device: json['device'] ?? '',
      equipamentId: json['equipamentId'] ?? '',
      isSynced: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed??0.0,
      'alert': alert??".",
      'data1': data1??".",
      'data2': data2??".",
      'device': device,
      'equipamentId': equipamentId,
    };
  }

  Map<String, dynamic> toDb() {
    return {
      columnDateTime: dateTime.toIso8601String(),
      columnLatitude: latitude,
      columnLongitude: longitude,
      columnSpeed: speed,
      columnAlert: alert,
      columnData1: data1,
      columnData2: data2,
      columnDevice: device,
      columnEquipamentId: equipamentId,
      columnIsSynced: isSynced ? 1 : 0,
    };
  }

  factory Coordinate.fromDb(Map<String, dynamic> db) {
    return Coordinate(
      dateTime: DateTime.parse(db[columnDateTime]),
      latitude: db[columnLatitude],
      longitude: db[columnLongitude],
      speed: db[columnSpeed],
      alert: db[columnAlert],
      data1: db[columnData1],
      data2: db[columnData2],
      device: db[columnDevice],
      equipamentId: db[columnEquipamentId],
      isSynced: db[columnIsSynced] == 1,
    );
  }
}
