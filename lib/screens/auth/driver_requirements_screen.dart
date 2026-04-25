import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';

class DriverRequirementsScreen extends StatelessWidget {
  const DriverRequirementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requisitos de Ingreso'),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Únete a Líneas Unidas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pasos previos para tu postulación oficial.',
                style: TextStyle(color: AppTheme.textGrey),
              ),
              const SizedBox(height: 24),

              // Aviso Informativo Principal
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Si deseas ser parte de esta prestigiosa organización debes ser socio activo de alguna de las líneas que la conforman... si no lo eres y deseas serlo puedes dirigirte a la oficina de "Líneas Unidas" ubicada en el terminal de pasajeros "Nuestra Señora del Pilar".',
                        style: TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Requisitos
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Qué necesito para ser conductor?',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem('🎂', 'Ser mayor de 21 años'),
                    _buildRequirementItem('🪪', 'Documento de identidad vigente'),
                    _buildRequirementItem('🩺', 'Certificado médico vigente'),
                    _buildRequirementItem('🚗', 'Certificado de circulación del vehículo'),
                    _buildRequirementItem('🚘', 'Licencia de conducir vigente'),
                    _buildRequirementItem('📄', 'RIF actualizado'),
                    const SizedBox(height: 12),
                    const Divider(color: AppTheme.cardColor),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Ten a la mano tus documentos para registrarte.',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Requisitos del Vehículo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Qué necesita mi vehículo?',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem('📅', 'Año 1995 en adelante'),
                    _buildRequirementItem('📋', 'Estar en las DT9 de la organización'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Botón Comencemos
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navegar al registro con el argumento 'driver'
                    Navigator.pushReplacementNamed(context, AppRoutes.register, arguments: 'driver');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('COMENCEMOS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
