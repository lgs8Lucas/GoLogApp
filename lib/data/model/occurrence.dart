class Occurrence {
  static final String tableName = 'occurrence';
  static final String columnType = 'type';
  static final String columnDescription = 'description';
  static final String columnAttachment = 'attachment';
  static final String columnDeliveryId = 'deliveryId';
  static final String columnTransportId = 'transportId';
  static final String columnSenderId = 'senderId';

  final String type;
  final String description;
  final String attachment;
  final String deliveryId;
  final String transportId;
  final String senderId;

  Occurrence({
    required this.type,
    required this.description,
    required this.attachment,
    required this.deliveryId,
    required this.transportId,
    required this.senderId,
  });

  factory Occurrence.fromJson(Map<String, dynamic> json) {
    return Occurrence(
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      attachment: json['attachment'] ?? '',
      deliveryId: json['deliveryId'] ?? '',
      transportId: json['transportId'] ?? '',
      senderId: json['senderId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'attachment': attachment,
      'deliveryId': deliveryId,
      'transportId': transportId,
      'senderId': senderId,
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
    );
  }
}