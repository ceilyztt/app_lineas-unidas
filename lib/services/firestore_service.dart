import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../models/rating_model.dart';
import '../models/national_fare_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ USUARIOS ============

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // ============ CONDUCTORES ============

  Future<void> updateDriver(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('drivers').doc(uid).update(data);
  }

  Stream<DriverModel?> streamDriver(String uid) {
    return _firestore.collection('drivers').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return DriverModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Obtener conductores disponibles
  Future<List<DriverModel>> getAvailableDrivers() async {
    final snapshot = await _firestore
        .collection('drivers')
        .where('isAvailable', isEqualTo: true)
        .where('isApproved', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => DriverModel.fromMap(doc.data()))
        .toList();
  }

  // Actualizar ubicación del conductor
  Future<void> updateDriverLocation(String uid, GeoPoint location) async {
    await _firestore.collection('drivers').doc(uid).update({
      'location': location,
    });
  }

  // Cambiar disponibilidad
  Future<void> toggleDriverAvailability(String uid, bool isAvailable) async {
    await _firestore.collection('drivers').doc(uid).update({
      'isAvailable': isAvailable,
    });
  }

  // ============ VIAJES ============

  Future<void> createRide(RideModel ride) async {
    await _firestore.collection('rides').doc(ride.rideId).set(ride.toMap());
  }

  Future<void> updateRide(String rideId, Map<String, dynamic> data) async {
    await _firestore.collection('rides').doc(rideId).update(data);
  }

  Stream<RideModel?> streamRide(String rideId) {
    return _firestore.collection('rides').doc(rideId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return RideModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Viajes activos del cliente
  Stream<List<RideModel>> streamClientActiveRides(String clientId) {
    return _firestore
        .collection('rides')
        .where('clientId', isEqualTo: clientId)
        .where('status', whereIn: ['requested', 'accepted', 'driverOnWay', 'inProgress'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromMap(doc.data()))
            .toList());
  }

  // Viajes asignados al conductor
  Stream<List<RideModel>> streamDriverActiveRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['accepted', 'driverOnWay', 'inProgress'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromMap(doc.data()))
            .toList());
  }

  // Solicitudes pendientes para conductores (viajes solicitados asignados a este conductor)
  Stream<List<RideModel>> streamPendingRideRequests(String driverId) {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: 'requested')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromMap(doc.data()))
            .toList());
  }

  // Historial de viajes
  Future<List<RideModel>> getRideHistory(String userId, String role) async {
    final field = role == 'client' ? 'clientId' : 'driverId';
    final snapshot = await _firestore
        .collection('rides')
        .where(field, isEqualTo: userId)
        .where('status', whereIn: ['completed', 'cancelled'])
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => RideModel.fromMap(doc.data()))
        .toList();
  }

  // ============ CALIFICACIONES ============

  Future<void> createRating(RatingModel rating) async {
    await _firestore.collection('ratings').doc(rating.ratingId).set(rating.toMap());

    // Actualizar promedio del conductor
    final ratingsSnapshot = await _firestore
        .collection('ratings')
        .where('driverId', isEqualTo: rating.driverId)
        .get();

    double totalStars = 0;
    for (var doc in ratingsSnapshot.docs) {
      totalStars += (doc.data()['stars'] as num).toDouble();
    }
    final avgRating = totalStars / ratingsSnapshot.docs.length;

    await _firestore.collection('drivers').doc(rating.driverId).update({
      'avgRating': avgRating,
      'totalRatings': ratingsSnapshot.docs.length,
    });
  }

  // Calificaciones de un conductor
  Future<List<RatingModel>> getDriverRatings(String driverId) async {
    final snapshot = await _firestore
        .collection('ratings')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => RatingModel.fromMap(doc.data()))
        .toList();
  }

  // ============ TARIFAS NACIONALES ============

  Future<List<NationalFareModel>> getNationalFares() async {
    final snapshot = await _firestore
        .collection('national_fares')
        .orderBy('origin')
        .get();

    return snapshot.docs
        .map((doc) => NationalFareModel.fromMap(doc.data()))
        .toList();
  }

  // ============ CONFIGURACIÓN ============

  Future<Map<String, dynamic>> getFareConfig() async {
    final doc = await _firestore.collection('config').doc('fares').get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!;
    }
    // Valores por defecto
    return {
      'fareBase': 2.0,
      'pricePerKm': 1.5,
    };
  }

  // Calcular tarifa
  Future<double> calculateFare(double distanceKm) async {
    final config = await getFareConfig();
    final fareBase = (config['fareBase'] as num).toDouble();
    final pricePerKm = (config['pricePerKm'] as num).toDouble();
    return fareBase + (distanceKm * pricePerKm);
  }
}
