import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../models/ride_model.dart';
import '../../services/firestore_service.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<RideModel> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.firebaseUser!.uid;
    final role = authProvider.userRole ?? 'client';

    final rides = await _firestoreService.getRideHistory(uid, role);
    setState(() {
      _rides = rides;
      _isLoading = false;
    });
  }

  String _getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return 'Completado';
      case RideStatus.cancelled:
        return 'Cancelado';
      default:
        return status.name;
    }
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return AppTheme.successGreen;
      case RideStatus.cancelled:
        return AppTheme.errorRed;
      default:
        return AppTheme.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Viajes'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : _rides.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: AppTheme.textGrey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes viajes registrados',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rides.length,
                    itemBuilder: (context, index) {
                      final ride = _rides[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fecha y estado
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm')
                                        .format(ride.createdAt),
                                    style: const TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(ride.status)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(ride.status),
                                      style: TextStyle(
                                        color: _getStatusColor(ride.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Ubicación
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: AppTheme.primaryColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      ride.pickupAddress,
                                      style: const TextStyle(
                                        color: AppTheme.textWhite,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (ride.driverName != null ||
                                  ride.fare != null) ...[
                                const Divider(
                                  color: AppTheme.cardColor,
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (ride.driverName != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            color: AppTheme.textGrey,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            ride.driverName!,
                                            style: const TextStyle(
                                              color: AppTheme.textGrey,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (ride.fare != null)
                                      Text(
                                        '\$${ride.fare!.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                  ],
                                ),
                                if (ride.distance != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${ride.distance!.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        color: AppTheme.textGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
