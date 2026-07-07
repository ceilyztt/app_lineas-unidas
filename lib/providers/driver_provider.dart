import 'dart:async';
import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class DriverProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  DriverModel? _driver;
  bool _isLoading = false;
  StreamSubscription? _driverSubscription;
  StreamSubscription? _activeRidesSubscription;
  bool _isInitialized = false;

  List<RideModel> _previousActiveRides = [];

  DriverModel? get driver => _driver;
  bool get isLoading => _isLoading;
  bool get isAvailable => _driver?.isAvailable ?? false;
  bool get isApproved => _driver?.isApproved ?? false;
  bool get isInitialized => _isInitialized;

  void loadDriver(String uid) {
    _isInitialized = false;
    _driverSubscription?.cancel();
    _driverSubscription = _firestoreService.streamDriver(uid).listen((driver) {
      _driver = driver;
      _isInitialized = true;
      notifyListeners();
    });

    // Escuchar viajes activos (por si el pasajero envía pago)
    _activeRidesSubscription?.cancel();
    _activeRidesSubscription = _firestoreService.streamDriverActiveRides(uid).listen((rides) {
      for (var ride in rides) {
        final previousRideIndex = _previousActiveRides.indexWhere((r) => r.rideId == ride.rideId);
        if (previousRideIndex != -1) {
          final previousRide = _previousActiveRides[previousRideIndex];
          if (previousRide.status != ride.status || previousRide.paymentStatus != ride.paymentStatus) {
            // Detectar si el método de pago cambió a cash o pago_movil y está pendiente de verificación
            if (ride.status == RideStatus.completed &&
                ride.paymentStatus == 'pending' &&
                previousRide.paymentStatus != 'pending') {
              final paymentMethodText = ride.paymentMethod == 'cash' ? 'efectivo' : 'pago móvil';
              _notificationService.showLocalNotification(
                title: '¡Verificar Pago! 💳',
                body: '${ride.clientName} ha enviado su pago por $paymentMethodText. Por favor verifica.',
                payload: ride.rideId,
              );
            }
          }
        }
      }
      _previousActiveRides = rides;
    });
  }

  // Limpiar suscripciones y datos
  void clearDriver() {
    _driverSubscription?.cancel();
    _activeRidesSubscription?.cancel();
    _driver = null;
    _previousActiveRides = [];
    _isInitialized = false;
    notifyListeners();
  }

  // Cambiar disponibilidad
  Future<void> toggleAvailability(String uid) async {
    if (_driver == null) return;
    _isLoading = true;
    notifyListeners();

    await _firestoreService.toggleDriverAvailability(
      uid,
      !_driver!.isAvailable,
    );

    _isLoading = false;
    notifyListeners();
  }

  // Actualizar perfil del conductor
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    await _firestoreService.updateDriver(uid, data);

    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _driverSubscription?.cancel();
    _activeRidesSubscription?.cancel();
    super.dispose();
  }
}
