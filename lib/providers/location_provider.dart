import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  Position? _currentPosition;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionSubscription;
  String? _error;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  String? get error => _error;
  bool get hasLocation => _currentPosition != null;

  // Obtener ubicación actual
  Future<bool> getCurrentLocation() async {
    try {
      _currentPosition = await _locationService.getCurrentPosition();
      if (_currentPosition == null) {
        _error = 'No se pudo obtener la ubicación. Verifica los permisos.';
        notifyListeners();
        return false;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al obtener ubicación: $e';
      notifyListeners();
      return false;
    }
  }

  // Iniciar seguimiento de ubicación (para conductores)
  void startTracking(String? driverId) {
    if (_isTracking) return;

    _isTracking = true;
    _positionSubscription = _locationService
        .getPositionStream(distanceFilter: 20)
        .listen(
      (position) {
        _currentPosition = position;
        notifyListeners();

        // Actualizar ubicación del conductor en Firestore
        if (driverId != null) {
          _firestoreService.updateDriverLocation(
            driverId,
            GeoPoint(position.latitude, position.longitude),
          );
        }
      },
      onError: (e) {
        _error = 'Error en seguimiento: $e';
        notifyListeners();
      },
    );
    notifyListeners();
  }

  // Detener seguimiento
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
