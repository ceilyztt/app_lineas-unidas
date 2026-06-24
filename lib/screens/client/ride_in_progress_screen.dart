import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/routing_service.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/ride_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/ride_model.dart';
import '../widgets/ride_info_card.dart';
import '../widgets/panic_button_widget.dart';

class RideInProgressScreen extends StatefulWidget {
  const RideInProgressScreen({super.key});

  @override
  State<RideInProgressScreen> createState() => _RideInProgressScreenState();
}

class _RideInProgressScreenState extends State<RideInProgressScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  String? _lastDriverId;
  LatLng? _lastDriverRoutePos;
  String _getStatusMessage(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
        return 'Buscando conductor cercano...';
      case RideStatus.accepted:
        return '¡Conductor asignado!';
      case RideStatus.driverOnWay:
        return 'El conductor va en camino';
      case RideStatus.inProgress:
        return 'Viaje en progreso';
      case RideStatus.completed:
        return '¡Viaje finalizado!';
      case RideStatus.cancelled:
        return 'Viaje cancelado';
    }
  }

  IconData _getStatusIcon(RideStatus status) {
    switch (status) {
      case RideStatus.requested:
        return Icons.search;
      case RideStatus.accepted:
        return Icons.check_circle;
      case RideStatus.driverOnWay:
        return Icons.directions_car;
      case RideStatus.inProgress:
        return Icons.navigation;
      case RideStatus.completed:
        return Icons.flag;
      case RideStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideProvider>(context);
    final rideObj = rideProvider.currentRide;

    return PopScope(
      canPop: rideObj == null || rideObj.status == RideStatus.cancelled,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final rideProvider = Provider.of<RideProvider>(context, listen: false);
        final ride = rideProvider.currentRide;
        if (ride != null && (ride.status == RideStatus.requested || ride.status == RideStatus.accepted)) {
          await rideProvider.cancelRide(ride.rideId);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        body: Consumer<RideProvider>(
        builder: (context, rideProvider, _) {
          final ride = rideProvider.currentRide;

          if (ride == null) {
            return const Center(
              child: Text(
                'No hay viaje activo',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            );
          }

          // Cargar ruta si hay conductor asignado y aún no se ha cargado (o se movió significativamente)
          final driver = rideProvider.assignedDriver;
          if (driver != null && driver.location != null) {
            final driverPos = LatLng(driver.location!.latitude, driver.location!.longitude);
            
            if (ride.status == RideStatus.driverOnWay) {
              final distanceMoved = _lastDriverRoutePos != null
                  ? Geolocator.distanceBetween(
                      _lastDriverRoutePos!.latitude,
                      _lastDriverRoutePos!.longitude,
                      driverPos.latitude,
                      driverPos.longitude,
                    )
                  : double.infinity;

              if (_lastDriverId != driver.uid || distanceMoved > 50) {
                _lastDriverId = driver.uid;
                _lastDriverRoutePos = driverPos;
                _loadRoute(
                  driverPos,
                  LatLng(ride.pickupLocation.latitude, ride.pickupLocation.longitude),
                );
              }
            } else if (ride.status == RideStatus.inProgress && ride.dropoffLocation != null) {
              final distanceMoved = _lastDriverRoutePos != null
                  ? Geolocator.distanceBetween(
                      _lastDriverRoutePos!.latitude,
                      _lastDriverRoutePos!.longitude,
                      driverPos.latitude,
                      driverPos.longitude,
                    )
                  : double.infinity;

              if (_lastDriverId != driver.uid || distanceMoved > 50) {
                _lastDriverId = driver.uid;
                _lastDriverRoutePos = driverPos;
                _loadRoute(
                  driverPos,
                  LatLng(ride.dropoffLocation!.latitude, ride.dropoffLocation!.longitude),
                );
              }
            }
          }

          // Si el viaje se completó, ir a pago o calificación
          if (ride.status == RideStatus.completed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ride.paymentStatus != 'confirmed') {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.payment,
                  arguments: ride,
                );
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.rating,
                  arguments: ride,
                );
              }
            });
          }

          // Si el viaje fue cancelado (ej: ningún conductor aceptó)
          if (ride.status == RideStatus.cancelled) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.surfaceColor,
                  title: const Text('Viaje Cancelado', style: TextStyle(color: AppTheme.textWhite)),
                  content: const Text(
                    'Lo sentimos, ningún conductor pudo aceptar tu viaje en este momento. Por favor, intenta de nuevo más tarde.',
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Cierra dialog
                        Navigator.pushReplacementNamed(context, AppRoutes.clientHome); // Vuelve al inicio
                      },
                      child: const Text('Aceptar', style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
              );
            });
          }

          return Stack(
            children: [
              // Mapa
              Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  if (locationProvider.currentPosition != null) {
                    return FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          ride.pickupLocation.latitude,
                          ride.pickupLocation.longitude,
                        ),
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.lineasunidas.app',
                        ),
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 4.0,
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: _buildMarkers(ride, rideProvider),
                        ),
                      ],
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                },
              ),

              // Header con estado
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(ride.status),
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getStatusMessage(ride.status),
                            style: const TextStyle(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (ride.status == RideStatus.requested)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Botón de Pánico (Solo si el viaje está en curso o conductor en camino)
              if (ride.status == RideStatus.inProgress || ride.status == RideStatus.driverOnWay)
                const Positioned(
                  bottom: 350,
                  right: 16,
                  child: PanicButtonWidget(role: 'client'),
                ),

              // Bottom sheet con info del viaje
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicador de arrastre
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.textGrey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      if (ride.driverName != null)
                        RideInfoCard(
                          driverName: ride.driverName!,
                          vehicleModel: rideProvider.assignedDriver?.vehicleModel ?? '',
                          vehiclePlate: rideProvider.assignedDriver?.vehiclePlate ?? '',
                          rating: rideProvider.assignedDriver?.avgRating,
                          status: ride.status.name,
                          pickupAddress: ride.pickupAddress,
                          fare: ride.fare,
                        ),

                      if (ride.status == RideStatus.requested) ...[
                        const SizedBox(height: 16),
                        if (ride.rejectedDriverNames.isNotEmpty)
                          Text(
                            'Rechazado por ${ride.rejectedDriverNames.last}...\nBuscando otro conductor cercano',
                            style: const TextStyle(
                                color: AppTheme.errorRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                            textAlign: TextAlign.center,
                          )
                        else
                          const Text(
                            'Buscando al conductor más cercano...',
                            style: TextStyle(color: AppTheme.textGrey),
                            textAlign: TextAlign.center,
                          ),
                      ],

                      const SizedBox(height: 16),

                      // Botón de Chat
                      if (ride.status == RideStatus.accepted || 
                          ride.status == RideStatus.driverOnWay || 
                          ride.status == RideStatus.inProgress)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: StreamBuilder<int>(
                              stream: _firestoreService.streamUnreadMessagesCount(
                                ride.rideId,
                                Provider.of<AuthProvider>(context, listen: false).firebaseUser?.uid ?? '',
                              ),
                              builder: (context, unreadSnapshot) {
                                final count = unreadSnapshot.data ?? 0;
                                return ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, AppRoutes.chat, arguments: ride.rideId);
                                  },
                                  icon: count > 0
                                      ? Badge(
                                          label: Text('$count'),
                                          backgroundColor: AppTheme.errorRed,
                                          textColor: Colors.white,
                                          child: const Icon(Icons.chat),
                                        )
                                      : const Icon(Icons.chat),
                                  label: const Text('CHAT CON CONDUCTOR'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: AppTheme.backgroundColor,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      // Botón cancelar
                      if (ride.status == RideStatus.requested ||
                          ride.status == RideStatus.accepted)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              rideProvider.cancelRide(ride.rideId);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('CANCELAR VIAJE'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorRed,
                              side: const BorderSide(color: AppTheme.errorRed),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }

  Future<void> _loadRoute(LatLng start, LatLng end) async {
    if (_isLoadingRoute) return;
    if (mounted) {
      setState(() => _isLoadingRoute = true);
    }
    
    final result = await RoutingService.getRoute(start, end);
    
    if (mounted) {
      setState(() {
        _routePoints = result?.points ?? [];
        _isLoadingRoute = false;
      });
    }
  }

  List<Marker> _buildMarkers(RideModel ride, RideProvider rideProvider) {
    final markers = <Marker>[];

    // Marcador de recogida
    markers.add(
      Marker(
        point: LatLng(
          ride.pickupLocation.latitude,
          ride.pickupLocation.longitude,
        ),
        width: 40,
        height: 40,
        child: const Icon(
          Icons.person_pin_circle,
          color: AppTheme.successGreen,
          size: 40,
        ),
      ),
    );

    // Marcador del conductor (si está asignado y tiene ubicación)
    final driver = rideProvider.assignedDriver;
    if (driver != null && driver.location != null) {
      markers.add(
        Marker(
          point: LatLng(
            driver.location!.latitude,
            driver.location!.longitude,
          ),
          width: 40,
          height: 40,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_taxi,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
        ),
      );
    }

    // Marcador de destino
    if (ride.dropoffLocation != null) {
      markers.add(
        Marker(
          point: LatLng(
            ride.dropoffLocation!.latitude,
            ride.dropoffLocation!.longitude,
          ),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: AppTheme.errorRed,
            size: 40,
          ),
        ),
      );
    }

    return markers;
  }
}
