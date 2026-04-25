import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          ride.pickupLocation.latitude,
                          ride.pickupLocation.longitude,
                        ),
                        zoom: 15,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      markers: _buildMarkers(ride),
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

  Set<Marker> _buildMarkers(RideModel ride) {
    final markers = <Marker>{};

    // Marcador de recogida
    markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          ride.pickupLocation.latitude,
          ride.pickupLocation.longitude,
        ),
        infoWindow: InfoWindow(title: 'Punto de recogida'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    return markers;
  }
}
