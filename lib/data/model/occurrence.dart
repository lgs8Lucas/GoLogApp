enum OccurrenceType { Inicio, Fim, Continuando, Parada }

class Occurrence {
  static const String tableName = 'occurrence';
  static const String columnType = 'type';
  static const String columnDescription = 'description';
  static const String columnAttachment = 'attachment';
  static const String columnDeliveryId = 'deliveryId';
  static const String columnTransportId = 'transportId';
  static const String columnSenderId = 'senderId';
  static const String columnIsSynced = 'isSynced';
  static const String columnLocalId = 'localId';
  static const String columnDateTime = 'dateTime';

  final String type;
  final String description;
  final String attachment;
  final String deliveryId;
  final String transportId;
  final String senderId;
  final bool isSynced;
  final int localId;
  final DateTime dateTime;

  Occurrence({
    required this.type,
    required this.description,
    required this.attachment,
    required this.deliveryId,
    required this.transportId,
    required this.senderId,
    required this.isSynced,
    required this.dateTime,
    this.localId = 0,
  });

  factory Occurrence.fromJson(Map<String, dynamic> json) {
    return Occurrence(
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      attachment: json['attachment'] ?? '',
      deliveryId: json['deliveryId'] ?? '',
      transportId: json['transportId'] ?? '',
      senderId: json['senderId'] ?? '',
      isSynced: json['isSynced'] ?? false,
      localId: json['localId'] ?? 0,
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'attachment': attachment.length < 5 ? 'Sem anexo' : attachment,
      'shipmentId': deliveryId,
      'transportId': transportId,
      'senderId': senderId,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  Map<String, dynamic> toDb() {
    return {
      columnType: type,
      columnDescription: description,
      columnAttachment: attachment,
      columnDeliveryId: deliveryId,
      columnTransportId: transportId,
      columnSenderId: senderId,
      columnIsSynced: isSynced ? 1 : 0,
      columnDateTime: dateTime.toIso8601String(),
    };
  }

  factory Occurrence.fromDb(Map<String, dynamic> db) {
    return Occurrence(
      type: db[columnType],
      description: db[columnDescription],
      attachment: db[columnAttachment],
      deliveryId: db[columnDeliveryId],
      transportId: db[columnTransportId],
      senderId: db[columnSenderId],
      isSynced: db[columnIsSynced] == 1,
      localId: db[columnLocalId] ?? 0,
      dateTime: DateTime.parse(db[columnDateTime]),
    );
  }
}
