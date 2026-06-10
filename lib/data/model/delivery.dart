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
    return Delivery(
      id: json['id'] ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
      shedulind: DateTime.parse(json['shedulind']),
      routePlanned: json['routePlanned'] ?? '',
      routeCompleted: json['routeCompleted'] ?? '',
      status: json['status'] ?? '',
      deliverySequence: json['routeStop']?['sequenceOrder'].toInt() ?? 0,
      deliveryTypeId: json['shipmentType'] != null
          ? json['shipmentType']['id'] ?? ''
          : '',
      transportId: json['transport'] != null
          ? json['transport']['id'] ?? ''
          : '',
      destinationAddress: json['address'] != null
          ? _getAddressFromJson(json['address'])
          : '',
      recipientName: json['customer']?['legalName'] ?? '',
      isPickup: json["typeOperation"] == "COLETA",
      destinationLat: double.tryParse(json['address']?['latitude']??'0') ?? 0.0,
      destinationLng: double.tryParse(json['address']?['longitude']??'0') ?? 0.0,
    );
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
      id: db[columnId],
      weight: db[columnWeight],
      volume: db[columnVolume],
      shedulind: DateTime.parse(db[columnScheduledCollection]),
      routePlanned: db[columnRoutePlanned],
      routeCompleted: db[columnRouteCompleted],
      status: db[columnStatus],
      deliverySequence: db[columnDeliverySequence],
      deliveryTypeId: db[columnDeliveryTypeId] ?? '',
      transportId: db[columnTransportId] ?? '',
      destinationAddress: db[columnDestinationAddress] ?? '',
      destinationLat: (db[columnDestinationLat] as num?)?.toDouble() ?? 0.0,
      destinationLng: (db[columnDestinationLng] as num?)?.toDouble() ?? 0.0,
      recipientName: db[columnRecipientName] ?? '',
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
