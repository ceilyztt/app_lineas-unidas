import 'package:cloud_firestore/cloud_firestore.dart';

enum RideStatus {
  requested,
  accepted,
  driverOnWay,
  inProgress,
  completed,
  cancelled,
}

class RideModel {
  final String rideId;
  final String clientId;
  final String clientName;
  final String? driverId;
  final String? driverName;
  final RideStatus status;
  final GeoPoint pickupLocation;
  final String pickupAddress;
  final GeoPoint? dropoffLocation;
  final String? dropoffAddress;
  final double? fare;
  final double? distance; // en km
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final List<String> rejectedDrivers;
  final List<String> rejectedDriverNames;
  final String? paymentMethod;
  final String? paymentStatus;
  final Map<String, dynamic>? paymentDetails;
  final DateTime? clientLastReadChat;
  final DateTime? driverLastReadChat;

  RideModel({
    required this.rideId,
    required this.clientId,
    required this.clientName,
    this.driverId,
    this.driverName,
    required this.status,
    required this.pickupLocation,
    required this.pickupAddress,
    this.dropoffLocation,
    this.dropoffAddress,
    this.fare,
    this.distance,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.rejectedDrivers = const [],
    this.rejectedDriverNames = const [],
    this.paymentMethod,
    this.paymentStatus,
    this.paymentDetails,
    this.clientLastReadChat,
    this.driverLastReadChat,
  });

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'clientId': clientId,
      'clientName': clientName,
      'driverId': driverId,
      'driverName': driverName,
      'status': status.name,
      'pickupLocation': pickupLocation,
      'pickupAddress': pickupAddress,
      'dropoffLocation': dropoffLocation,
      'dropoffAddress': dropoffAddress,
      'fare': fare,
      'distance': distance,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'rejectedDrivers': rejectedDrivers,
      'rejectedDriverNames': rejectedDriverNames,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentDetails': paymentDetails,
      'clientLastReadChat': clientLastReadChat != null ? Timestamp.fromDate(clientLastReadChat!) : null,
      'driverLastReadChat': driverLastReadChat != null ? Timestamp.fromDate(driverLastReadChat!) : null,
    };
  }

  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      rideId: map['rideId'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      driverId: map['driverId'],
      driverName: map['driverName'],
      status: RideStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideStatus.requested,
      ),
      pickupLocation: map['pickupLocation'] as GeoPoint,
      pickupAddress: map['pickupAddress'] ?? '',
      dropoffLocation: map['dropoffLocation'] as GeoPoint?,
      dropoffAddress: map['dropoffAddress'],
      fare: (map['fare'] as num?)?.toDouble(),
      distance: (map['distance'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      rejectedDrivers: List<String>.from(map['rejectedDrivers'] ?? []),
      rejectedDriverNames: List<String>.from(map['rejectedDriverNames'] ?? []),
      paymentMethod: map['paymentMethod'],
      paymentStatus: map['paymentStatus'],
      paymentDetails: map['paymentDetails'] != null ? Map<String, dynamic>.from(map['paymentDetails']) : null,
      clientLastReadChat: (map['clientLastReadChat'] as Timestamp?)?.toDate(),
      driverLastReadChat: (map['driverLastReadChat'] as Timestamp?)?.toDate(),
    );
  }

  RideModel copyWith({
    String? rideId,
    String? clientId,
    String? clientName,
    String? driverId,
    String? driverName,
    RideStatus? status,
    GeoPoint? pickupLocation,
    String? pickupAddress,
    GeoPoint? dropoffLocation,
    String? dropoffAddress,
    double? fare,
    double? distance,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    List<String>? rejectedDrivers,
    List<String>? rejectedDriverNames,
    String? paymentMethod,
    String? paymentStatus,
    Map<String, dynamic>? paymentDetails,
    DateTime? clientLastReadChat,
    DateTime? driverLastReadChat,
  }) {
    return RideModel(
      rideId: rideId ?? this.rideId,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      status: status ?? this.status,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      fare: fare ?? this.fare,
      distance: distance ?? this.distance,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      rejectedDrivers: rejectedDrivers ?? this.rejectedDrivers,
      rejectedDriverNames: rejectedDriverNames ?? this.rejectedDriverNames,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      clientLastReadChat: clientLastReadChat ?? this.clientLastReadChat,
      driverLastReadChat: driverLastReadChat ?? this.driverLastReadChat,
    );
  }
}
