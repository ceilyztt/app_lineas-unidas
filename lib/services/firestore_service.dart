import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_upload_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../models/rating_model.dart';
import '../models/national_fare_model.dart';
import '../models/message_model.dart';
import '../models/sos_alert_model.dart';

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
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .where('isAvailable', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .get();

      final List<DriverModel> list = [];
      for (var doc in snapshot.docs) {
        try {
          list.add(DriverModel.fromMap(doc.data()));
        } catch (e) {
          debugPrint("Error parsing driver ${doc.id}: $e");
        }
      }
      return list.where((d) => d.isSuspended != true && d.isDeleted != true).toList();
    } catch (e) {
      debugPrint("Error in getAvailableDrivers: $e");
      return [];
    }
  }

  // Actualizar ubicación del conductor
  Future<void> updateDriverLocation(String uid, GeoPoint location) async {
    await _firestore.collection('drivers').doc(uid).update({
      'location': location,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Cambiar disponibilidad
  Future<void> toggleDriverAvailability(String uid, bool isAvailable) async {
    await _firestore.collection('drivers').doc(uid).update({
      'isAvailable': isAvailable,
      if (isAvailable) 'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  // ============ VIAJES ============

  Future<void> createRide(RideModel ride) async {
    await _firestore.collection('rides').doc(ride.rideId).set(ride.toMap());
  }

  Future<void> updateRide(String rideId, Map<String, dynamic> data) async {
    await _firestore.collection('rides').doc(rideId).update(data);
  }

  Future<RideModel?> getRide(String rideId) async {
    final doc = await _firestore.collection('rides').doc(rideId).get();
    if (doc.exists && doc.data() != null) {
      return RideModel.fromMap(doc.data()!);
    }
    return null;
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
        .where('status', whereIn: ['requested', 'accepted', 'driverOnWay', 'inProgress', 'completed'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideModel.fromMap(doc.data()))
            .where((ride) => ride.status != RideStatus.completed || ride.paymentStatus != 'confirmed')
            .toList());
  }

  // Viajes asignados al conductor
  Stream<List<RideModel>> streamDriverActiveRides(String driverId) {
    return _firestore
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['accepted', 'driverOnWay', 'inProgress', 'completed'])
        .snapshots()
        .map((snapshot) {
      final List<RideModel> list = [];
      for (var doc in snapshot.docs) {
        try {
          list.add(RideModel.fromMap(doc.data()));
        } catch (e) {
          debugPrint("Error parsing active ride ${doc.id}: $e");
        }
      }
      return list.where((ride) => ride.status != RideStatus.completed || ride.paymentStatus != 'confirmed').toList();
    });
  }

  // Solicitudes pendientes para conductores (viajes solicitados asignados a este conductor)
  Stream<List<RideModel>> streamPendingRideRequests(String driverId) {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: 'requested')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      final List<RideModel> list = [];
      for (var doc in snapshot.docs) {
        try {
          list.add(RideModel.fromMap(doc.data()));
        } catch (e) {
          debugPrint("Error parsing pending ride ${doc.id}: $e");
        }
      }
      return list;
    });
  }

  // Ganancias del conductor (todos los viajes completados)
  Stream<List<RideModel>> streamDriverEarnings(String driverId) {
    return _firestore
        .collection('rides')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'completed')
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
        .where('status', isEqualTo: 'completed')
        .get();

    final rides = snapshot.docs
        .map((doc) => RideModel.fromMap(doc.data()))
        .toList();
        
    // Ordenar localmente para evadir el Índice Compuesto
    rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rides.take(50).toList();
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
        .get();

    final ratings = snapshot.docs
        .map((doc) => RatingModel.fromMap(doc.data()))
        .toList();
        
    ratings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ratings.take(20).toList();
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

  // ============ CHAT ============

  Future<void> sendMessage(String rideId, MessageModel message) async {
    await _firestore
        .collection('rides')
        .doc(rideId)
        .collection('messages')
        .add(message.toMap());
  }

  Stream<List<MessageModel>> streamMessages(String rideId) {
    return _firestore
        .collection('rides')
        .doc(rideId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<int> streamUnreadMessagesCount(String rideId, String currentUserId) {
    late StreamController<int> controller;
    StreamSubscription? rideSub;
    StreamSubscription? msgSub;

    controller = StreamController<int>(
      onListen: () {
        void update() async {
          try {
            final rideSnap = await _firestore.collection('rides').doc(rideId).get();
            if (!rideSnap.exists) {
              if (!controller.isClosed) controller.add(0);
              return;
            }
            final rideData = rideSnap.data() ?? {};
            final clientId = rideData['clientId'];
            final driverId = rideData['driverId'];
            
            DateTime? lastRead;
            if (currentUserId == clientId) {
              final ts = rideData['clientLastReadChat'] as Timestamp?;
              lastRead = ts?.toDate();
            } else if (currentUserId == driverId) {
              final ts = rideData['driverLastReadChat'] as Timestamp?;
              lastRead = ts?.toDate();
            }

            final messagesSnap = await _firestore
                .collection('rides')
                .doc(rideId)
                .collection('messages')
                .get();

            final count = messagesSnap.docs.where((doc) {
              final data = doc.data();
              final senderId = data['senderId'] ?? '';
              if (senderId == currentUserId) return false;
              if (lastRead == null) return true;
              
              final timestampTs = data['timestamp'] as Timestamp?;
              final timestamp = timestampTs?.toDate() ?? DateTime.now();
              return timestamp.isAfter(lastRead);
            }).length;

            if (!controller.isClosed) {
              controller.add(count);
            }
          } catch (e) {
            debugPrint("Error updating unread count: $e");
          }
        }

        // Escuchar cambios del viaje y de los mensajes
        rideSub = _firestore.collection('rides').doc(rideId).snapshots().listen((_) => update());
        msgSub = _firestore.collection('rides').doc(rideId).collection('messages').snapshots().listen((_) => update());
        
        // Ejecución inicial rápida
        update();
      },
      onCancel: () {
        rideSub?.cancel();
        msgSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> markChatAsRead(String rideId, String userId) async {
    try {
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (rideDoc.exists) {
        final data = rideDoc.data();
        if (data != null) {
          final clientId = data['clientId'];
          final driverId = data['driverId'];
          if (userId == clientId) {
            await _firestore.collection('rides').doc(rideId).update({
              'clientLastReadChat': FieldValue.serverTimestamp(),
            });
          } else if (userId == driverId) {
            await _firestore.collection('rides').doc(rideId).update({
              'driverLastReadChat': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error marking chat as read: $e");
    }
  }

  // Subir captura de pago móvil a Firebase Storage
  Future<String?> uploadPaymentScreenshot(String rideId, File file) async {
    return await ApiUploadService.subirImagenAInternet(file);
  }

  // ============ BOTÓN DE PÁNICO (SOS) ============

  Future<void> createSosAlert(SosAlertModel alert) async {
    await _firestore.collection('sos_alerts').doc(alert.alertId).set(alert.toMap());
  }

  Stream<List<SosAlertModel>> streamActiveSosAlerts() {
    return _firestore
        .collection('sos_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SosAlertModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> resolveSosAlert(String alertId) async {
    await _firestore.collection('sos_alerts').doc(alertId).update({
      'status': 'resolved',
    });
  }
}
