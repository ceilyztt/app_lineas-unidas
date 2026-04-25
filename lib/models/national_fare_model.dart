class NationalFareModel {
  final String fareId;
  final String origin;
  final String destination;
  final double price;
  final String? description;

  NationalFareModel({
    required this.fareId,
    required this.origin,
    required this.destination,
    required this.price,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'fareId': fareId,
      'origin': origin,
      'destination': destination,
      'price': price,
      'description': description,
    };
  }

  factory NationalFareModel.fromMap(Map<String, dynamic> map) {
    return NationalFareModel(
      fareId: map['fareId'] ?? '',
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      description: map['description'],
    );
  }
}
