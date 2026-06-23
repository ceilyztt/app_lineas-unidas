import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../models/rating_model.dart';
import '../../services/firestore_service.dart';
import '../widgets/star_rating.dart';

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    final firestoreService = FirestoreService();

    final ride = rideProvider.currentRide;
    if (ride == null || ride.driverId == null) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.clientHome, (r) => false);
      return;
    }

    final ratingId =
        FirebaseFirestore.instance.collection('ratings').doc().id;

    final rating = RatingModel(
      ratingId: ratingId,
      rideId: ride.rideId,
      driverId: ride.driverId!,
      clientId: authProvider.firebaseUser!.uid,
      clientName: authProvider.userModel?.name ?? 'Cliente',
      stars: _rating,
      comment: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
      createdAt: DateTime.now(),
    );

    try {
      await firestoreService.createRating(rating);
      rideProvider.clearRide();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Gracias por tu calificación!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.clientHome, (r) => false);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hubo un error al guardar la calificación. Intenta de nuevo.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideProvider = Provider.of<RideProvider>(context);
    final ride = rideProvider.currentRide;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Ícono de check
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.successGreen.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: AppTheme.successGreen,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                '¡Viaje Finalizado!',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              if (ride?.fare != null)
                Text(
                  'Total: \$${ride!.fare!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              if (ride?.distance != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Distancia: ${ride!.distance!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 14,
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Califica al conductor
              const Text(
                '¿Cómo fue tu experiencia?',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              if (ride?.driverName != null)
                Text(
                  'Conductor: ${ride!.driverName}',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                  ),
                ),

              const SizedBox(height: 20),

              // Estrellas
              StarRatingWidget(
                rating: _rating,
                onRatingChanged: (value) {
                  setState(() => _rating = value);
                },
                size: 48,
              ),

              const SizedBox(height: 8),
              Text(
                _getRatingLabel(_rating),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // Comentario
              TextField(
                controller: _commentController,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(
                  hintText: 'Deja un comentario (opcional)',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 32),

              // Botón enviar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitRating,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.backgroundColor,
                          ),
                        )
                      : const Icon(Icons.star),
                  label: Text(
                    _isSubmitting ? 'ENVIANDO...' : 'ENVIAR CALIFICACIÓN',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Omitir
              TextButton(
                onPressed: () {
                  rideProvider.clearRide();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.clientHome,
                    (r) => false,
                  );},
                child: const Text(
                  'Omitir',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}
