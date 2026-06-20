import 'dart:async';
import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class DriverProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  DriverModel? _driver;
  bool _isLoading = false;
  StreamSubscription? _driverSubscription;
  StreamSubscription? _requestsSubscription;
  StreamSubscription? _activeRidesSubscription;
  StreamSubscription? _messagesSubscription;

  List<RideModel> _previousPendingRequests = [];
  List<RideModel> _previousActiveRides = [];
  List<MessageModel> _previousMessages = [];
  bool _isFirstMessagesLoad = true;
  String? _currentActiveRideId;

  DriverModel? get driver => _driver;
  bool get isLoading => _isLoading;
  bool get isAvailable => _driver?.isAvailable ?? false;
  bool get isApproved => _driver?.isApproved ?? false;

  // Cargar datos del conductor y escuchar solicitudes/viajes en tiempo real
  void loadDriver(String uid) {
    _driverSubscription?.cancel();
    _driverSubscription = _firestoreService.streamDriver(uid).listen((driver) {
      _driver = driver;
      notifyListeners();
    });

    // Escuchar solicitudes pendientes
    _requestsSubscription?.cancel();
    _requestsSubscription = _firestoreService.streamPendingRideRequests(uid).listen((requests) {
      // Si llega una nueva solicitud que no estaba antes en la lista, notificar al conductor
      for (var request in requests) {
        final wasPending = _previousPendingRequests.any((r) => r.rideId == request.rideId);
        if (!wasPending) {
          _notificationService.showLocalNotification(
            title: '¡Nueva solicitud de viaje! 🚕',
            body: '${request.clientName} necesita un viaje en ${request.pickupAddress}',
            payload: request.rideId,
          );
        }
      }
      _previousPendingRequests = requests;
    });

    // Escuchar viajes activos (por si el pasajero cancela o envía pago)
    _activeRidesSubscription?.cancel();
    _activeRidesSubscription = _firestoreService.streamDriverActiveRides(uid).listen((rides) {
      if (rides.isNotEmpty) {
        final activeRide = rides.first;
        if (_currentActiveRideId != activeRide.rideId) {
          _currentActiveRideId = activeRide.rideId;
          _listenToMessages(activeRide.rideId, uid);
        }
      } else {
        _messagesSubscription?.cancel();
        _messagesSubscription = null;
        _currentActiveRideId = null;
        _previousMessages = [];
        _isFirstMessagesLoad = true;
      }

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
            // Detectar si el cliente canceló el viaje
            if (ride.status == RideStatus.cancelled && previousRide.status != RideStatus.cancelled) {
              _notificationService.showLocalNotification(
                title: 'Viaje cancelado ❌',
                body: 'El cliente ha cancelado el viaje.',
                payload: ride.rideId,
              );
            }
          }
        }
      }
      _previousActiveRides = rides;
    });
  }

  void _listenToMessages(String rideId, String currentUserId) {
    _messagesSubscription?.cancel();
    _isFirstMessagesLoad = true;
    _previousMessages = [];
    _messagesSubscription = _firestoreService.streamMessages(rideId).listen((messages) {
      if (_isFirstMessagesLoad) {
        _previousMessages = messages;
        _isFirstMessagesLoad = false;
        return;
      }

      // Solo notificar si la pantalla de chat no está abierta en este viaje
      if (NotificationService.isChatOpen && NotificationService.activeRideId == rideId) {
        _previousMessages = messages;
        return;
      }

      for (var message in messages) {
        final wasNotified = _previousMessages.any((m) => m.id == message.id);
        if (!wasNotified && message.senderId != currentUserId) {
          _notificationService.showLocalNotification(
            title: 'Mensaje de chat 💬',
            body: message.text,
            payload: rideId,
          );
        }
      }
      _previousMessages = messages;
    });
  }

  // Limpiar suscripciones y datos
  void clearDriver() {
    _driverSubscription?.cancel();
    _requestsSubscription?.cancel();
    _activeRidesSubscription?.cancel();
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _driver = null;
    _previousPendingRequests = [];
    _previousActiveRides = [];
    _currentActiveRideId = null;
    _previousMessages = [];
    _isFirstMessagesLoad = true;
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
    _requestsSubscription?.cancel();
    _activeRidesSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
