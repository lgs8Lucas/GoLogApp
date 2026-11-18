class Delivery {
  static final String tableName = 'delivery';
  static final String columnId = 'id';
  static final String columnWeight = 'weight';
  static final String columnVolume = 'volume';
  static final String columnScheduledCollection = 'scheduledCollection';
  static final String columnScheduledDelivery = 'scheduledDelivery';
  static final String columnRoutePlanned = 'routePlanned';
  static final String columnRouteCompleted = 'routeCompleted';
  static final String columnStatus = 'status';
  static final String columnDeliverySequence = 'deliverySequence';

  static final String columnDeliveryTypeId = 'deliveryTypeId';
  static final String columnTransportId = 'transportId';
  static final String columnIsPickup = 'isPickup';
  static final String columnDestinationAddress = 'destinationAddress';
  static final String columnDestinationLat = 'destinationLat';
  static final String columnDestinationLng = 'destinationLng';
  static final String columnRecipientName = 'recipientName';

  final String id;
  final double weight;
  final double volume;
  final DateTime shedulind;
  final String routePlanned;
  final String routeCompleted;
  late String status;
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
    required this.shedulind,
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

  factory Delivery.fromJson(Map<String, dynamic> json) {
    var rawAddress = json['address'] ?? json['customer']?['address'];
    return Delivery(
      id: json['id']?.toString() ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      shedulind: DateTime.tryParse(json['shedulind']?.toString() ?? json['schedulind']?.toString() ?? '') ?? DateTime.now(),
      routePlanned: json['routeStop']?['routePlanned']?.toString() ?? json['routePlanned']?.toString() ?? '',
      routeCompleted: json['routeCompleted']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      deliverySequence: (json['routeStop']?['sequenceOrder'] as num?)?.toInt() ?? (json['deliverySequence'] as num?)?.toInt() ?? 0,
      deliveryTypeId: json['shipmentType'] != null
          ? json['shipmentType']['id']?.toString() ?? ''
          : '',
      transportId: json['transport'] != null
          ? json['transport']['id']?.toString() ?? ''
          : (json['transportId']?.toString() ?? ''),
      destinationAddress: _getAddressFromJson(rawAddress),
      recipientName: json['customer']?['legalName']?.toString() ?? '',
      isPickup: json["typeOperation"] == "COLETA",
      destinationLat: _parseCoord(rawAddress?['latitude']),
      destinationLng: _parseCoord(rawAddress?['longitude']),
    );
  }

  static double _parseCoord(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weight': weight,
      'volume': volume,
      'shedulind': shedulind.toIso8601String(),
      'routePlanned': routePlanned,
      'routeCompleted': routeCompleted,
      'status': status,
      'deliverySequence': deliverySequence,
      'isPickup': isPickup,
      'recipientName': recipientName,
    };
  }

  Map<String, dynamic> toDb() {
    return {
      columnId: id,
      columnWeight: weight,
      columnVolume: volume,
      columnScheduledCollection: shedulind.toIso8601String(),
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
      id: db[columnId]?.toString() ?? '',
      weight: (db[columnWeight] as num?)?.toDouble() ?? 0.0,
      volume: (db[columnVolume] as num?)?.toDouble() ?? 0.0,
      shedulind: DateTime.tryParse(db[columnScheduledCollection]?.toString() ?? '') ?? DateTime.now(),
      routePlanned: db[columnRoutePlanned]?.toString() ?? '',
      routeCompleted: db[columnRouteCompleted]?.toString() ?? '',
      status: db[columnStatus]?.toString() ?? '',
      deliverySequence: (db[columnDeliverySequence] as num?)?.toInt() ?? 0,
      deliveryTypeId: db[columnDeliveryTypeId]?.toString() ?? '',
      transportId: db[columnTransportId]?.toString() ?? '',
      destinationAddress: db[columnDestinationAddress]?.toString() ?? '',
      destinationLat: (db[columnDestinationLat] as num?)?.toDouble() ?? 0.0,
      destinationLng: (db[columnDestinationLng] as num?)?.toDouble() ?? 0.0,
      recipientName: db[columnRecipientName]?.toString() ?? '',
      isPickup: db[columnIsPickup] == 1,
    );
  }

  static String _getAddressFromJson(json) {
    if (json == null) return '';
    String street = json['street'] ?? '';
    String number = json['number'] ?? '';
    String city = json['city'] ?? '';
    String state = json['state'] ?? '';
    String zipCode = json['zipCode'] ?? '';
    return '$street, $number, $city, $state, $zipCode';
  }

  static List<Delivery> sortedBySequence(List<Delivery> deliveries) {
    return deliveries..sort((a, b) => a.deliverySequence.compareTo(b.deliverySequence));
  }
}
