import 'package:flutter/material.dart';
import '../../config/theme.dart';

void showVehicleClassificationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 28),
            SizedBox(width: 12),
            Text(
              'Clasificación de Vehículos',
              style: TextStyle(
                color: AppTheme.textWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Conoce las categorías de vehículos autorizados en nuestra línea según sus características y comodidades:',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                
                // TIPO A
                _buildClassCard(
                  title: 'Tipo A - Premium',
                  color: Colors.amber,
                  icon: Icons.stars,
                  description: 'Vehículo en excelente estado y con todos los privilegios premium.',
                  features: [
                    'Aire acondicionado activo',
                    'Asientos con tapicería intacta',
                    'Condición mecánica excelente (sin fallas)',
                    'Impecable estado de limpieza',
                    'Recién pintado',
                    'Vidrios ahumados',
                    'Neumáticos en óptimo estado',
                  ],
                ),
                const SizedBox(height: 12),
                
                // TIPO B
                _buildClassCard(
                  title: 'Tipo B - Estándar',
                  color: AppTheme.primaryColor,
                  icon: Icons.directions_car,
                  description: 'Mantiene el excelente estado del Tipo A, pero sin climatización.',
                  features: [
                    'Asientos con tapicería intacta',
                    'Condición mecánica excelente (sin fallas)',
                    'Impecable estado de limpieza',
                    'Recién pintado',
                    'Vidrios ahumados',
                    'Neumáticos en óptimo estado',
                    'No cuenta con aire acondicionado',
                  ],
                  isSemiPremium: true,
                ),
                const SizedBox(height: 12),
                
                // TIPO C
                _buildClassCard(
                  title: 'Tipo C - Básico',
                  color: Colors.grey.shade400,
                  icon: Icons.build_circle_outlined,
                  description: 'Vehículo de transporte básico.',
                  features: [
                    'Servicio de traslado básico',
                    'No cuenta con aire acondicionado',
                    'No promete estar al día con una buena condición mecánica',
                  ],
                  isBasic: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildClassCard({
  required String title,
  required Color color,
  required IconData icon,
  required String description,
  required List<String> features,
  bool isSemiPremium = false,
  bool isBasic = false,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            color: AppTheme.textWhite,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 8),
        ...features.map((feature) {
          final isNegative = feature.startsWith('No ') || feature.contains('No promete') || feature.contains('Sin ');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isNegative ? Icons.remove_circle_outline : Icons.check_circle_outline,
                  color: isNegative 
                      ? (isBasic ? AppTheme.errorRed : Colors.orangeAccent) 
                      : AppTheme.successGreen,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      color: isNegative ? AppTheme.textGrey : AppTheme.textWhite.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}
