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
  static final String columnOriginAddressId = 'originAddressId';
  static final String columnDestinationAddressId = 'destinationAddressId';
  static final String columnIsPickup = 'isPickup';

  final String id;
  final double weight;
  final double volume;
  final DateTime shedulind;
  final String routePlanned;
  final String routeCompleted;
  final String status;
  final int deliverySequence;
  final bool isPickup;

  final String deliveryTypeId;
  final String transportId;
  final String originAddressId;
  final String destinationAddressId;
  final String destinationAddress;
  final String recipientName;

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
    required this.originAddressId,
    required this.destinationAddressId,
    required this.destinationAddress,
    required this.recipientName,
    required this.isPickup,
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
      deliverySequence: json['shippingSequence'].toInt() ?? 0,
      deliveryTypeId: json['deliveryType'] != null
          ? json['deliveryType']['id'] ?? ''
          : '',
      transportId: json['transport'] != null
          ? json['transport']['id'] ?? ''
          : '',
      originAddressId: json['originAdrress'] != null
          ? json['originAdrress']['id'] ?? ''
          : '',
      destinationAddressId: json['destinationAddress'] != null
          ? json['destinationAddress']['id'] ?? ''
          : '',
      destinationAddress: _getAddressFromJson(json['destinationAddress']),
      recipientName: json['customerDelivery']?['legalName'] ?? '',
      isPickup: json["typeOperation"] == "COLETA",
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
      columnOriginAddressId: originAddressId,
      columnDestinationAddressId: destinationAddressId,
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
      originAddressId: db[columnOriginAddressId] ?? '',
      destinationAddressId: db[columnDestinationAddressId] ?? '',
      destinationAddress: '',
      recipientName: '',
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
}
