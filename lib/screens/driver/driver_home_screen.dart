import 'dart:async';
import 'package:geolocator/geolocator.dart';
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
import '../../providers/currency_provider.dart';
import '../../models/ride_model.dart';
import '../../services/firestore_service.dart';
import '../widgets/panic_button_widget.dart';

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
      locationProvider.checkAndPromptGPSAndPermissions(context);
    }
  }

  Position? _lastRouteDriverPosition;

  void _loadRouteForRide(RideModel ride, Position? driverPos) async {
    if (driverPos == null) return;

    LatLng start;
    LatLng end;

    final isGoingToPickup = ride.status == RideStatus.requested ||
                            ride.status == RideStatus.accepted ||
                            ride.status == RideStatus.driverOnWay;

    if (isGoingToPickup) {
      start = LatLng(driverPos.latitude, driverPos.longitude);
      end = LatLng(ride.pickupLocation.latitude, ride.pickupLocation.longitude);
    } else if (ride.status == RideStatus.inProgress && ride.dropoffLocation != null) {
      start = LatLng(driverPos.latitude, driverPos.longitude);
      end = LatLng(ride.dropoffLocation!.latitude, ride.dropoffLocation!.longitude);
    } else {
      _clearRoute();
      return;
    }

    final distanceMoved = _lastRouteDriverPosition != null
        ? Geolocator.distanceBetween(
            _lastRouteDriverPosition!.latitude,
            _lastRouteDriverPosition!.longitude,
            driverPos.latitude,
            driverPos.longitude,
          )
        : double.infinity;

    if (_currentRideIdForRoute == ride.rideId && distanceMoved < 50) {
      return;
    }

    _currentRideIdForRoute = ride.rideId;
    _lastRouteDriverPosition = driverPos;

    final result = await RoutingService.getRoute(start, end);

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
    final driverProvider = Provider.of<DriverProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final driver = driverProvider.driver;

    if (driver == null && driverProvider.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await authProvider.signOut();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
        }
      });
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    if (driver != null && driver.isDeleted) {
      if (locationProvider.isTracking) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          locationProvider.stopTracking();
        });
      }
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.delete_forever,
                  size: 80,
                  color: AppTheme.errorRed,
                ),
                const SizedBox(height: 24),
                const Text(
                  'CUENTA ELIMINADA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tu cuenta de conductor ha sido eliminada por la administración.\n\nSi crees que esto es un error, comunícate con la oficina de Líneas Unidas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceColor,
                    foregroundColor: AppTheme.textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                    }
                  },
                  child: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (driver != null && driver.isSuspended) {
      if (locationProvider.isTracking) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          locationProvider.stopTracking();
        });
      }
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.block,
                  size: 80,
                  color: AppTheme.errorRed,
                ),
                const SizedBox(height: 24),
                const Text(
                  'CUENTA SUSPENDIDA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu cuenta de conductor ha sido suspendida temporalmente por la administración.\n\nMotivo de la suspensión:\n"${driver.suspensionReason ?? 'No especificado'}"\n\nComunícate con la oficina de Líneas Unidas para resolver tu situación.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceColor,
                    foregroundColor: AppTheme.textWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                    }
                  },
                  child: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (driver != null && driver.isApproved && driver.isAvailable && !locationProvider.isTracking) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final success = await locationProvider.startTracking(driver.uid);
        if (!success && context.mounted) {
          await driverProvider.toggleAvailability(driver.uid);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(locationProvider.error ?? 'Error de ubicación al autoiniciar.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
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
                      onChanged: (value) async {
                        final uid = authProvider.firebaseUser!.uid;
                        final locationProvider =
                            Provider.of<LocationProvider>(context,
                                listen: false);
                        if (value) {
                          final success = await locationProvider.startTracking(uid);
                          if (success) {
                            await driverProvider.toggleAvailability(uid);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(locationProvider.error ?? 'Error al activar ubicación'),
                                  backgroundColor: AppTheme.errorRed,
                                ),
                              );
                            }
                          }
                        } else {
                          locationProvider.stopTracking();
                          await driverProvider.toggleAvailability(uid);
                        }
                      },
                      activeThumbColor: AppTheme.successGreen,
                    ),
                  ],
                ),
              );
            },
          ),

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
                    _loadRouteForRide(activeRide, locationProvider.currentPosition);

                    // Asegurar que el proveedor del viaje escuche el viaje activo para recibir mensajes y notificaciones
                    final rideProvider = Provider.of<RideProvider>(context, listen: false);
                    if (rideProvider.currentRide?.rideId != activeRide.rideId) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        rideProvider.listenToRide(activeRide.rideId);
                      });
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.backgroundColor,
                      child: ActiveRideCard(ride: activeRide),
                    );
                  } else {
                    // Si no hay viaje activo, limpiar la escucha en el proveedor del viaje
                    final rideProvider = Provider.of<RideProvider>(context, listen: false);
                    if (rideProvider.currentRide != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        rideProvider.clearRide();
                      });
                    }
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
                      _loadRouteForRide(pendingRide, locationProvider.currentPosition);

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

          // Imagen del Equipo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/team_welcome.png.jpeg',
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
                          'Guarda tu imagen como\nassets/images/team_welcome.png.jpeg',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 300,
              child: Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  if (locationProvider.currentPosition == null) {
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
                  }

                  final uid = authProvider.firebaseUser!.uid;

                  return StreamBuilder<List<RideModel>>(
                    stream: _firestoreService.streamDriverActiveRides(uid),
                    builder: (context, activeSnapshot) {
                      final activeRides = activeSnapshot.data ?? [];

                      return StreamBuilder<List<RideModel>>(
                        stream: _firestoreService.streamPendingRideRequests(uid),
                        builder: (context, pendingSnapshot) {
                          final pendingRides = pendingSnapshot.data ?? [];

                          RideModel? currentRide;
                          if (activeRides.isNotEmpty) {
                            currentRide = activeRides.first;
                          } else if (pendingRides.isNotEmpty) {
                            currentRide = pendingRides.first;
                          }

                          final markers = <Marker>[
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
                          ];

                          if (currentRide != null) {
                            // Marcador de recogida
                            markers.add(
                              Marker(
                                point: LatLng(
                                  currentRide.pickupLocation.latitude,
                                  currentRide.pickupLocation.longitude,
                                ),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: AppTheme.successGreen,
                                  size: 36,
                                ),
                              ),
                            );

                            // Marcador de destino si está disponible
                            if (currentRide.dropoffLocation != null) {
                              markers.add(
                                Marker(
                                  point: LatLng(
                                    currentRide.dropoffLocation!.latitude,
                                    currentRide.dropoffLocation!.longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: AppTheme.errorRed,
                                    size: 36,
                                  ),
                                ),
                              );
                            }
                          }

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
                                if (_routePoints.isNotEmpty && currentRide != null)
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
                                  markers: markers,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        ),
      ),
      const Positioned(
        bottom: 20,
        right: 16,
        child: PanicButtonWidget(role: 'driver'),
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
              Expanded(
                child: Row(
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
                    const Expanded(
                      child: Text(
                        'Líneas Unidas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '¡Hola, ${authProvider.userModel?.name ?? 'Conductor'}! 🚕',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '¿Listo para tu próximo servicio? Enciende tu radar y comienza a generar ingresos hoy mismo.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textGrey,
                height: 1.4,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
              ),
              child: Consumer<CurrencyProvider>(
                builder: (context, currency, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'BCV',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currency.bcvRate > 0 
                          ? 'Bs. ${currency.bcvRate.toStringAsFixed(2)}' 
                          : '...',
                        style: const TextStyle(
                          color: AppTheme.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),
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
  int _timeLeft = 40;
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
                        value: _timeLeft / 40,
                        backgroundColor: AppTheme.backgroundColor,
                        color: _timeLeft <= 10 ? AppTheme.errorRed : AppTheme.primaryColor,
                        strokeWidth: 5,
                      ),
                    ),
                    Text(
                      '${_timeLeft}s',
                      style: TextStyle(
                        color: _timeLeft <= 10 ? AppTheme.errorRed : AppTheme.textWhite,
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
                      Consumer<CurrencyProvider>(
                        builder: (context, currency, _) {
                          final bsFare = currency.bcvRate > 0 ? (ride.fare! * currency.bcvRate).toStringAsFixed(2) : null;
                          return Row(
                            children: [
                              const Icon(Icons.payments, color: AppTheme.successGreen, size: 18),
                              const SizedBox(width: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${ride.fare!.toStringAsFixed(2)}',
                                    style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold),
                                  ),
                                  if (bsFare != null)
                                    Text(
                                      'Bs. $bsFare',
                                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
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

  Future<void> _confirmPayment(BuildContext context, String rideId) async {
    final firestoreService = FirestoreService();
    try {
      await firestoreService.updateRide(rideId, {
        'paymentStatus': 'confirmed',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago confirmado con éxito. El viaje ha finalizado.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar pago: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _rejectPayment(BuildContext context, String rideId) async {
    final firestoreService = FirestoreService();
    try {
      await firestoreService.updateRide(rideId, {
        'paymentStatus': 'rejected',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago rechazado. El cliente ha sido notificado.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar pago: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showCaptureDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Captura de Pago Móvil'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: AppTheme.primaryColor),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                            'Error al cargar la imagen.',
                            style: TextStyle(color: AppTheme.errorRed),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _cancelRide(BuildContext context, RideProvider rideProvider, String rideId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Cancelar Viaje', style: TextStyle(color: AppTheme.textWhite)),
          content: const Text(
            '¿Estás seguro de que deseas cancelar este viaje? Se le notificará al cliente.',
            style: TextStyle(color: AppTheme.textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('NO', style: TextStyle(color: AppTheme.textGrey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await rideProvider.cancelRide(rideId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El viaje ha sido cancelado.'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              },
              child: const Text(
                'SÍ, CANCELAR',
                style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final firestoreService = FirestoreService();
    
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
    } else if (ride.status == RideStatus.completed) {
      statusText = 'ESPERANDO PAGO';
      statusColor = Colors.amber;
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
                Icon(
                  ride.status == RideStatus.completed ? Icons.hourglass_bottom : Icons.directions_car, 
                  color: statusColor
                ),
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
            if (ride.status == RideStatus.completed && ride.driverName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Conductor asignado: ${ride.driverName}',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
              ),
            ],
            const SizedBox(height: 6),
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
            
            if (ride.status != RideStatus.completed) ...[
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
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: StreamBuilder<int>(
                stream: firestoreService.streamUnreadMessagesCount(
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
                    label: const Text('CHAT CON PASAJERO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.backgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  );
                },
              ),
            ),
            
            // Sección de Pago si está finalizado (completed)
            if (ride.status == RideStatus.completed) ...[
              const SizedBox(height: 16),
              const Divider(color: AppTheme.cardColor),
              const SizedBox(height: 12),
              
              if (ride.paymentStatus == 'pending') ...[
                if (ride.paymentMethod == 'cash') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.money, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'PAGO EN EFECTIVO',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'El cliente indica que te pagará en efectivo la cantidad de: \$${ride.fare?.toStringAsFixed(2)}.',
                          style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorRed,
                                  side: const BorderSide(color: AppTheme.errorRed),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () => _rejectPayment(context, ride.rideId),
                                child: const Text('RECHAZAR'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () => _confirmPayment(context, ride.rideId),
                                child: const Text('CONFIRMAR'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ] else if (ride.paymentMethod == 'pago_movil') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
                            SizedBox(width: 8),
                            Text(
                              'VERIFICAR PAGO MÓVIL',
                              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailText('Banco:', ride.paymentDetails?['banco'] ?? ''),
                        _buildDetailText('Referencia:', ride.paymentDetails?['referencia'] ?? ''),
                        _buildDetailText('Monto:', ride.paymentDetails?['monto'] ?? ''),
                        _buildDetailText('Fecha:', ride.paymentDetails?['fecha'] ?? ''),
                        const SizedBox(height: 12),
                        
                        // Botón para ver la captura
                        if (ride.paymentDetails?['imagenUrl'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                icon: const Icon(Icons.image),
                                label: const Text('VER CAPTURA DE PAGO'),
                                onPressed: () => _showCaptureDialog(context, ride.paymentDetails!['imagenUrl']),
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorRed,
                                  side: const BorderSide(color: AppTheme.errorRed),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () => _rejectPayment(context, ride.rideId),
                                child: const Text('RECHAZAR'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () => _confirmPayment(context, ride.rideId),
                                child: const Text('CONFIRMAR'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ]
              ] else if (ride.paymentStatus == 'rejected') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorRed),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rechazaste el pago. Esperando que el cliente envíe una nueva forma de pago.',
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_empty, color: Colors.amber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esperando que el cliente envíe el pago...',
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )
              ]
            ],
            
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
            if (ride.status == RideStatus.accepted || ride.status == RideStatus.driverOnWay) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelRide(context, rideProvider, ride.rideId),
                  icon: const Icon(Icons.close),
                  label: const Text('CANCELAR VIAJE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: const BorderSide(color: AppTheme.errorRed),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
