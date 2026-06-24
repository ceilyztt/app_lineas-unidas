import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../widgets/star_rating.dart';
import '../widgets/vehicle_classification_dialog.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);
    final driver = driverProvider.driver;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: AppTheme.primaryColor),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.editDriverProfile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con foto de portada y avatar
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: AppTheme.surfaceColor,
                ),
                Positioned(
                  bottom: -50,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.backgroundColor, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: AppTheme.cardColor,
                      backgroundImage: driver?.photoUrl != null
                          ? NetworkImage(driver!.photoUrl!)
                          : null,
                      child: driver?.photoUrl == null
                          ? const Icon(Icons.person, size: 50, color: AppTheme.primaryColor)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Nombre y Calificación
            Text(
              driver?.name ?? 'Conductor',
              style: const TextStyle(color: AppTheme.textWhite, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (driver != null && driver.totalRatings > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StarRatingWidget(rating: driver.avgRating.round(), readOnly: true, size: 24),
                  const SizedBox(width: 8),
                  Text('${driver.avgRating.toStringAsFixed(1)} (${driver.totalRatings})', style: const TextStyle(color: AppTheme.textGrey)),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              const Text('Sin calificaciones aún', style: TextStyle(color: AppTheme.textGrey)),
              const SizedBox(height: 16),
            ],

            // Etiqueta de Aprobación
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: driver?.isApproved == true ? AppTheme.successGreen.withValues(alpha: 0.15) : AppTheme.secondaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                driver?.isApproved == true ? '✓ Conductor Aprobado' : '⏳ Solicitud en Revisión',
                style: TextStyle(
                  color: driver?.isApproved == true ? AppTheme.successGreen : AppTheme.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Información Personal'),
                  _buildInfoTile(Icons.email_outlined, 'Correo', driver?.email ?? 'N/A'),
                  _buildInfoTile(Icons.phone_outlined, 'Teléfono', driver?.phone ?? 'N/A'),
                  _buildInfoTile(Icons.location_on_outlined, 'Dirección', driver?.address ?? 'N/A'),
                  Row(
                    children: [
                      Expanded(child: _buildInfoTile(Icons.cake_outlined, 'Edad', '${driver?.age ?? '?'} años')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoTile(Icons.work_outline, 'Experiencia', '${driver?.yearsOfExperience ?? '?'} años')),
                    ],
                  ),
                  _buildInfoTile(Icons.corporate_fare, 'Línea Adherida', driver?.affiliatedLine ?? 'N/A'),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Información del Vehículo'),
                  InkWell(
                    onTap: () => showVehicleClassificationDialog(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium_outlined, color: Colors.amber, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Clasificación del Vehículo',
                                  style: TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                ),
                                Text(
                                  driver?.vehicleCategory ?? 'N/A',
                                  style: const TextStyle(color: AppTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.help_outline, color: AppTheme.textGrey, size: 20),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: _buildInfoTile(Icons.directions_car_outlined, 'Marca', driver?.vehicleBrand ?? 'N/A')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoTile(Icons.info_outline, 'Modelo', driver?.vehicleModel ?? 'N/A')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _buildInfoTile(Icons.color_lens_outlined, 'Color', driver?.vehicleColor ?? 'N/A')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoTile(Icons.credit_card, 'Placa', driver?.vehiclePlate ?? 'N/A')),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Galería del Vehículo'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildVehicleImage(driver?.vehiclePhotoFrontUrl, 'Frontal'),
                        _buildVehicleImage(driver?.vehiclePhotoBackUrl, 'Trasera'),
                        _buildVehicleImage(driver?.vehiclePhotoInteriorUrl, 'Interior'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Datos de Pago Móvil'),
                  _buildInfoTile(Icons.account_balance, 'Banco', (driver?.bankName == null || driver!.bankName!.isEmpty) ? 'No configurado' : driver.bankName!),
                  _buildInfoTile(Icons.phone_android, 'Teléfono Pago Móvil', (driver?.bankPhone == null || driver!.bankPhone!.isEmpty) ? 'No configurado' : driver.bankPhone!),
                  _buildInfoTile(Icons.badge_outlined, 'Cédula / RIF', (driver?.bankDni == null || driver!.bankDni!.isEmpty) ? 'No configurado' : driver.bankDni!),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Opciones de Cuenta'),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet, color: AppTheme.successGreen),
                    title: const Text('Panel de Ganancias', style: TextStyle(color: AppTheme.textWhite)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: AppTheme.surfaceColor,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.driverEarnings),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.history, color: AppTheme.primaryColor),
                    title: const Text('Historial de viajes', style: TextStyle(color: AppTheme.textWhite)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: AppTheme.surfaceColor,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.rideHistory),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                    title: const Text('Cambiar Contraseña', style: TextStyle(color: AppTheme.textWhite)),
                    trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: AppTheme.surfaceColor,
                    onTap: () => _showChangePasswordDialog(context, authProvider),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Provider.of<DriverProvider>(context, listen: false).clearDriver();
                        await authProvider.signOut();
                        if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar Sesión'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Eliminar Cuenta
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDeleteAccountDialog(context, authProvider),
                      icon: const Icon(Icons.delete_forever, color: Colors.white),
                      label: const Text('Eliminar Cuenta Definitivamente', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.secondaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
                Text(
                  value,
                  style: const TextStyle(color: AppTheme.textWhite, fontSize: 15, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleImage(String? url, String label) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider auth) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        bool obscureCurrent = true;
        bool obscureNew = true;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              title: const Text('Cambiar Contraseña', style: TextStyle(color: AppTheme.textWhite)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: InputDecoration(
                        labelText: 'Contraseña Actual',
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, color: AppTheme.textGrey),
                          onPressed: () {
                            setState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, color: AppTheme.textGrey),
                          onPressed: () {
                            setState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                      validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: AppTheme.textGrey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );

                    final success = await auth.changePassword(
                      currentPasswordController.text,
                      newPasswordController.text,
                    );
                    
                    if (!context.mounted) return;
                    Navigator.pop(context); // cerrar progress

                    if (success) {
                      Navigator.pop(context); // cerrar dialog form
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contraseña actualizada con éxito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: AppTheme.successGreen),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(auth.error ?? 'Error de actualización', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: AppTheme.errorRed),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthProvider auth) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Eliminar Cuenta', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¡ADVERTENCIA! Esta acción es irreversible. Perderás todos tus datos, el registro de tu vehículo y tu historial de viajes.',
                  style: TextStyle(color: AppTheme.textWhite),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Por seguridad, ingresa tu contraseña para confirmar:',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                final success = await auth.deleteAccount(passwordController.text);
                
                if (!context.mounted) return;
                Navigator.pop(context); // cerrar progress

                if (success) {
                  Navigator.pop(context); // cerrar dialog form
                  Provider.of<DriverProvider>(context, listen: false).clearDriver();
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cuenta eliminada permanentemente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: AppTheme.successGreen),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(auth.error ?? 'Error de actualización', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: AppTheme.errorRed),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              child: const Text('Eliminar Definitivamente'),
            ),
          ],
        );
      },
    );
  }
}
