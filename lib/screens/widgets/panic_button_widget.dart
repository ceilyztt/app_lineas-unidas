import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/sos_alert_model.dart';
import '../../models/ride_model.dart';

class PanicButtonWidget extends StatefulWidget {
  final String role; // 'client' o 'driver'

  const PanicButtonWidget({super.key, required this.role});

  @override
  State<PanicButtonWidget> createState() => _PanicButtonWidgetState();
}

class _PanicButtonWidgetState extends State<PanicButtonWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSent = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Animación de 3 segundos
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addListener(() {
      setState(() {});
    });

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await _sendSosAlert();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  RideModel? _activeRide;

  void _onPressStart() {
    if (_isSent || _isSending) return;
    _controller.forward(); // Inicia la animación y cuenta regresiva
  }

  void _onPressEnd() {
    if (_isSent || _isSending) return;
    if (_controller.status != AnimationStatus.completed) {
      _controller.reset(); // Reseteo instantáneo a 0 en lugar de rebobinar
    }
  }

  Future<void> _sendSosAlert() async {
    setState(() => _isSending = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final locProvider = Provider.of<LocationProvider>(context, listen: false);

      final currentRide = _activeRide;
      // Solo exigimos viaje activo si el rol es pasajero
      if (widget.role == 'client' && currentRide == null) return;

      final uid = auth.firebaseUser?.uid ?? 'desconocido';
      final name = widget.role == 'client' ? auth.userModel?.name : auth.driverModel?.name;
      final phone = widget.role == 'client' ? auth.userModel?.phone : auth.driverModel?.phone;
      
      final currentPos = locProvider.currentPosition;
      GeoPoint location;
      if (currentPos != null) {
        location = GeoPoint(currentPos.latitude, currentPos.longitude);
      } else if (currentRide != null) {
        // Fallback a la locación original del ride si falla el GPS en ese instante
        location = GeoPoint(currentRide.pickupLocation.latitude, currentRide.pickupLocation.longitude);
      } else {
        location = const GeoPoint(0, 0); // Fallback absoluto si no hay GPS ni viaje
      }

      final alert = SosAlertModel(
        alertId: const Uuid().v4(),
        rideId: currentRide?.rideId ?? 'Conductor sin viaje activo',
        userId: uid,
        userName: name ?? 'Desconocido',
        userPhone: phone ?? 'Desconocido',
        role: widget.role,
        location: location,
        status: 'active',
        timestamp: DateTime.now(),
      );

      await FirestoreService().createSosAlert(alert);

      setState(() => _isSent = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ALERTA ENVIADA AL ADMINISTRADOR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          )
        );
      }
    } catch (e) {
      debugPrint("Error enviando alerta SOS: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role == 'client') {
      final rideProvider = Provider.of<RideProvider>(context);
      final currentRide = rideProvider.currentRide;
      if (currentRide == null) return const SizedBox.shrink();
      return _buildButton(currentRide);
    }

    if (widget.role == 'driver') {
      final auth = Provider.of<AuthProvider>(context);
      if (auth.firebaseUser == null) return const SizedBox.shrink();

      return StreamBuilder<List<RideModel>>(
        stream: FirestoreService().streamDriverActiveRides(auth.firebaseUser!.uid),
        builder: (context, snapshot) {
          final activeRides = snapshot.data ?? [];
          final ride = activeRides.isNotEmpty ? activeRides.first : null;
          return _buildButton(ride);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildButton(RideModel? ride) {
    // Actualizamos la variable local para que _sendSosAlert sepa el ride correcto
    _activeRide = ride;

    // El pasajero solo ve el botón si tiene un viaje en curso o conductor en camino
    if (widget.role == 'client') {
      if (ride == null || !(ride.status == RideStatus.inProgress || ride.status == RideStatus.driverOnWay)) {
        return const SizedBox.shrink();
      }
    }

    if (_isSent) {
      return Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 30),
      );
    }

    return GestureDetector(
      onTapDown: (_) => _onPressStart(),
      onTapUp: (_) => _onPressEnd(),
      onTapCancel: () => _onPressEnd(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              value: _controller.value,
              strokeWidth: 6,
              color: Colors.red,
              backgroundColor: Colors.transparent,
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _controller.isAnimating ? Colors.red.withOpacity(0.8) : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            ),
            child: _isSending 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.sos, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}
