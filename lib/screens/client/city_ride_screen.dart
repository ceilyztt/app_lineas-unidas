import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/routing_service.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/currency_provider.dart';

class CityRideScreen extends StatefulWidget {
  const CityRideScreen({super.key});

  @override
  State<CityRideScreen> createState() => _CityRideScreenState();
}

class _CityRideScreenState extends State<CityRideScreen> {
  final MapController _mapController = MapController();
  String _currentAddress = 'Obteniendo ubicación...';
  
  bool _isMapSelectionMode = false;
  bool _isFullScreenMap = false;
  LatLng? _destinationPoint;
  String? _destinationAddress;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  double? _estimatedFare;
  double? _distanceKm;
  bool _isNightFare = false;
  List<PlaceSearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  Future<void> _initLocation() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.getCurrentLocation();

    if (locationProvider.currentPosition != null) {
      _getAddressFromLatLng(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    final address = await RoutingService.getAddressFromLatLng(lat, lng);
    if (mounted) {
      setState(() {
        _currentAddress = address;
      });
    }
  }

  Future<void> _loadRouteToDestination() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final start = locationProvider.currentPosition;
    if (start != null && _destinationPoint != null) {
      setState(() => _isLoadingRoute = true);
      final result = await RoutingService.getRoute(
        LatLng(start.latitude, start.longitude),
        _destinationPoint!,
      );
      if (mounted) {
        setState(() {
          if (result != null) {
            _routePoints = result.points;
            _distanceKm = result.distanceKm;
            // Cálculo de tarifa compuesta
            double baseFare = 1.0; // Bajada de bandera
            double pricePerKm = 0.50;
            double nightSurcharge = 0.0;
            
            // Recargo nocturno (9 PM a 5 AM)
            final now = DateTime.now();
            if (now.hour >= 21 || now.hour < 5) {
              nightSurcharge = 1.0;
              _isNightFare = true;
            } else {
              _isNightFare = false;
            }
            
            double totalFare = baseFare + (_distanceKm! * pricePerKm) + nightSurcharge;
            _estimatedFare = double.parse(totalFare.toStringAsFixed(2));
          } else {
            _routePoints = [];
            _distanceKm = null;
            _estimatedFare = null;
            _isNightFare = false;
          }
          _isLoadingRoute = false;
        });
      }
    }
  }

  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: InputDecoration(
                      hintText: 'Buscar destino...',
                      hintStyle: const TextStyle(color: AppTheme.textGrey),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) async {
                      if (value.length > 2) {
                        final results = await RoutingService.searchPlaces(value);
                        setSheetState(() {
                          _searchResults = results;
                        });
                      } else {
                        setSheetState(() {
                          _searchResults = [];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.map, color: AppTheme.primaryColor),
                    title: const Text('Seleccionar en el mapa', style: TextStyle(color: AppTheme.primaryColor)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _isMapSelectionMode = true;
                      });
                    },
                  ),
                  const Divider(color: AppTheme.cardColor),
                  if (_searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Escribe para buscar...', style: TextStyle(color: AppTheme.textGrey)),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: AppTheme.textGrey),
                            title: Text(
                              place.displayName,
                              style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              setState(() {
                                _destinationPoint = LatLng(place.lat, place.lon);
                                _destinationAddress = place.displayName;
                                _isMapSelectionMode = false;
                              });
                              _loadRouteToDestination();
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _requestRide() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (locationProvider.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener tu ubicación'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final success = await rideProvider.requestRide(
      clientId: authProvider.firebaseUser!.uid,
      clientName: authProvider.userModel?.name ?? 'Cliente',
      pickupPosition: locationProvider.currentPosition!,
      pickupAddress: _currentAddress,
      dropoffPosition: _destinationPoint,
      dropoffAddress: _destinationAddress,
      distance: _distanceKm,
      fare: _estimatedFare,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.rideInProgress);
    } else if (mounted && rideProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rideProvider.error!),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreenMap
          ? null
          : AppBar(
              title: const Text(
                'Regresar al inicio',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: AppTheme.textWhite,
                ),
              ),
              backgroundColor: AppTheme.backgroundColor,
              foregroundColor: AppTheme.textWhite,
              elevation: 0,
            ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, _) {
          return Stack(
            children: [
              // 1. EL MAPA (ocupa todo el fondo siempre)
              if (locationProvider.currentPosition != null)
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        locationProvider.currentPosition!.latitude,
                        locationProvider.currentPosition!.longitude,
                      ),
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) {
                        if (!_isMapSelectionMode) {
                          setState(() {
                            _isFullScreenMap = !_isFullScreenMap;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.lineasunidas.app',
                      ),
                      if (_routePoints.isNotEmpty && !_isMapSelectionMode)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 4.0,
                              color: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      if (!_isMapSelectionMode)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                locationProvider.currentPosition!.latitude,
                                locationProvider.currentPosition!.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: AppTheme.primaryColor,
                                size: 40,
                              ),
                            ),
                            if (_destinationPoint != null)
                              Marker(
                                point: _destinationPoint!,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppTheme.errorRed,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                )
              else
                const Center(
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
                ),

              // 2. MODO SELECCIÓN DE MAPA (Pin central)
              if (_isMapSelectionMode)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(
                      Icons.location_on,
                      color: AppTheme.errorRed,
                      size: 40,
                    ),
                  ),
                ),

