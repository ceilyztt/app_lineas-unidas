import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_upload_service.dart';
import '../widgets/custom_button.dart';

class EditClientProfileScreen extends StatefulWidget {
  const EditClientProfileScreen({super.key});

  @override
  State<EditClientProfileScreen> createState() => _EditClientProfileScreenState();
}

class _EditClientProfileScreenState extends State<EditClientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phone);
  }

  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _cambiarFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    
    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      
      try {
        final url = await ApiUploadService.subirImagenAInternet(File(pickedFile.path));
        
        if (url != null) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final uid = auth.userModel?.uid;
          if (uid != null) {
            await auth.updateProfilePhoto(uid, 'client', url);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Foto actualizada correctamente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: AppTheme.successGreen),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al subir foto: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppTheme.errorRed),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userModel?.uid;
    if (uid == null) return;

    final success = await auth.updateClientProfile(
      uid,
      _nameController.text.trim(),
      _phoneController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(title: const Text('Editar Perfil Pasajero')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _isUploadingImage ? null : _cambiarFoto,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryColor, width: 2)),
                      child: auth.userModel?.photoUrl != null && auth.userModel!.photoUrl!.isNotEmpty
                        ? CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.surfaceColor,
                            backgroundImage: NetworkImage(auth.userModel!.photoUrl!),
                          )
                        : const CircleAvatar(radius: 40, backgroundColor: AppTheme.surfaceColor, child: Icon(Icons.person, size: 40, color: AppTheme.primaryColor)),
                    ),
                    if (_isUploadingImage)
                      const CircularProgressIndicator(color: AppTheme.primaryColor)
                    else
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person_outline)),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                ],
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined)),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) => v!.length < 10 ? 'Teléfono inválido' : null,
              ),
              const SizedBox(height: 32),
              if (auth.error != null) ...[
                Text(auth.error!, style: const TextStyle(color: AppTheme.errorRed)),
                const SizedBox(height: 16),
              ],
              CustomButton(
                text: 'GUARDAR CAMBIOS',
                isLoading: auth.isLoading,
                onPressed: _guardarCambios,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
