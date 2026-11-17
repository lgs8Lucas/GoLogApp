class Coordinate {
  static const String tableName = 'coordinate';
  static const String columnLocalId = 'localId';
  static const String columnDateTime = 'dateTime';
  static const String columnLatitude = 'latitude';
  static const String columnLongitude = 'longitude';
  static const String columnSpeed = 'speed';
  static const String columnAlert = 'alert';
  static const String columnData1 = 'data1';
  static const String columnData2 = 'data2';
  static const String columnDevice = 'device';
  static const String columnEquipmentId = 'equipmentId';
  static const String columnIsSynced = 'isSynced';

  final int localId;
  final DateTime dateTime;
  final String latitude;
  final String longitude;
  final double? speed;
  final String? alert;
  final String? data1;
  final String? data2;
  final String device;
  final String equipmentId;
  final bool isSynced;

  Coordinate({
    this.localId = 0,
    required this.dateTime,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.alert,
    required this.data1,
    required this.data2,
    required this.device,
    required this.equipmentId,
    required this.isSynced,
  });

  /// Corpo enviado para `/telemetry`. As chaves seguem o contrato do
  /// backend (inclusive a grafia `equipamentId`).
  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed ?? 0.0,
      'alert': alert ?? '.',
      'data1': data1 ?? '.',
      'data2': data2 ?? '.',
      'device': device,
      'equipamentId': equipmentId,
    };
  }

  Map<String, dynamic> toDb() {
    return {
      // localId é AUTOINCREMENT: omitido no insert.
      if (localId != 0) columnLocalId: localId,
      columnDateTime: dateTime.toIso8601String(),
      columnLatitude: latitude,
      columnLongitude: longitude,
      columnSpeed: speed,
      columnAlert: alert,
      columnData1: data1,
      columnData2: data2,
      columnDevice: device,
      columnEquipmentId: equipmentId,
      columnIsSynced: isSynced ? 1 : 0,
    };
  }

  factory Coordinate.fromDb(Map<String, dynamic> db) {
    return Coordinate(
      localId: db[columnLocalId] ?? 0,
      dateTime: DateTime.parse(db[columnDateTime]),
      latitude: db[columnLatitude] ?? '',
      longitude: db[columnLongitude] ?? '',
      speed: (db[columnSpeed] as num?)?.toDouble(),
      alert: db[columnAlert],
      data1: db[columnData1],
      data2: db[columnData2],
      device: db[columnDevice] ?? '',
      equipmentId: db[columnEquipmentId] ?? '',
      isSynced: db[columnIsSynced] == 1,
    );
  }
}
