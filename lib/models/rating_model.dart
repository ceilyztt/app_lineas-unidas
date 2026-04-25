import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String ratingId;
  final String rideId;
  final String driverId;
  final String clientId;
  final String clientName;
  final int stars;
  final String? comment;
  final DateTime createdAt;

  RatingModel({
    required this.ratingId,
    required this.rideId,
    required this.driverId,
    required this.clientId,
    required this.clientName,
    required this.stars,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ratingId': ratingId,
      'rideId': rideId,
      'driverId': driverId,
      'clientId': clientId,
      'clientName': clientName,
      'stars': stars,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      ratingId: map['ratingId'] ?? '',
      rideId: map['rideId'] ?? '',
      driverId: map['driverId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      stars: map['stars'] ?? 0,
      comment: map['comment'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
