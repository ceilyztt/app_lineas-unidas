import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  
  // Nuevos datos personales
  final String address;
  final int age;
  final int yearsOfExperience;
  final String affiliatedLine;

  // Datos del vehículo
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleColor;
  final String vehiclePlate;
  final String vehicleCategory;
  final String? vehiclePhotoFrontUrl;
  final String? vehiclePhotoBackUrl;
  final String? vehiclePhotoInteriorUrl;
  
  // Evaluación Vehicular (Cuestionario)
  final bool hasAirConditioning;
  final String mechanicalCondition;
  final bool hasGoodTires;
  final String cleanlinessLevel;
  final String seatingMaterial;

  final double avgRating;
  final int totalRatings;
  final bool isAvailable;
  final bool isApproved;
  final GeoPoint? location;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime? lastLocationUpdate;
  final bool isRejected;
  final String? rejectionReason;
  final bool isSuspended;
  final String? suspensionReason;
  final bool isDeleted;

  // Datos de Pago Móvil
  final String? bankName;
  final String? bankPhone;
  final String? bankDni;

  DriverModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.address,
    required this.age,
    required this.yearsOfExperience,
    required this.affiliatedLine,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehiclePlate,
    this.vehicleCategory = 'Tipo B - Estándar',
    this.vehiclePhotoFrontUrl,
    this.vehiclePhotoBackUrl,
    this.vehiclePhotoInteriorUrl,
    required this.hasAirConditioning,
    required this.mechanicalCondition,
    required this.hasGoodTires,
    required this.cleanlinessLevel,
    required this.seatingMaterial,
    this.avgRating = 0.0,
    this.totalRatings = 0,
    this.isAvailable = false,
    this.isApproved = false,
    this.location,
    this.fcmToken,
    required this.createdAt,
    this.lastLocationUpdate,
    this.bankName,
    this.bankPhone,
    this.bankDni,
    this.isRejected = false,
    this.rejectionReason,
    this.isSuspended = false,
    this.suspensionReason,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'address': address,
      'age': age,
      'yearsOfExperience': yearsOfExperience,
      'affiliatedLine': affiliatedLine,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'vehiclePlate': vehiclePlate,
      'vehicleCategory': vehicleCategory,
      'vehiclePhotoFrontUrl': vehiclePhotoFrontUrl,
      'vehiclePhotoBackUrl': vehiclePhotoBackUrl,
      'vehiclePhotoInteriorUrl': vehiclePhotoInteriorUrl,
      'hasAirConditioning': hasAirConditioning,
      'mechanicalCondition': mechanicalCondition,
      'hasGoodTires': hasGoodTires,
      'cleanlinessLevel': cleanlinessLevel,
      'seatingMaterial': seatingMaterial,
      'avgRating': avgRating,
      'totalRatings': totalRatings,
      'isAvailable': isAvailable,
      'isApproved': isApproved,
      'location': location,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLocationUpdate': lastLocationUpdate != null ? Timestamp.fromDate(lastLocationUpdate!) : null,
      'bankName': bankName,
      'bankPhone': bankPhone,
      'bankDni': bankDni,
      'isRejected': isRejected,
      'rejectionReason': rejectionReason,
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
      'isDeleted': isDeleted,
    };
  }

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      address: map['address'] ?? '',
      age: map['age'] ?? 0,
      yearsOfExperience: map['yearsOfExperience'] ?? 0,
      affiliatedLine: map['affiliatedLine'] ?? '',
      vehicleBrand: map['vehicleBrand'] ?? '',
      vehicleModel: map['vehicleModel'] ?? '',
      vehicleColor: map['vehicleColor'] ?? '',
      vehiclePlate: map['vehiclePlate'] ?? '',
      vehicleCategory: map['vehicleCategory'] ?? 'Tipo B - Estándar',
      vehiclePhotoFrontUrl: map['vehiclePhotoFrontUrl'],
      vehiclePhotoBackUrl: map['vehiclePhotoBackUrl'],
      vehiclePhotoInteriorUrl: map['vehiclePhotoInteriorUrl'],
      hasAirConditioning: map['hasAirConditioning'] ?? false,
      mechanicalCondition: map['mechanicalCondition'] ?? 'Sin fallas',
      hasGoodTires: map['hasGoodTires'] ?? true,
      cleanlinessLevel: map['cleanlinessLevel'] ?? 'Promedio',
      seatingMaterial: map['seatingMaterial'] ?? 'Tela',
      avgRating: (map['avgRating'] ?? 0.0).toDouble(),
      totalRatings: map['totalRatings'] ?? 0,
      isAvailable: map['isAvailable'] ?? false,
      isApproved: map['isApproved'] ?? false,
      location: map['location'] as GeoPoint?,
      fcmToken: map['fcmToken'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLocationUpdate: (map['lastLocationUpdate'] as Timestamp?)?.toDate(),
      bankName: map['bankName'],
      bankPhone: map['bankPhone'],
      bankDni: map['bankDni'],
      isRejected: map['isRejected'] ?? false,
      rejectionReason: map['rejectionReason'],
      isSuspended: map['isSuspended'] ?? false,
      suspensionReason: map['suspensionReason'],
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  DriverModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? address,
    int? age,
    int? yearsOfExperience,
    String? affiliatedLine,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleColor,
    String? vehiclePlate,
    String? vehicleCategory,
    String? vehiclePhotoFrontUrl,
    String? vehiclePhotoBackUrl,
    String? vehiclePhotoInteriorUrl,
    bool? hasAirConditioning,
    String? mechanicalCondition,
    bool? hasGoodTires,
    String? cleanlinessLevel,
    String? seatingMaterial,
    double? avgRating,
    int? totalRatings,
    bool? isAvailable,
    bool? isApproved,
    GeoPoint? location,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? lastLocationUpdate,
    String? bankName,
    String? bankPhone,
    String? bankDni,
    bool? isRejected,
    String? rejectionReason,
    bool? isSuspended,
    String? suspensionReason,
    bool? isDeleted,
  }) {
    return DriverModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      age: age ?? this.age,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      affiliatedLine: affiliatedLine ?? this.affiliatedLine,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleCategory: vehicleCategory ?? this.vehicleCategory,
      vehiclePhotoFrontUrl: vehiclePhotoFrontUrl ?? this.vehiclePhotoFrontUrl,
      vehiclePhotoBackUrl: vehiclePhotoBackUrl ?? this.vehiclePhotoBackUrl,
      vehiclePhotoInteriorUrl: vehiclePhotoInteriorUrl ?? this.vehiclePhotoInteriorUrl,
      hasAirConditioning: hasAirConditioning ?? this.hasAirConditioning,
      mechanicalCondition: mechanicalCondition ?? this.mechanicalCondition,
      hasGoodTires: hasGoodTires ?? this.hasGoodTires,
      cleanlinessLevel: cleanlinessLevel ?? this.cleanlinessLevel,
      seatingMaterial: seatingMaterial ?? this.seatingMaterial,
      avgRating: avgRating ?? this.avgRating,
      totalRatings: totalRatings ?? this.totalRatings,
      isAvailable: isAvailable ?? this.isAvailable,
      isApproved: isApproved ?? this.isApproved,
      location: location ?? this.location,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      bankName: bankName ?? this.bankName,
      bankPhone: bankPhone ?? this.bankPhone,
      bankDni: bankDni ?? this.bankDni,
      isRejected: isRejected ?? this.isRejected,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
