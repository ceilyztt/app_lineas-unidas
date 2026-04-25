import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../widgets/custom_button.dart';

class EditDriverProfileScreen extends StatefulWidget {
  const EditDriverProfileScreen({super.key});

  @override
  State<EditDriverProfileScreen> createState() => _EditDriverProfileScreenState();
}

class _EditDriverProfileScreenState extends State<EditDriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _ageController;
  late TextEditingController _expController;
  late TextEditingController _plateController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _colorController;
  late TextEditingController _lineController;
  late String _assignedCategory;

  // Cuestionario
  late bool _hasAirConditioning;
  late bool _hasGoodTires;
  late String _mechanicalCondition;
  final List<String> _mechOptions = ['Sin fallas', 'Fallas menores', 'Requiere reparación'];
  late String _cleanlinessLevel;
  final List<String> _cleanOptions = ['Impecable', 'Promedio', 'Regular'];
  late String _seatingMaterial;
  final List<String> _seatOptions = ['Tela', 'Cuero', 'Otro'];

  @override
  void initState() {
    super.initState();
    final driver = Provider.of<AuthProvider>(context, listen: false).driverModel;
    _nameController = TextEditingController(text: driver?.name);
    _phoneController = TextEditingController(text: driver?.phone);
    _addressController = TextEditingController(text: driver?.address);
    _ageController = TextEditingController(text: driver?.age.toString());
    _expController = TextEditingController(text: driver?.yearsOfExperience.toString());
    _plateController = TextEditingController(text: driver?.vehiclePlate);
    _brandController = TextEditingController(text: driver?.vehicleBrand);
    _modelController = TextEditingController(text: driver?.vehicleModel);
    _colorController = TextEditingController(text: driver?.vehicleColor);
    _lineController = TextEditingController(text: driver?.affiliatedLine);
    _assignedCategory = driver?.vehicleCategory ?? 'Pendiente';

    _hasAirConditioning = driver?.hasAirConditioning ?? true;
    _hasGoodTires = driver?.hasGoodTires ?? true;
    _mechanicalCondition = driver?.mechanicalCondition ?? 'Sin fallas';
    _cleanlinessLevel = driver?.cleanlinessLevel ?? 'Impecable';
    _seatingMaterial = driver?.seatingMaterial ?? 'Tela';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _expController.dispose();
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.driverModel?.uid;
    if (uid == null) return;

    final data = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'yearsOfExperience': int.tryParse(_expController.text.trim()) ?? 0,
      'vehiclePlate': _plateController.text.trim(),
      'vehicleBrand': _brandController.text.trim(),
      'vehicleModel': _modelController.text.trim(),
      'vehicleColor': _colorController.text.trim(),
      'affiliatedLine': _lineController.text.trim(),
      'hasAirConditioning': _hasAirConditioning,
      'mechanicalCondition': _mechanicalCondition,
      'hasGoodTires': _hasGoodTires,
      'cleanlinessLevel': _cleanlinessLevel,
      'seatingMaterial': _seatingMaterial,
    };

    final success = await auth.updateDriverProfile(uid, data);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil de conductor actualizado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.successGreen,
        )
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Actualizar Datos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryColor, width: 2)),
                  child: auth.driverModel?.photoUrl != null && auth.driverModel!.photoUrl!.isNotEmpty
                    ? CircleAvatar(
                        radius: 45,
                        backgroundColor: AppTheme.surfaceColor,
                        backgroundImage: NetworkImage(auth.driverModel!.photoUrl!),
                      )
                    : const CircleAvatar(radius: 45, backgroundColor: AppTheme.surfaceColor, child: Icon(Icons.person, size: 45, color: AppTheme.primaryColor)),
                ),
              ),
              const Text('INFORMACIÓN PERSONAL', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              TextFormField(controller: _nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'Nombre Completo'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'Teléfono'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _addressController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'Dirección Principal'), validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _ageController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'Edad'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _expController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'Experiencia (años)'))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _lineController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'Línea de Taxi Adherida')),
              
              const SizedBox(height: 32),
              const Text('INFORMACIÓN DEL VEHÍCULO', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _brandController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'Marca'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _modelController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'Modelo'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _colorController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'Color'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _plateController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'No. Placa'))),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Categoría Asignada por Administrador:', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _assignedCategory,
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const Text('CONDICIÓN DEL VEHÍCULO', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Aire Acondicionado', style: TextStyle(color: AppTheme.textWhite)),
                value: _hasAirConditioning,
                activeColor: AppTheme.successGreen,
                onChanged: (val) => setState(() => _hasAirConditioning = val),
              ),
              SwitchListTile(
                title: const Text('Cauchos en buen estado', style: TextStyle(color: AppTheme.textWhite)),
                value: _hasGoodTires,
                activeColor: AppTheme.successGreen,
                onChanged: (val) => setState(() => _hasGoodTires = val),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _mechanicalCondition,
                dropdownColor: AppTheme.surfaceColor,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(labelText: 'Condición Mecánica'),
                items: _mechOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                onChanged: (val) => setState(() => _mechanicalCondition = val!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _cleanlinessLevel,
                      dropdownColor: AppTheme.surfaceColor,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: const InputDecoration(labelText: 'Nivel de Limpieza'),
                      items: _cleanOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                      onChanged: (val) => setState(() => _cleanlinessLevel = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _seatingMaterial,
                      dropdownColor: AppTheme.surfaceColor,
                      style: const TextStyle(color: AppTheme.textWhite),
                      decoration: const InputDecoration(labelText: 'Asientos'),
                      items: _seatOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                      onChanged: (val) => setState(() => _seatingMaterial = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              if (auth.error != null) ...[
                Text(auth.error!, style: const TextStyle(color: AppTheme.errorRed)),
                const SizedBox(height: 16),
              ],
              CustomButton(
                text: 'APLICAR CAMBIOS',
                isLoading: auth.isLoading,
                onPressed: _guardarCambios,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
