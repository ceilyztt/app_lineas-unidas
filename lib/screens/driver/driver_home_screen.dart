import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/routing_service.dart';
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
  List<LatLng> _routePoints = [];
  String? _currentRideIdForRoute;

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

  void _loadRouteForRide(RideModel ride) async {
    if (_currentRideIdForRoute == ride.rideId || ride.dropoffLocation == null) {
      return;
    }
    _currentRideIdForRoute = ride.rideId;
    
    final result = await RoutingService.getRoute(
      LatLng(ride.pickupLocation.latitude, ride.pickupLocation.longitude),
      LatLng(ride.dropoffLocation!.latitude, ride.dropoffLocation!.longitude),
    );
    
    if (result != null && mounted) {
      setState(() {
        _routePoints = result.points;
      });
    }
  }

  void _clearRoute() {
    if (_routePoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _routePoints = [];
            _currentRideIdForRoute = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
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

          // Solicitudes pendientes o Viaje Activo
          Consumer<DriverProvider>(
            builder: (context, driverProvider, _) {
              if (driverProvider.driver?.isAvailable != true) {
                _clearRoute();
                return const SizedBox.shrink();
              }

              final uid = authProvider.firebaseUser!.uid;

              // Primero: escuchar viajes activos
              return StreamBuilder<List<RideModel>>(
                stream: _firestoreService.streamDriverActiveRides(uid),
                builder: (context, activeSnapshot) {
                  final activeRides = activeSnapshot.data ?? [];

                  if (activeRides.isNotEmpty) {
                    final activeRide = activeRides.first;
                    _loadRouteForRide(activeRide);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.backgroundColor,
                      child: ActiveRideCard(ride: activeRide),
                    );
                  }

                  // Segundo: si no hay viaje activo, escuchar pendientes
                  return StreamBuilder<List<RideModel>>(
                    stream: _firestoreService.streamPendingRideRequests(uid),
                    builder: (context, pendingSnapshot) {
                      if (!pendingSnapshot.hasData || pendingSnapshot.data!.isEmpty) {
                        _clearRoute();
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: const Text(
                            'Esperando solicitudes...',
                            style: TextStyle(color: AppTheme.textGrey),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final pendingRides = pendingSnapshot.data!;

                      if (pendingRides.isEmpty) {
                        _clearRoute();
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: const Text(
                            'Sin solicitudes pendientes',
                            style: TextStyle(color: AppTheme.textGrey),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final pendingRide = pendingRides.first;
                      _loadRouteForRide(pendingRide);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        color: AppTheme.backgroundColor,
                        child: RideRequestCard(ride: pendingRide),
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Mapa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 300, // Altura reducida para que sea más pequeño
              child: Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  if (locationProvider.currentPosition != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          locationProvider.currentPosition!.latitude,
                          locationProvider.currentPosition!.longitude,
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
                          markers: [
                            Marker(
                              point: LatLng(
                                locationProvider.currentPosition!.latitude,
                                locationProvider.currentPosition!.longitude,
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
                          ],
                        ),
                      ],
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
          ),
          const SizedBox(height: 20),
        ],
        ),
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

}

class RideRequestCard extends StatefulWidget {
  final RideModel ride;

  const RideRequestCard({super.key, required this.ride});

  @override
  State<RideRequestCard> createState() => _RideRequestCardState();
}

class _RideRequestCardState extends State<RideRequestCard> {
  int _timeLeft = 15;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    FlutterRingtonePlayer().playAlarm(looping: true, volume: 1.0, asAlarm: true);
  }

  void _stopSound() {
    try {
      FlutterRingtonePlayer().stop();
    } catch (_) {}
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          _autoReject();
        }
      });
    });
  }

  void _autoReject() {
    _stopSound();
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    rideProvider.rejectRide(
      widget.ride.rideId,
      authProvider.firebaseUser!.uid,
    );
  }

  @override
  void dispose() {
    _stopSound();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    
    return Card(
      color: AppTheme.primaryColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: _timeLeft / 15,
                        backgroundColor: AppTheme.backgroundColor,
                        color: _timeLeft <= 5 ? AppTheme.errorRed : AppTheme.primaryColor,
                        strokeWidth: 5,
                      ),
                    ),
                    Text(
                      '${_timeLeft}s',
                      style: TextStyle(
                        color: _timeLeft <= 5 ? AppTheme.errorRed : AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${ride.clientName}',
              style: const TextStyle(color: AppTheme.textWhite),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.my_location, color: AppTheme.successGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.pickupAddress,
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (ride.dropoffAddress != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.errorRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.dropoffAddress!,
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            if (ride.distance != null || ride.fare != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (ride.distance != null)
                      Row(
                        children: [
                          const Icon(Icons.route, color: AppTheme.primaryColor, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${ride.distance!.toStringAsFixed(1)} km',
                            style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    if (ride.fare != null)
                      Row(
                        children: [
                          const Icon(Icons.payments, color: AppTheme.successGreen, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '\$${ride.fare!.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _autoReject,
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
                      _stopSound();
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

class ActiveRideCard extends StatelessWidget {
  final RideModel ride;

  const ActiveRideCard({super.key, required this.ride});

  Future<void> _openNavigation() async {
    // Si el viaje está en progreso, navegamos al destino. De lo contrario, al punto de recogida.
    final isGoingToDropoff = ride.status == RideStatus.inProgress && ride.dropoffLocation != null;
    
    final lat = isGoingToDropoff ? ride.dropoffLocation!.latitude : ride.pickupLocation.latitude;
    final lng = isGoingToDropoff ? ride.dropoffLocation!.longitude : ride.pickupLocation.longitude;

    // Intentar con esquemas de app directos y web como fallback
    final wazeAppUrl = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    final mapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final wazeWebUrl = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');

    try {
      // 1. Intenta abrir la app de Waze directamente
      bool launched = await launchUrl(wazeAppUrl, mode: LaunchMode.externalApplication);
      
      // 2. Si no tiene Waze, intenta Google Maps
      if (!launched) {
        launched = await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
      }
      
      // 3. Si tampoco tiene Google Maps (raro en Android), intenta Waze por la web
      if (!launched) {
        await launchUrl(wazeWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Si falla cualquier esquema por políticas de Android 11+, forzamos el fallback a Maps URL
      try {
        await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
      } catch (e2) {
        debugPrint('No se pudo abrir ninguna app de navegación: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    
    String statusText = '';
    Color statusColor = AppTheme.primaryColor;
    
    if (ride.status == RideStatus.accepted) {
      statusText = 'VIAJE ACEPTADO';
      statusColor = AppTheme.successGreen;
    } else if (ride.status == RideStatus.driverOnWay) {
      statusText = 'EN CAMINO';
      statusColor = Colors.orangeAccent;
    } else if (ride.status == RideStatus.inProgress) {
      statusText = 'VIAJE EN PROGRESO';
      statusColor = AppTheme.primaryColor;
    }

    return Card(
      color: statusColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Cliente: ${ride.clientName}',
              style: const TextStyle(color: AppTheme.textWhite, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.my_location, color: AppTheme.successGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.pickupAddress,
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (ride.dropoffAddress != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.errorRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.dropoffAddress!,
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.navigation),
                label: const Text('NAVEGAR (WAZE / MAPS)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceColor,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _openNavigation,
              ),
            ),
            const SizedBox(height: 12),
            if (ride.status == RideStatus.accepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => rideProvider.startPickup(ride.rideId),
                  child: const Text('VOY EN CAMINO'),
                ),
              ),
            if (ride.status == RideStatus.driverOnWay)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => rideProvider.startTrip(ride.rideId),
                  child: const Text('INICIAR VIAJE (PASAJERO A BORDO)'),
                ),
              ),
            if (ride.status == RideStatus.inProgress)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                  onPressed: () => rideProvider.completeTrip(ride.rideId, ride.distance ?? 0.0),
                  child: const Text('FINALIZAR VIAJE'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