              // 3. TARJETA SUPERIOR ("¿Necesitas un taxi?")
              if (!_isFullScreenMap && !_isMapSelectionMode)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_taxi,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '¿Necesitas un taxi?',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Contamos con conductores profesionales preparados para moverte por toda Barinas.',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),

              // 4. MODO MAPA COMPLETO (Indicador)
              if (_isFullScreenMap)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Toca el mapa para salir',
                        style: TextStyle(color: AppTheme.textWhite, fontSize: 12),
                      ),
                    ),
                  ),
                ),

              // 5. BOTÓN FLOTANTE CENTRAR MAPA
              if (!_isFullScreenMap)
                Positioned(
                  right: 16,
                  bottom: MediaQuery.of(context).size.height * 0.45 + 16,
                  child: FloatingActionButton(
                    heroTag: 'city_ride_center_map',
                    backgroundColor: AppTheme.primaryColor,
                    onPressed: () {
                      if (locationProvider.currentPosition != null) {
                        _mapController.move(
                          LatLng(
                            locationProvider.currentPosition!.latitude,
                            locationProvider.currentPosition!.longitude,
                          ),
                          15.0,
                        );
                      }
                    },
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),

              // 6. TARJETA INFERIOR (DraggableScrollableSheet)
              if (!_isFullScreenMap)
                DraggableScrollableSheet(
                  initialChildSize: _isMapSelectionMode ? 0.35 : 0.45,
                  minChildSize: 0.15,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
                    return Container(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                      child: SafeArea(
                        top: false,
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Indicador de arrastre (Pill)
                              Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.textGrey.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              _isMapSelectionMode
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Mueve el mapa para seleccionar tu destino',
                                          style: TextStyle(color: AppTheme.textWhite, fontSize: 16),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final center = _mapController.camera.center;
                                              final address = await RoutingService.getAddressFromLatLng(
                                                  center.latitude, center.longitude);
                                              setState(() {
                                                _destinationPoint = center;
                                                _destinationAddress = address;
                                                _isMapSelectionMode = false;
                                              });
                                              _loadRouteToDestination();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                            ),
                                            child: const Text('CONFIRMAR DESTINO', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '¿A dónde vamos?',
                                          style: TextStyle(
                                            color: AppTheme.textWhite,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceColor,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.my_location,
                                                color: AppTheme.successGreen,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _currentAddress,
                                                  style: const TextStyle(
                                                    color: AppTheme.textWhite,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: _openSearchSheet,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceColor,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppTheme.cardColor),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  color: AppTheme.errorRed,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    _destinationAddress ?? 'Buscar destino...',
                                                    style: TextStyle(
                                                      color: _destinationAddress != null
                                                          ? AppTheme.textWhite
                                                          : AppTheme.textGrey,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (_estimatedFare != null) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Distancia',
                                                      style: TextStyle(
                                                        color: AppTheme.textGrey,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${_distanceKm!.toStringAsFixed(1)} km',
                                                      style: const TextStyle(
                                                        color: AppTheme.textWhite,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    const Text(
                                                      'Precio estimado',
                                                      style: TextStyle(
                                                        color: AppTheme.primaryColor,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Consumer<CurrencyProvider>(
                                                      builder: (context, currency, _) {
                                                        final bsFare = currency.bcvRate > 0 ? (_estimatedFare! * currency.bcvRate).toStringAsFixed(2) : null;
                                                        return Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          children: [
                                                            Text(
                                                              '\$${_estimatedFare!.toStringAsFixed(2)}',
                                                              style: const TextStyle(
                                                                color: AppTheme.primaryColor,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                            if (bsFare != null)
                                                              Text(
                                                                'Bs. $bsFare',
                                                                style: const TextStyle(
                                                                  color: AppTheme.textGrey,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_isNightFare)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.nightlight_round, color: AppTheme.primaryColor, size: 14),
                                                  const SizedBox(width: 6),
                                                  const Expanded(
                                                    child: Text(
                                                      'Incluye recargo de \$1.00 por horario nocturno.',
                                                      style: TextStyle(color: AppTheme.primaryColor, fontSize: 12),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                        const SizedBox(height: 16),
                                        Consumer<RideProvider>(
                                          builder: (context, rideProvider, _) {
                                            final bool isReadyToRequest = _distanceKm != null && _estimatedFare != null;
                                            
                                            return SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: (rideProvider.isLoading || !isReadyToRequest) 
                                                    ? null 
                                                    : _requestRide,
                                                icon: rideProvider.isLoading
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: AppTheme.backgroundColor,
                                                        ),
                                                      )
                                                    : const Icon(Icons.directions_car, size: 24),
                                                label: Text(
                                                  rideProvider.isLoading ? 'BUSCANDO...' : 'SOLICITAR TAXI',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  backgroundColor: isReadyToRequest ? AppTheme.primaryColor : AppTheme.cardColor,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
