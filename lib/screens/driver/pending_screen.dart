import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';

class DriverPendingScreen extends StatelessWidget {
  const DriverPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Sesión no iniciada")));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor, 
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error de conexión', style: TextStyle(color: Colors.white)));
          
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final isApproved = data?['isApproved'] ?? false;
            final isRejected = data?['isRejected'] ?? false;

            if (isApproved == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.splash, (r) => false);
              });
            }

            if (isRejected == true) {
              final reason = data?['rejectionReason'] as String?;
              return _buildRejectedUI(context, reason);
            }

            return _buildWaitingUI(context);
          } else if (snapshot.hasData && !snapshot.data!.exists) {
            return _buildRejectedUI(context, null);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildWaitingUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.access_time_filled, size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 24),
            const Text(
              'SOLICITUD EN REVISIÓN', 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'El equipo de administración de Líneas Unidas está verificando tu documentación e información vehicular. Te avisaremos por este medio cuando estés aprobado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false).signOut();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
              },
              child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedUI(BuildContext context, String? reason) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, size: 80, color: AppTheme.errorRed),
            const SizedBox(height: 24),
            const Text(
              'SOLICITUD NEGADA', 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              reason != null && reason.isNotEmpty
                  ? 'Tu solicitud de registro como conductor ha sido rechazada por el siguiente motivo:\n\n"$reason"'
                  : 'Tu solicitud no ha sido aprobada tras la revisión. Contacta con la oficina central para más información.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false).signOut();
                if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}