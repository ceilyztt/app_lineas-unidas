import 'dart:async';
import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../services/firestore_service.dart';

class DriverProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  DriverModel? _driver;
  bool _isLoading = false;
  StreamSubscription? _driverSubscription;

  DriverModel? get driver => _driver;
  bool get isLoading => _isLoading;
  bool get isAvailable => _driver?.isAvailable ?? false;
  bool get isApproved => _driver?.isApproved ?? false;

  // Cargar datos del conductor
  void loadDriver(String uid) {
    _driverSubscription?.cancel();
    _driverSubscription = _firestoreService.streamDriver(uid).listen((driver) {
      _driver = driver;
      notifyListeners();
    });
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
    super.dispose();
  }
}
