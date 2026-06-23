import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../models/driver_model.dart';
import '../widgets/star_rating.dart';

class DriverReviewsScreen extends StatelessWidget {
  const DriverReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = ModalRoute.of(context)!.settings.arguments as DriverModel;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Perfil del Conductor'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildDriverOverview(driver),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
              child: Text('Comentarios de Pasajeros', style: TextStyle(color: AppTheme.primaryColor, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ratings')
                .where('driverId', isEqualTo: driver.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const SliverToBoxAdapter(child: Center(child: Text('Error al cargar reseñas', style: TextStyle(color: Colors.white))));
              if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));

              final rawDocs = snapshot.data!.docs;

              if (rawDocs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('Este conductor aún no tiene reseñas. ¡Sé el primero en viajar con él!', style: TextStyle(color: AppTheme.textGrey, fontSize: 16), textAlign: TextAlign.center),
                  ),
                );
              }

              // Ordenar localmente por fecha para evadir la necesidad de un Índice Compuesto en Firebase
              final docs = rawDocs.toList();
              docs.sort((a, b) {
                final dateA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final dateB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                if (dateA == null || dateB == null) return 0;
                return dateB.compareTo(dateA); // Orden descendente (más reciente primero)
              });

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildReviewTile(data);
                  },
                  childCount: docs.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverOverview(DriverModel driver) {
    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.cardColor,
            backgroundImage: driver.photoUrl != null ? NetworkImage(driver.photoUrl!) : null,
            child: driver.photoUrl == null ? const Icon(Icons.person, color: AppTheme.primaryColor, size: 40) : null,
          ),
          const SizedBox(height: 16),
          Text(driver.name, style: const TextStyle(color: AppTheme.textWhite, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(driver.vehicleCategory, style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatColumn('EDAD', '${driver.age}'),
              _buildDivider(),
              _buildStatColumn('EXPERIENCIA', '${driver.yearsOfExperience} a.'),
              _buildDivider(),
              _buildStatColumn('PUNTUACIÓN', '${driver.avgRating.toStringAsFixed(1)} ★'),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('VEHÍCULO', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${driver.vehicleBrand} ${driver.vehicleModel}', style: const TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Color: ${driver.vehicleColor} • Placa: ${driver.vehiclePlate}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 30, width: 1, color: AppTheme.cardColor);
  }

  Widget _buildReviewTile(Map<String, dynamic> data) {
    final rating = (data['rating'] as num?)?.toInt() ?? 0;
    final comment = data['comment'] as String? ?? '';
    final date = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StarRatingWidget(rating: rating, readOnly: true, size: 16),
              Text(
                '${date.day}/${date.month}/${date.year}',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '"$comment"',
              style: const TextStyle(color: AppTheme.textWhite, fontStyle: FontStyle.italic, height: 1.4),
            ),
          ]
        ],
      ),
    );
  }
}
