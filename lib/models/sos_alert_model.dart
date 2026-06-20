import 'package:cloud_firestore/cloud_firestore.dart';

class SosAlertModel {
  final String alertId;
  final String rideId;
  final String userId;
  final String userName;
  final String userPhone;
  final String role; // 'client' o 'driver'
  final GeoPoint location;
  final String status; // 'active', 'resolved'
  final DateTime timestamp;

  SosAlertModel({
    required this.alertId,
    required this.rideId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.role,
    required this.location,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'rideId': rideId,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'role': role,
      'location': location,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory SosAlertModel.fromMap(Map<String, dynamic> map) {
    return SosAlertModel(
      alertId: map['alertId'] ?? '',
      rideId: map['rideId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Desconocido',
      userPhone: map['userPhone'] ?? 'Desconocido',
      role: map['role'] ?? '',
      location: map['location'] as GeoPoint,
      status: map['status'] ?? 'active',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
