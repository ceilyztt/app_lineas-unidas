import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:provider/provider.dart';
import '../../providers/currency_provider.dart';

class RideInfoCard extends StatelessWidget {
  final String driverName;
  final String vehicleModel;
  final String vehiclePlate;
  final double? rating;
  final String status;
  final String? pickupAddress;
  final double? fare;

  const RideInfoCard({
    super.key,
    required this.driverName,
    required this.vehicleModel,
    required this.vehiclePlate,
    this.rating,
    required this.status,
    this.pickupAddress,
    this.fare,
  });

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Aceptado';
      case 'driverOnWay':
        return 'Conductor en camino';
      case 'inProgress':
        return 'En viaje';
      case 'completed':
        return 'Finalizado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Buscando conductor...';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppTheme.primaryColor;
      case 'driverOnWay':
        return Colors.orange;
      case 'inProgress':
        return AppTheme.successGreen;
      case 'completed':
        return AppTheme.accentBlue;
      case 'cancelled':
        return AppTheme.errorRed;
      default:
        return AppTheme.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado del viaje
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(status),
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Info del conductor
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.backgroundColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      Text(
                        '$vehicleModel • $vehiclePlate',
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (pickupAddress != null) ...[
              const Divider(color: AppTheme.cardColor, height: 24),
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
                      pickupAddress!,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (fare != null) ...[
              const Divider(color: AppTheme.cardColor, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tarifa',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                    ),
                  ),
                  Consumer<CurrencyProvider>(
                    builder: (context, currency, _) {
                      final bsFare = currency.bcvRate > 0 ? (fare! * currency.bcvRate).toStringAsFixed(2) : null;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${fare!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }
}
