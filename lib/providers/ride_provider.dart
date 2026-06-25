import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  StreamSubscription? _driverSubscription;

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
    LatLng? dropoffPosition,
    String? dropoffAddress,
    double? fare,
    double? distance,
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
        dropoffLocation: dropoffPosition != null
            ? GeoPoint(dropoffPosition.latitude, dropoffPosition.longitude)
            : null,
        dropoffAddress: dropoffAddress,
        fare: fare,
        distance: distance,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createRide(ride);
      _currentRide = ride;

      // Buscar conductor más cercano
      final driverFound = await _findNearestDriver(ride);

      if (!driverFound) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

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
  Future<bool> _findNearestDriver(RideModel ride) async {
    final drivers = await _firestoreService.getAvailableDrivers();

    if (drivers.isEmpty) {
      _error = 'Lo sentimos, no hay conductores disponibles en este momento.';
      await _firestoreService.updateRide(ride.rideId, {
        'status': RideStatus.cancelled.name,
      });
      notifyListeners();
      return false;
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
      return false;
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

      // Enviar push notification al conductor asignado
      _notificationService.sendPushNotification(
        recipientId: nearestDriver.uid,
        title: '¡Nueva solicitud de carrera! 🚕',
        body: '${ride.clientName} ha solicitado un taxi.',
        data: {'rideId': ride.rideId, 'type': 'request'},
      );

      return true;
    }
    
    _error = 'No pudimos asignar un conductor a tu viaje.';
    return false;
  }

  Timer? _driverRequestTimer;

  // Método público para iniciar la escucha de un viaje desde fuera (ej: conductor)
  void listenToRide(String rideId) {
    _listenToRide(rideId);
  }

  // Escuchar cambios en el viaje
  void _listenToRide(String rideId) {
    _rideSubscription?.cancel();
    _rideSubscription = _firestoreService.streamRide(rideId).listen((ride) {
      if (ride != null) {
        // --- INICIO LÓGICA DE TIMEOUT ---
        _driverRequestTimer?.cancel();
        
        // Si el viaje está 'requested' y tiene un driver asignado, iniciamos timer de 45s.
        // Esto ocurrirá cada vez que Firestore se actualice (ej: al asignar un nuevo conductor).
        if (ride.status == RideStatus.requested && ride.driverId != null) {
          final assignedDriverId = ride.driverId!;
          _driverRequestTimer = Timer(const Duration(seconds: 45), () async {
            // Verificamos si sigue en 'requested' con el mismo conductor
            if (_currentRide != null && 
                _currentRide!.status == RideStatus.requested && 
                _currentRide!.driverId == assignedDriverId) {
              await rejectRide(ride.rideId, assignedDriverId);
            }
          });
        }
        // --- FIN LÓGICA DE TIMEOUT ---

        // Escuchar la ubicación del conductor asignado en tiempo real
        if (ride.driverId != null) {
          if (_assignedDriver == null || _assignedDriver!.uid != ride.driverId) {
            _listenToDriver(ride.driverId!);
          }
        } else {
          _driverSubscription?.cancel();
          _driverSubscription = null;
          _assignedDriver = null;
        }

        _currentRide = ride;
        notifyListeners();
      }
    });
  }

  void _listenToDriver(String driverId) {
    _driverSubscription?.cancel();
    _driverSubscription = _firestoreService.streamDriver(driverId).listen((driver) {
      _assignedDriver = driver;
      notifyListeners();
    });
  }

  Future<void> _sendStatusPushToPassenger(String rideId, RideStatus status) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
      if (!doc.exists || doc.data() == null) return;
      final ride = RideModel.fromMap(doc.data()!);

      String? title;
      String? body;

      switch (status) {
        case RideStatus.accepted:
          title = '¡Conductor encontrado!';
          body = '${ride.driverName ?? 'Un conductor'} ha aceptado tu solicitud.';
          break;
        case RideStatus.driverOnWay:
          title = '¡Conductor en camino!';
          body = '${ride.driverName ?? 'El conductor'} va en camino a tu ubicación.';
          break;
        case RideStatus.inProgress:
          title = '¡Viaje iniciado!';
          body = 'Estás en camino a tu destino. ¡Disfruta del viaje!';
          break;
        case RideStatus.completed:
          title = '¡Viaje finalizado!';
          body = 'Has llegado a tu destino. Procede a realizar el pago de \$${ride.fare?.toStringAsFixed(2) ?? '0.00'}.';
          break;
        case RideStatus.cancelled:
          title = 'Viaje cancelado';
          body = 'Tu solicitud de viaje ha sido cancelada.';
          break;
        default:
          break;
      }

      if (title != null && body != null) {
        await _notificationService.sendPushNotification(
          recipientId: ride.clientId,
          title: title,
          body: body,
          data: {'rideId': ride.rideId, 'type': 'status'},
        );
      }
    } catch (e) {
      debugPrint("Error sending status push to passenger: $e");
    }
  }

  // ============ CONDUCTOR: Aceptar/Rechazar viaje ============

  Future<void> acceptRide(String rideId, String driverId) async {
    await _firestoreService.updateRide(rideId, {
      'status': RideStatus.accepted.name,
      'driverId': driverId,
      'acceptedAt': Timestamp.now(),
    });
    await _sendStatusPushToPassenger(rideId, RideStatus.accepted);
  }

  Future<void> rejectRide(String rideId, String driverId) async {
    try {
      // 1. Obtener el viaje directamente de Firestore
      final doc = await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
      if (!doc.exists || doc.data() == null) return;
      
      final ride = RideModel.fromMap(doc.data()!);

      // 2. Obtener el nombre del conductor que rechaza para mostrarlo al pasajero
      final driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
      final driverName = driverDoc.exists ? (driverDoc.data()?['name'] ?? 'Un conductor') : 'Un conductor';

      final rejectedList = List<String>.from(ride.rejectedDrivers)..add(driverId);
      final rejectedNamesList = List<String>.from(ride.rejectedDriverNames)..add(driverName);

      // 3. Buscar siguiente conductor disponible
      final drivers = await _firestoreService.getAvailableDrivers();

      // Filtrar conductores que ya rechazaron y que tienen ubicación válida
      final availableDrivers = drivers
          .where((d) =>
              !rejectedList.contains(d.uid) && d.location != null)
          .toList();

      if (availableDrivers.isEmpty) {
        // No hay más conductores disponibles, cancelar el viaje en un solo update
        _error = 'Ningún conductor disponible pudo aceptar tu solicitud.';
        await _firestoreService.updateRide(rideId, {
          'driverId': null,
          'driverName': null,
          'status': RideStatus.cancelled.name,
          'rejectedDrivers': rejectedList,
          'rejectedDriverNames': rejectedNamesList,
        });
        notifyListeners();
        return;
      }

      // 4. Calcular distancias y encontrar el más cercano
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
        // Asignar al siguiente conductor más cercano en un solo update
        await _firestoreService.updateRide(rideId, {
          'driverId': nearestDriver.uid,
          'driverName': nearestDriver.name,
          'rejectedDrivers': rejectedList,
          'rejectedDriverNames': rejectedNamesList,
        });

        // Enviar push notification al nuevo conductor asignado
        _notificationService.sendPushNotification(
          recipientId: nearestDriver.uid,
          title: '¡Nueva solicitud de carrera! 🚕',
          body: '${ride.clientName} ha solicitado un taxi.',
          data: {'rideId': rideId, 'type': 'request'},
        );
      } else {
        // En caso extremo, cancelar en un solo update
        _error = 'No pudimos asignar un conductor a tu viaje.';
        await _firestoreService.updateRide(rideId, {
          'driverId': null,
          'driverName': null,
          'status': RideStatus.cancelled.name,
          'rejectedDrivers': rejectedList,
          'rejectedDriverNames': rejectedNamesList,
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error en rejectRide: $e');
      final context = NotificationService.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar viaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============ CONDUCTOR: Cambiar estado del viaje ============

  Future<void> startPickup(String rideId) async {
    await _firestoreService.updateRide(rideId, {
      'status': RideStatus.driverOnWay.name,
    });
    await _sendStatusPushToPassenger(rideId, RideStatus.driverOnWay);
  }

  Future<void> startTrip(String rideId) async {
    await _firestoreService.updateRide(rideId, {
      'status': RideStatus.inProgress.name,
    });
    await _sendStatusPushToPassenger(rideId, RideStatus.inProgress);
  }

  Future<void> completeTrip(String rideId, double distanceKm) async {
    await _firestoreService.updateRide(rideId, {
      'status': RideStatus.completed.name,
      'distance': distanceKm,
      'completedAt': Timestamp.now(),
    });
    await _sendStatusPushToPassenger(rideId, RideStatus.completed);
  }

  Future<void> cancelRide(String rideId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('rides').doc(rideId).get();
      if (doc.exists && doc.data() != null) {
        final ride = RideModel.fromMap(doc.data()!);
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        await _firestoreService.updateRide(rideId, {
          'status': RideStatus.cancelled.name,
        });

        // Si el cliente cancela, notificar al conductor
        if (currentUserId == ride.clientId && ride.driverId != null) {
          _notificationService.sendPushNotification(
            recipientId: ride.driverId!,
            title: 'Viaje cancelado ❌',
            body: 'El cliente ha cancelado el viaje.',
            data: {'rideId': rideId, 'type': 'cancel'},
          );
        }
        // Si el conductor cancela, notificar al cliente
        else if (currentUserId == ride.driverId) {
          _notificationService.sendPushNotification(
            recipientId: ride.clientId,
            title: 'Viaje cancelado ❌',
            body: 'El conductor ha cancelado el viaje.',
            data: {'rideId': rideId, 'type': 'cancel'},
          );
        }
      }
    } catch (e) {
      debugPrint("Error in cancelRide: $e");
    }
    _currentRide = null;
    _assignedDriver = null;
    notifyListeners();
  }

  // Limpiar estado
  void clearRide() {
    _rideSubscription?.cancel();
    _driverSubscription?.cancel();
    _currentRide = null;
    _assignedDriver = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _driverSubscription?.cancel();
    super.dispose();
  }
}
