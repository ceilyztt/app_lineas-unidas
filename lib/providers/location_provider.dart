import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';
import '../services/firestore_service.dart';
import '../config/theme.dart';

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

  // Comprobar GPS y permisos solicitando activación si es necesario de forma interactiva
  Future<bool> checkAndPromptGPSAndPermissions(BuildContext context) async {
    // 1. Verificar si el servicio de GPS está activo
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        final goToSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.gps_off_rounded, color: AppTheme.secondaryColor, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'GPS Desactivado',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'El GPS de tu dispositivo está apagado. Para que Líneas Unidas funcione correctamente y determine tu ubicación real, por favor enciéndelo.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'ACTIVAR GPS',
                  style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

        if (goToSettings == true) {
          await Geolocator.openLocationSettings();
        }
      }
      return false;
    }

    // 2. Verificar y pedir permisos de ubicación
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    // 3. Manejo de permisos denegados permanentemente
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        final goToAppSettings = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.location_off_rounded, color: AppTheme.errorRed, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Permiso Requerido',
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Has denegado los permisos de ubicación permanentemente. Para que la aplicación funcione y localice tu posición real, por favor ve a los ajustes y actívalos manualmente.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'ABRIR AJUSTES',
                  style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

        if (goToAppSettings == true) {
          await Geolocator.openAppSettings();
        }
      }
      return false;
    }

    // Ubicación válida y concedida, la cargamos
    return await getCurrentLocation();
  }

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
  Future<bool> startTracking(String? driverId) async {
    if (_isTracking) return true;

    _isTracking = true;
    _error = null;
    notifyListeners();

    // Obtener ubicación inicial inmediatamente para evitar null en Firestore
    try {
      final hasPermission = await _locationService.checkAndRequestPermission();
      if (!hasPermission) {
        _error = 'Permisos de ubicación denegados o GPS desactivado.';
        _isTracking = false;
        notifyListeners();
        return false;
      }

      final initialPosition = await _locationService.getCurrentPosition();
      if (initialPosition != null) {
        _currentPosition = initialPosition;
        notifyListeners();
        if (driverId != null) {
          await _firestoreService.updateDriverLocation(
            driverId,
            GeoPoint(initialPosition.latitude, initialPosition.longitude),
          );
        }
      } else {
        _error = 'No se pudo obtener la ubicación GPS actual.';
        _isTracking = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error de ubicación: $e';
      _isTracking = false;
      notifyListeners();
      return false;
    }

    _positionSubscription = _locationService
        .getPositionStream(distanceFilter: 20)
        .listen(
      (position) {
        _currentPosition = position;
        _error = null;
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

    return true;
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
