import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/routing_service.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/ride_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/ride_model.dart';
import '../widgets/ride_info_card.dart';

class RideInProgressScreen extends StatefulWidget {
  const RideInProgressScreen({super.key});

  @override
  State<RideInProgressScreen> createState() => _RideInProgressScreenState();
}

class _RideInProgressScreenState extends State<RideInProgressScreen> {
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  String? _lastDriverId;
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
    return Scaffold(
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

          // Cargar ruta si hay conductor asignado y aún no se ha cargado
          final driver = rideProvider.assignedDriver;
          if (driver != null && driver.location != null && ride.status == RideStatus.driverOnWay) {
            if (_lastDriverId != driver.uid) {
              _lastDriverId = driver.uid;
              _loadRoute(
                LatLng(driver.location!.latitude, driver.location!.longitude),
                LatLng(ride.pickupLocation.latitude, ride.pickupLocation.longitude),
              );
            }
          }

          // Si el viaje se completó, ir a calificación
          if (ride.status == RideStatus.completed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(
                context,
                AppRoutes.rating,
                arguments: ride,
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
                        const Text(
                          'Buscando un conductor cercano...',
                          style: TextStyle(color: AppTheme.textGrey),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 16),

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

    return markers;
  }
}
