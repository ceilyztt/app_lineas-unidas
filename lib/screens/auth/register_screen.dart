import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores Generales
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Controladores Específicos de Conductor
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _experienceController = TextEditingController();
  final _affiliatedLineController = TextEditingController();
  
  // Controladores de Vehículo
  final _vehicleBrandController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _vehiclePlateController = TextEditingController();

  // Fotos de Conductor y Vehículo
  File? _clientPhoto;
  File? _driverPhoto;
  File? _vehiclePhotoFront;
  File? _vehiclePhotoBack;
  File? _vehiclePhotoInterior;

  // Cuestionario de Evaluación Vehicular
  bool _hasAirConditioning = true;
  bool _hasGoodTires = true;
  String _mechanicalCondition = 'Sin fallas';
  final List<String> _mechOptions = ['Sin fallas', 'Fallas menores', 'Requiere reparación'];
  String _cleanlinessLevel = 'Impecable';
  final List<String> _cleanOptions = ['Impecable', 'Promedio', 'Regular'];
  String _seatingMaterial = 'Tela';
  final List<String> _seatOptions = ['Tela', 'Cuero', 'Otro'];

  bool _obscurePassword = true;
  String _selectedRole = 'client';
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && (args == 'client' || args == 'driver')) {
        _selectedRole = args;
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _experienceController.dispose();
    _affiliatedLineController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Seleccionar imagen',
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text('Tomar foto con la cámara', style: TextStyle(color: AppTheme.textWhite)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Elegir de la galería', style: TextStyle(color: AppTheme.textWhite)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 60,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (pickedFile != null) {
      setState(() {
        if (type == 'driver') {
          _driverPhoto = File(pickedFile.path);
        } else if (type == 'client') {
          _clientPhoto = File(pickedFile.path);
        } else if (type == 'front') {
          _vehiclePhotoFront = File(pickedFile.path);
        } else if (type == 'back') {
          _vehiclePhotoBack = File(pickedFile.path);
        } else if (type == 'interior') {
          _vehiclePhotoInterior = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validación adicional para conductor o cliente
    if (_selectedRole == 'driver') {
      if (_driverPhoto == null || _vehiclePhotoFront == null || _vehiclePhotoBack == null || _vehiclePhotoInterior == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, debes adjuntar todas las fotografías solicitadas.', style: TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
    } else if (_selectedRole == 'client') {
      if (_clientPhoto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, adjunta una foto clara tuya con fondo blanco.', style: TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_selectedRole == 'client') {
      success = await authProvider.registerClient(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        profilePhoto: _clientPhoto,
      );
    } else {
      success = await authProvider.registerDriver(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        yearsOfExperience: int.tryParse(_experienceController.text.trim()) ?? 0,
        affiliatedLine: _affiliatedLineController.text.trim(),
        vehicleBrand: _vehicleBrandController.text.trim(),
        vehicleModel: _vehicleModelController.text.trim(),
        vehicleColor: _vehicleColorController.text.trim(),
        vehiclePlate: _vehiclePlateController.text.trim().toUpperCase(),
        hasAirConditioning: _hasAirConditioning,
        mechanicalCondition: _mechanicalCondition,
        hasGoodTires: _hasGoodTires,
        cleanlinessLevel: _cleanlinessLevel,
        seatingMaterial: _seatingMaterial,
        driverPhoto: _driverPhoto,
        vehiclePhotoFront: _vehiclePhotoFront,
        vehiclePhotoBack: _vehiclePhotoBack,
        vehiclePhotoInterior: _vehiclePhotoInterior,
      );
    }

    if (success && mounted) {
      if (_selectedRole == 'driver') {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.driverPending, (r) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.clientHome, (r) => false);
      }
    }
  }

  Widget _buildPhotoPicker(String title, File? imageFile, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(type),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: imageFile != null ? AppTheme.primaryColor : AppTheme.cardColor,
                width: 2,
              ),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: AppTheme.textGrey, size: 40),
                      SizedBox(height: 8),
                      Text('Tocar para adjuntar foto', style: TextStyle(color: AppTheme.textGrey)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
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
                Text(
                  _selectedRole == 'driver' 
                    ? 'Completa tu información para unirte como conductor oficial.'
                    : 'Crea tu cuenta para comenzar a viajar.',
                  style: const TextStyle(color: AppTheme.textGrey),
                ),
                const SizedBox(height: 24),

                // DATOS COMUNES
                const Text(
                  'Datos Personales Básicos',
                  style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                  ],
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requerido';
                    if (!value.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(labelText: 'Teléfono celular', prefixIcon: Icon(Icons.phone_outlined)),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    labelText: 'Contraseña (Min. 6 caracteres)',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textGrey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requerido';
                    if (value.length < 6) return 'Mínimo 6 caracteres';
                    if (value.contains('"')) return 'No se admiten comillas dobles';
                    return null;
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'"')),
                  ],
                ),
                const SizedBox(height: 24),

                if (_selectedRole == 'client') ...[
                  const Divider(color: AppTheme.cardColor, thickness: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Fotografía de Seguridad',
                    style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildPhotoPicker('Foto clara del rostro (Fondo blanco)', _clientPhoto, 'client'),
                  const SizedBox(height: 8),
                ],

                // DATOS ESPECÍFICOS DEL CONDUCTOR
                if (_selectedRole == 'driver') ...[
                  const Divider(color: AppTheme.cardColor, thickness: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Información Profesional',
                    style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  _buildPhotoPicker('Foto clara del rostro (Fondo blanco)', _driverPhoto, 'driver'),

                  TextFormField(
                    controller: _addressController,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'Dirección de residencia', prefixIcon: Icon(Icons.home_outlined)),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s]')),
                    ],
                    validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.textWhite),
                          decoration: const InputDecoration(labelText: 'Edad', prefixIcon: Icon(Icons.calendar_month)),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _experienceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppTheme.textWhite),
                          decoration: const InputDecoration(labelText: 'Años Exp.', prefixIcon: Icon(Icons.work_history_outlined)),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _affiliatedLineController,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'Línea Actual (Escriba Líneas Unidas u otra)', prefixIcon: Icon(Icons.business)),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                    ],
                    validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 24),

                  const Divider(color: AppTheme.cardColor, thickness: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Datos del Vehículo',
                    style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _vehicleBrandController,
                          style: const TextStyle(color: AppTheme.textWhite),
                          decoration: const InputDecoration(labelText: 'Marca (Ej: Toyota)', prefixIcon: Icon(Icons.directions_car_outlined)),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                          ],
                          validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _vehicleColorController,
                          style: const TextStyle(color: AppTheme.textWhite),
                          decoration: const InputDecoration(labelText: 'Color', prefixIcon: Icon(Icons.color_lens_outlined)),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                          ],
                          validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _vehicleModelController,
                          style: const TextStyle(color: AppTheme.textWhite),
                          decoration: const InputDecoration(labelText: 'Modelo (Ej: Corolla)', prefixIcon: Icon(Icons.info_outline)),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                          ],
                          validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _vehiclePlateController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(color: AppTheme.textWhite),
                          decoration: const InputDecoration(labelText: 'Placa', prefixIcon: Icon(Icons.numbers)),
                          validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // CUESTIONARIO VEHICULAR
                  const Text(
                    'Evaluación Inicial del Vehículo',
                    style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('¿Tiene Aire Acondicionado?', style: TextStyle(color: AppTheme.textWhite)),
                    value: _hasAirConditioning,
                    activeColor: AppTheme.successGreen,
                    onChanged: (val) => setState(() => _hasAirConditioning = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('¿Neumáticos (cauchos) en buen estado?', style: TextStyle(color: AppTheme.textWhite)),
                    value: _hasGoodTires,
                    activeColor: AppTheme.successGreen,
                    onChanged: (val) => setState(() => _hasGoodTires = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _mechanicalCondition,
                    dropdownColor: AppTheme.surfaceColor,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'Condición Mecánica', prefixIcon: Icon(Icons.build_circle_outlined)),
                    items: _mechOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                    onChanged: (val) => setState(() => _mechanicalCondition = val!),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _cleanlinessLevel,
                          dropdownColor: AppTheme.surfaceColor,
                          style: const TextStyle(color: AppTheme.textWhite),
                          decoration: const InputDecoration(labelText: 'Limpieza', prefixIcon: Icon(Icons.cleaning_services_outlined)),
                          items: _cleanOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                          onChanged: (val) => setState(() => _cleanlinessLevel = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _seatingMaterial,
                          dropdownColor: AppTheme.surfaceColor,
                          style: const TextStyle(color: AppTheme.textWhite),
                          decoration: const InputDecoration(labelText: 'Asientos', prefixIcon: Icon(Icons.chair_outlined)),
                          items: _seatOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                          onChanged: (val) => setState(() => _seatingMaterial = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // FOTOS DEL CARRO
                  const Text(
                    'Fotografías del Vehículo',
                    style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  _buildPhotoPicker('Foto Frontal del Auto (visible la placa)', _vehiclePhotoFront, 'front'),
                  _buildPhotoPicker('Foto Trasera del Auto (visible la placa)', _vehiclePhotoBack, 'back'),
                  _buildPhotoPicker('Foto del Interior (Asientos limpios)', _vehiclePhotoInterior, 'interior'),
                ],

                // Error provider
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(auth.error!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13)),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // Submit
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return CustomButton(
                      text: _selectedRole == 'driver' ? 'ENVIAR SOLICITUD DE INGRESO' : 'REGISTRARME',
                      onPressed: _register,
                      isLoading: auth.isLoading,
                    );
                  },
                ),
                
                // Opción Iniciar Sesión (sólo para cliente, el conductor tiene otra UI)
                if (_selectedRole == 'client') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿Ya tienes una cuenta?', style: TextStyle(color: AppTheme.textGrey)),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.emailLogin),
                        child: const Text('Inicia sesión', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
