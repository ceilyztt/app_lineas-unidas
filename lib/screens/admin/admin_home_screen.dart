import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/sos_alert_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _showActiveDrivers = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Column(
            children: [
              _buildAdminHeader(context),
              
              // Selector de pestañas premium
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_showActiveDrivers
                              ? AppTheme.primaryColor
                              : AppTheme.surfaceColor,
                          foregroundColor: !_showActiveDrivers
                              ? AppTheme.backgroundColor
                              : AppTheme.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: !_showActiveDrivers
                                  ? AppTheme.primaryColor
                                  : AppTheme.cardColor,
                            ),
                          ),
                        ),
                        onPressed: () {
                          setState(() => _showActiveDrivers = false);
                        },
                        child: const Text(
                          'Solicitudes',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showActiveDrivers
                              ? AppTheme.primaryColor
                              : AppTheme.surfaceColor,
                          foregroundColor: _showActiveDrivers
                              ? AppTheme.backgroundColor
                              : AppTheme.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _showActiveDrivers
                                  ? AppTheme.primaryColor
                                  : AppTheme.cardColor,
                            ),
                          ),
                        ),
                        onPressed: () {
                          setState(() => _showActiveDrivers = true);
                        },
                        child: const Text(
                          'Activos',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: !_showActiveDrivers
                    ? _buildPendingRequestsView()
                    : _buildActiveDriversView(),
              ),
            ],
          ),
        ),
        
        // Capa Superior: Escucha de Alertas de Emergencia (SOS)
        StreamBuilder<List<SosAlertModel>>(
          stream: FirestoreService().streamActiveSosAlerts(),
          builder: (context, snapshot) {
            final activeAlerts = snapshot.data ?? [];
            if (activeAlerts.isEmpty) return const SizedBox.shrink();

            final alert = activeAlerts.first;

            return Material(
              color: Colors.red.withOpacity(0.95),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_rounded, color: Colors.white, size: 100),
                        const SizedBox(height: 16),
                        const Text(
                          '¡EMERGENCIA SOS!',
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Text('Usuario en Peligro: ${alert.userName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                              Text('Teléfono: ${alert.userPhone}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                              Text('Rol: ${alert.role == "driver" ? "Conductor" : "Pasajero"}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    icon: const Icon(Icons.call, color: Colors.white),
                                    label: const Text('Llamar', style: TextStyle(color: Colors.white)),
                                    onPressed: () => launchUrl(Uri.parse("tel://${alert.userPhone}")),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    icon: const Icon(Icons.map, color: Colors.white),
                                    label: const Text('Ver Mapa', style: TextStyle(color: Colors.white)),
                                    onPressed: () {
                                      final url = 'https://www.google.com/maps/search/?api=1&query=${alert.location.latitude},${alert.location.longitude}';
                                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                            onPressed: () => FirestoreService().resolveSosAlert(alert.alertId),
                            child: const Text('MARCAR COMO RESUELTA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPendingRequestsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .where('isApproved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error al cargar datos', style: TextStyle(color: Colors.white)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isRejected'] != true;
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('No hay solicitudes pendientes', style: TextStyle(color: Colors.white, fontSize: 18)));
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            return Card(
              color: AppTheme.surfaceColor,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(data['name'] ?? 'Sin nombre', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Vehículo: ${data['vehicleBrand']} ${data['vehicleModel']}\nPlaca: ${data['vehiclePlate']}\nExperiencia: ${data['yearsOfExperience']} años', style: const TextStyle(color: AppTheme.textGrey, height: 1.4)),
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.remove_red_eye, color: AppTheme.primaryColor),
                          onPressed: () => _mostrarExpedienteAspirante(context, data, docId),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: AppTheme.errorRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: AppTheme.errorRed),
                          onPressed: () => _rechazarConductor(context, docId),
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
    );
  }

  Widget _buildActiveDriversView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .where('isApproved', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error al cargar datos', style: TextStyle(color: Colors.white)));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No hay conductores activos', style: TextStyle(color: Colors.white, fontSize: 18)));
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            
            final isSuspended = data['isSuspended'] ?? false;
            final String name = data['name'] ?? 'Sin nombre';
            final String vehicleInfo = '${data['vehicleBrand'] ?? ''} ${data['vehicleModel'] ?? ''}'.trim();
            final String plate = data['vehiclePlate'] ?? '';
            final String category = data['vehicleCategory'] ?? 'Tipo B - Estándar';
            final double rating = (data['avgRating'] ?? 0.0).toDouble();

            return Card(
              color: AppTheme.surfaceColor,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSuspended ? AppTheme.errorRed.withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSuspended
                              ? AppTheme.errorRed.withValues(alpha: 0.15)
                              : AppTheme.successGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isSuspended ? 'SUSPENDIDO' : 'ACTIVO',
                          style: TextStyle(
                            color: isSuspended ? AppTheme.errorRed : AppTheme.successGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehículo: $vehicleInfo\nPlaca: $plate\nCategoría: $category',
                          style: const TextStyle(color: AppTheme.textGrey, height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        if (isSuspended && data['suspensionReason'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Motivo suspensión: "${data['suspensionReason']}"',
                              style: const TextStyle(color: AppTheme.errorRed, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  isThreeLine: true,
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: isSuspended 
                          ? AppTheme.successGreen.withValues(alpha: 0.1) 
                          : AppTheme.errorRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isSuspended ? Icons.check_circle_outline : Icons.block,
                        color: isSuspended ? AppTheme.successGreen : AppTheme.errorRed,
                      ),
                      onPressed: () {
                        if (isSuspended) {
                          _reactivarConductor(context, docId);
                        } else {
                          _suspenderConductor(context, docId);
                        }
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 40,
                  width: 40,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.people_alt, color: AppTheme.primaryColor),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.directory),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: AppTheme.errorRed),
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Central de Mando',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Líneas Unidas - Administración',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hola, administrador. Revisa y gestiona las solicitudes de los nuevos conductores para mantener la flota completamente operativa y segura.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarExpedienteAspirante(BuildContext context, Map<String, dynamic> data, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('REVISIÓN DE ASPIRANTE', 
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSeccionTitulo("IDENTIFICACIÓN"),
                _buildDatoFila(Icons.person, "Nombre", data['name']),
                _buildDatoFila(Icons.phone, "Teléfono", data['phone']),
                _buildDatoFila(Icons.cake, "Edad", "${data['age']} años"),
                _buildDatoFila(Icons.work_history, "Experiencia", "${data['yearsOfExperience']} años"),
                const Divider(color: AppTheme.cardColor),

                _buildSeccionTitulo("VEHÍCULO"),
                _buildDatoFila(Icons.directions_car, "Marca/Modelo", "${data['vehicleBrand']} ${data['vehicleModel']}"),
                _buildDatoFila(Icons.numbers, "Placa", data['vehiclePlate']),
                _buildDatoFila(Icons.color_lens, "Color", data['vehicleColor']),
                const Divider(color: AppTheme.cardColor),

                _buildSeccionTitulo("GALERÍA DE ESTADO"),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFotoCard(context, "Frontal", data['vehiclePhotoFrontUrl']),
                      _buildFotoCard(context, "Trasera", data['vehiclePhotoBackUrl']),
                      _buildFotoCard(context, "Interior", data['vehiclePhotoInteriorUrl']),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.cardColor),

                _buildSeccionTitulo("CONFORT Y CALIDAD"),
                _buildDatoFila(Icons.ac_unit, "Aire Acond.", data['hasAirConditioning'] == true ? "SÍ" : "NO"),
                _buildDatoFila(Icons.cleaning_services, "Limpieza", data['cleanlinessLevel']),
                _buildDatoFila(Icons.tire_repair, "Cauchos Buenos", data['hasGoodTires'] == true ? "SÍ" : "NO"),
                _buildDatoFila(Icons.build, "Mecánica", data['mechanicalCondition']),
                _buildDatoFila(Icons.chair, "Tapicería", data['seatingMaterial']),
                
                const SizedBox(height: 20),
                const Text("DEFINIR CATEGORÍA FINAL:", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _botonAsignar(context, "Tipo A - Premium", Colors.amber.shade700, docId, "Tipo A"),
              _botonAsignar(context, "Tipo B - Estándar", AppTheme.primaryColor, docId, "Tipo B"),
              _botonAsignar(context, "Tipo C - Básico", Colors.grey, docId, "Tipo C"),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar", style: TextStyle(color: AppTheme.errorRed)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(titulo, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
    );
  }

  Widget _buildDatoFila(IconData icono, String etiqueta, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icono, size: 16, color: AppTheme.textGrey),
          const SizedBox(width: 8),
          Text("$etiqueta:", style: const TextStyle(fontSize: 13, color: AppTheme.textWhite)),
          const Spacer(),
          Text(valor?.toString() ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
        ],
      ),
    );
  }

  Widget _buildFotoCard(BuildContext context, String titulo, String? url) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Text(titulo, style: const TextStyle(fontSize: 10, color: AppTheme.textWhite)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              if (url != null && url.isNotEmpty) {
                _mostrarImagenGrande(context, url);
              }
            },
            child: Container(
              width: 130, height: 90,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: (url != null && url.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url, fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor));
                        },
                        errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, color: AppTheme.errorRed),
                      ),
                    )
                  : const Icon(Icons.no_photography, color: AppTheme.textGrey),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarImagenGrande(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonAsignar(BuildContext context, String cat, Color color, String docId, String buttonText) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      onPressed: () async {
        await FirebaseFirestore.instance.collection('drivers').doc(docId).update({
          'isApproved': true,
          'isRejected': false, // Limpiar rechazos pasados al aprobar
          'vehicleCategory': cat,
        });

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Conductor aprobado como $cat", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
        }
      },
      child: Text(buttonText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _rechazarConductor(BuildContext context, String docId) async {
    final TextEditingController reasonController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Rechazar Solicitud',
            style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Escribe el motivo por el cual estás negando la solicitud del conductor:',
                style: TextStyle(color: AppTheme.textWhite, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: 'Ej. Documentación vencida, fotos borrosas, etc.',
                  hintStyle: const TextStyle(color: AppTheme.textGrey),
                  fillColor: AppTheme.surfaceColor,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor escribe un motivo.'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('drivers').doc(docId).update({
                  'isRejected': true,
                  'rejectionReason': reason,
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitud negada con éxito.', style: TextStyle(color: Colors.white)),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              },
              child: const Text('NEGAR SOLICITUD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _suspenderConductor(BuildContext context, String docId) async {
    final TextEditingController reasonController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Suspender Conductor',
            style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Escribe el motivo por el cual estás suspendiendo a este conductor:',
                style: TextStyle(color: AppTheme.textWhite, fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: 'Ej. Reporte de mala conducta, tarifa excesiva, etc.',
                  hintStyle: const TextStyle(color: AppTheme.textGrey),
                  fillColor: AppTheme.surfaceColor,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR', style: TextStyle(color: AppTheme.textGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor escribe un motivo.'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('drivers').doc(docId).update({
                  'isSuspended': true,
                  'suspensionReason': reason,
                  'isAvailable': false, // Forzar no disponible al suspender
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conductor suspendido con éxito.', style: TextStyle(color: Colors.white)),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              },
              child: const Text('SUSPENDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reactivarConductor(BuildContext context, String docId) async {
    await FirebaseFirestore.instance.collection('drivers').doc(docId).update({
      'isSuspended': false,
      'suspensionReason': null,
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conductor reactivado con éxito.', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }
}