import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../models/driver_model.dart';
import '../widgets/star_rating.dart';
import '../widgets/vehicle_classification_dialog.dart';

class DriversDirectoryScreen extends StatelessWidget {
  const DriversDirectoryScreen({super.key});

  Color _getCategoryColor(String category) {
    if (category.contains('Premium') || category.contains('A -')) {
      return Colors.amber;
    } else if (category.contains('Básico') || category.contains('C -')) {
      return Colors.grey;
    }
    return AppTheme.primaryColor; // Tipo B - Estándar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Directorio de Conductores'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
            tooltip: 'Clasificación de Vehículos',
            onPressed: () => showVehicleClassificationDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .where('isApproved', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error al cargar datos', style: TextStyle(color: Colors.white)));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isDeleted'] != true;
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No hay conductores aprobados', style: TextStyle(color: Colors.white, fontSize: 18)));
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final driver = DriverModel.fromMap(docs[index].data() as Map<String, dynamic>);

              return Card(
                color: AppTheme.surfaceColor,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.driverReviews, arguments: driver);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: AppTheme.cardColor,
                          backgroundImage: driver.photoUrl != null ? NetworkImage(driver.photoUrl!) : null,
                          child: driver.photoUrl == null ? const Icon(Icons.person, color: AppTheme.primaryColor, size: 30) : null,
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver.name,
                                style: const TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(driver.vehicleCategory).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _getCategoryColor(driver.vehicleCategory).withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      driver.vehicleCategory,
                                      style: TextStyle(color: _getCategoryColor(driver.vehicleCategory), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${driver.age} años', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  StarRatingWidget(rating: driver.avgRating.round(), readOnly: true, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${driver.avgRating.toStringAsFixed(1)} (${driver.totalRatings})',
                                    style: const TextStyle(color: AppTheme.textWhite, fontSize: 12),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios, color: AppTheme.textGrey, size: 16),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
