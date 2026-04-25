import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ride_model.dart';
import '../models/driver_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';

class RideProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  RideModel? _currentRide;
  DriverModel? _assignedDriver;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _rideSubscription;

  RideModel? get currentRide => _currentRide;
  DriverModel? get assignedDriver => _assignedDriver;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveRide => _currentRide != null;

  // ============ CLIENTE: Solicitar taxi ============

  Future<bool> requestRide({
    required String clientId,
    required String clientName,
    required Position pickupPosition,
    required String pickupAddress,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final rideId = FirebaseFirestore.instance.collection('rides').doc().id;

      final ride = RideModel(
        rideId: rideId,
        clientId: clientId,
        clientName: clientName,
        status: RideStatus.requested,
        pickupLocation: GeoPoint(
          pickupPosition.latitude,
          pickupPosition.longitude,
        ),
        pickupAddress: pickupAddress,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createRide(ride);
      _currentRide = ride;

      // Buscar conductor más cercano
      await _findNearestDriver(ride);

      // Escuchar cambios en el viaje
      _listenToRide(rideId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al solicitar taxi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Buscar el conductor disponible más cercano
  Future<void> _findNearestDriver(RideModel ride) async {
    final drivers = await _firestoreService.getAvailableDrivers();

    if (drivers.isEmpty) {
      _error = 'No hay conductores disponibles en este momento.';
      await _firestoreService.updateRide(ride.rideId, {
        'status': RideStatus.cancelled.name,
      });
      notifyListeners();
      return;
    }

    // Filtrar conductores que ya rechazaron
    final availableDrivers = drivers
        .where((d) =>
            !ride.rejectedDrivers.contains(d.uid) && d.location != null)
        .toList();

    if (availableDrivers.isEmpty) {
      _error = 'Ningún conductor disponible pudo aceptar tu solicitud.';
      await _firestoreService.updateRide(ride.rideId, {
        'status': RideStatus.cancelled.name,
      });
      notifyListeners();
      return;
    }

    // Calcular distancias y encontrar el más cercano
    DriverModel? nearestDriver;
    double minDistance = double.infinity;

    for (final driver in availableDrivers) {
      final distance = _locationService.calculateDistance(
        ride.pickupLocation.latitude,
        ride.pickupLocation.longitude,
        driver.location!.latitude,
        driver.location!.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestDriver = driver;
      }
    }

    if (nearestDriver != null) {
      // Asignar conductor al viaje
      await _firestoreService.updateRide(ride.rideId, {
        'driverId': nearestDriver.uid,
        'driverName': nearestDriver.name,
      });

      _assignedDriver = nearestDriver;

      // Notificar al conductor
      _notificationService.showLocalNotification(
        title: '¡Nueva solicitud de viaje!',
        body: '${ride.clientName} necesita un taxi en ${ride.pickupAddress}',
        payload: ride.rideId,
      );
    }
  }

  // Escuchar cambios en el viaje
  void _listenToRide(String rideId) {
    _rideSubscription?.cancel();
    _rideSubscription = _firestoreService.streamRide(rideId).listen((ride) {
      if (ride != null) {
        _currentRide = ride;
        notifyListeners();
      }
    });
  }

  // ============ CONDUCTOR: Aceptar/Rechazar viaje ============

  Future<void> acceptRide(String rideId, String driverId) async {
    await _firestoreService.updateRide(rideId, {
      'status': RideStatus.accepted.name,
      'driverId': driverId,
      'acceptedAt': Timestamp.now(),
    });

    // Notificar al cliente
    _notificationService.showLocalNotification(
      title: '¡Conductor encontrado!',
      body: 'Un conductor ha aceptado tu solicitud.',
      payload: rideId,
    );
  }

  Future<void> rejectRide(String rideId, String driverId) async {
    // Agregar conductor a la lista de rechazados
    final ride = _currentRide;
    if (ride != null) {
      final rejectedList = List<String>.from(ride.rejectedDrivers)
        ..add(driverId);

      await _firestoreService.updateRide(rideId, {
        'driverId': null,
        'driverName': null,
        'rejectedDrivers': rejectedList,
      });

      // Buscar siguiente conductor
      final updatedRide = ride.copyWith(rejectedDrivers: rejectedList);
      await _findNearestDriver(updatedRide);
    }
  }

  // ============ CONDUCTOR: Cambiar estado del viaje ============

  Future<void> startPickup(String rideId) async {
    await _firestoreService.updateRide(rideId, {
      'status': RideStatus.driverOnWay.name,
    });
  }

  Future<void> startTrip(String rideId) async {
    await _firestoreService.updateRide(rideId, {
      'status': RideStatus.inProgress.name,
    });
  }

  Future<void> completeTrip(String rideId, double distanceKm) async {
    final fare = await _firestoreService.calculateFare(distanceKm);

    await _firestoreService.updateRide(rideId, {
      'status': RideStatus.completed.name,
      'fare': fare,
      'distance': distanceKm,
      'completedAt': Timestamp.now(),
    });
  }

  Future<void> cancelRide(String rideId) async {
    await _firestoreService.updateRide(rideId, {
      'status': RideStatus.cancelled.name,
    });
    _currentRide = null;
    _assignedDriver = null;
    notifyListeners();
  }

  // Limpiar estado
  void clearRide() {
    _rideSubscription?.cancel();
    _currentRide = null;
    _assignedDriver = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    super.dispose();
  }
}
