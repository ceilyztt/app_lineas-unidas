import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/ride_provider.dart';
import '../../models/ride_model.dart';
import '../../services/firestore_service.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  void _init() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    if (authProvider.firebaseUser != null) {
      driverProvider.loadDriver(authProvider.firebaseUser!.uid);
      locationProvider.getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildDriverHeader(context, authProvider),
          // Toggle de disponibilidad
          Consumer<DriverProvider>(
            builder: (context, driverProvider, _) {
              final driver = driverProvider.driver;

              if (driver == null) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }

              if (!driver.isApproved) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: AppTheme.secondaryColor,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aprobación Pendiente',
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tu cuenta está en revisión. Un administrador debe aprobar tu perfil para que puedas recibir viajes.',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: driver.isAvailable
                      ? AppTheme.successGreen.withValues(alpha: 0.1)
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: driver.isAvailable
                        ? AppTheme.successGreen.withValues(alpha: 0.3)
                        : AppTheme.cardColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      driver.isAvailable
                          ? Icons.wifi_tethering
                          : Icons.wifi_tethering_off,
                      color: driver.isAvailable
                          ? AppTheme.successGreen
                          : AppTheme.textGrey,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.isAvailable
                                ? 'Disponible'
                                : 'No disponible',
                            style: TextStyle(
                              color: driver.isAvailable
                                  ? AppTheme.successGreen
                                  : AppTheme.textGrey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            driver.isAvailable
                                ? 'Recibiendo solicitudes'
                                : 'No recibirás solicitudes',
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: driver.isAvailable,
                      onChanged: (value) {
                        final uid = authProvider.firebaseUser!.uid;
                        driverProvider.toggleAvailability(uid);

                        final locationProvider =
                            Provider.of<LocationProvider>(context,
                                listen: false);
                        if (value) {
                          locationProvider.startTracking(uid);
                        } else {
                          locationProvider.stopTracking();
                        }
                      },
                      activeThumbColor: AppTheme.successGreen,
                    ),
                  ],
                ),
              );
            },
          ),

          // Imagen del Equipo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/team_welcome.png',
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image,
                            color: AppTheme.primaryColor, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Guarda tu imagen como\nassets/images/team_welcome.png',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mapa
          Expanded(
            child: Consumer<LocationProvider>(
              builder: (context, locationProvider, _) {
                if (locationProvider.currentPosition != null) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          locationProvider.currentPosition!.latitude,
                          locationProvider.currentPosition!.longitude,
                        ),
                        zoom: 15,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  );
                }
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Obteniendo ubicación...',
                        style: TextStyle(color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Solicitudes pendientes
          Consumer<DriverProvider>(
            builder: (context, driverProvider, _) {
              if (driverProvider.driver?.isAvailable != true) {
                return const SizedBox.shrink();
              }

              return StreamBuilder<List<RideModel>>(
                stream: _firestoreService.streamPendingRideRequests(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'Esperando solicitudes...',
                        style: TextStyle(color: AppTheme.textGrey),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final rides = snapshot.data!.where((ride) =>
                      ride.driverId == authProvider.firebaseUser?.uid);

                  if (rides.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'Sin solicitudes pendientes',
                        style: TextStyle(color: AppTheme.textGrey),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.backgroundColor,
                    child: Column(
                      children: rides.map((ride) => _buildRideRequest(ride)).toList(),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverHeader(BuildContext context, AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 32,
                      width: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Líneas Unidas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.people_alt, color: AppTheme.textWhite),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.directory),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: AppTheme.textWhite),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.rideHistory),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person, color: AppTheme.textWhite),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.driverProfile),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '¡Hola, ${authProvider.userModel?.name ?? 'Conductor'}! 🚕',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '¿Listo para tu próximo servicio? Enciende tu radar y comienza a generar ingresos hoy mismo.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textGrey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideRequest(RideModel ride) {
    return Card(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notification_important,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '¡Nueva solicitud!',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${ride.clientName}',
              style: const TextStyle(color: AppTheme.textWhite),
            ),
            Text(
              'Ubicación: ${ride.pickupAddress}',
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final rideProvider =
                          Provider.of<RideProvider>(context, listen: false);
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      rideProvider.rejectRide(
                        ride.rideId,
                        authProvider.firebaseUser!.uid,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: const BorderSide(color: AppTheme.errorRed),
                    ),
                    child: const Text('RECHAZAR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final rideProvider =
                          Provider.of<RideProvider>(context, listen: false);
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      rideProvider.acceptRide(
                        ride.rideId,
                        authProvider.firebaseUser!.uid,
                      );
                    },
                    child: const Text('ACEPTAR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
