import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  UserModel? _userModel;
  DriverModel? _driverModel;
  bool _isLoading = false;
  String? _error;
  bool _isInitChecked = false;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  DriverModel? get driverModel => _driverModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _firebaseUser != null;
  String? get userRole => _userModel?.role;
  bool get isInitChecked => _isInitChecked;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    try {
      _firebaseUser = user;
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _userModel = null;
        _driverModel = null;
      }
    } catch (e) {
      debugPrint("Error en _onAuthStateChanged: $e");
      _firebaseUser = null;
      _userModel = null;
      _driverModel = null;
    } finally {
      _isInitChecked = true;
      notifyListeners();
    }
  }

  Future<void> _loadUserData(String uid) async {
    _userModel = await _authService.getUserData(uid);
    if (_userModel?.role == 'driver') {
      _driverModel = await _authService.getDriverData(uid);
    }
  }

  // Registrar como cliente
  Future<bool> registerClient({
    required String email,
    required String password,
    required String name,
    required String phone,
    File? profilePhoto,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.registerClient(
        email: email,
        password: password,
        name: name,
        phone: phone,
        profilePhoto: profilePhoto,
      );
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Registrar como conductor
  Future<bool> registerDriver({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required int age,
    required int yearsOfExperience,
    required String affiliatedLine,
    required String vehicleBrand,
    required String vehicleModel,
    required String vehicleColor,
    required String vehiclePlate,
    required bool hasAirConditioning,
    required String mechanicalCondition,
    required bool hasGoodTires,
    required String cleanlinessLevel,
    required String seatingMaterial,
    File? driverPhoto,
    File? vehiclePhotoFront,
    File? vehiclePhotoBack,
    File? vehiclePhotoInterior,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final driver = await _authService.registerDriver(
        email: email,
        password: password,
        name: name,
        phone: phone,
        address: address,
        age: age,
        yearsOfExperience: yearsOfExperience,
        affiliatedLine: affiliatedLine,
        vehicleBrand: vehicleBrand,
        vehicleModel: vehicleModel,
        vehicleColor: vehicleColor,
        vehiclePlate: vehiclePlate,
        hasAirConditioning: hasAirConditioning,
        mechanicalCondition: mechanicalCondition,
        hasGoodTires: hasGoodTires,
        cleanlinessLevel: cleanlinessLevel,
        seatingMaterial: seatingMaterial,
        driverPhoto: driverPhoto,
        vehiclePhotoFront: vehiclePhotoFront,
        vehiclePhotoBack: vehiclePhotoBack,
        vehiclePhotoInterior: vehiclePhotoInterior,
      );
      _isLoading = false;
      notifyListeners();
      return driver != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Iniciar sesión
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signIn(
        email: email,
        password: password,
      );
      if (user != null) {
        await _loadUserData(user.uid);
      }
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      debugPrint('Error en signIn: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Iniciar sesión como invitado (Pruebas)
  Future<bool> signInAsGuest(String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInAsGuest(role);
      if (user != null) {
        await _loadUserData(user.uid);
      }
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    // Si es un conductor, lo ponemos automáticamente como "no disponible"
    if (_firebaseUser != null && _userModel?.role == 'driver') {
      try {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(_firebaseUser!.uid)
            .update({'isAvailable': false});
      } catch (e) {
        debugPrint('Error al actualizar disponibilidad al cerrar sesión: $e');
      }
    }

    await _authService.signOut();
    _userModel = null;
    _driverModel = null;
    notifyListeners();
  }

  // Recuperar contraseña
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar Perfil Cliente
  Future<bool> updateClientProfile(String uid, String name, String phone) async {
    _isLoading = true; notifyListeners();
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': name,
        'phone': phone,
      });
      await _loadUserData(uid);
      _isLoading = false; notifyListeners();
      return true;
    } catch(e) {
      _error = e.toString();
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  // Actualizar Foto de Perfil
  Future<bool> updateProfilePhoto(String uid, String role, String photoUrl) async {
    _isLoading = true; notifyListeners();
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'photoUrl': photoUrl});
      if (role == 'driver') {
        await FirebaseFirestore.instance.collection('drivers').doc(uid).update({'photoUrl': photoUrl});
      }
      await _loadUserData(uid);
      _isLoading = false; notifyListeners();
      return true;
    } catch(e) {
      _error = e.toString();
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  // Actualizar Perfil Conductor
  Future<bool> updateDriverProfile(String uid, Map<String, dynamic> data) async {
    _isLoading = true; notifyListeners();
    try {
      final userUpdates = <String, dynamic>{};
      if (data.containsKey('name')) userUpdates['name'] = data['name'];
      if (data.containsKey('phone')) userUpdates['phone'] = data['phone'];
      
      if (userUpdates.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update(userUpdates);
      }
      await FirebaseFirestore.instance.collection('drivers').doc(uid).update(data);
      await _loadUserData(uid);
      
      _isLoading = false; notifyListeners();
      return true;
    } catch(e) {
      _error = e.toString();
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  // Cambiar Contraseña desde el Perfil
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true; notifyListeners();
    try {
      final user = _firebaseUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        _isLoading = false; notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Contraseña actual incorrecta.';
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  // Eliminar Cuenta
  Future<bool> deleteAccount(String currentPassword) async {
    _isLoading = true; notifyListeners();
    try {
      final user = _firebaseUser;
      if (user != null && user.email != null) {
        // 1. Re-autenticar por seguridad
        AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);

        final uid = user.uid;
        final role = _userModel?.role;

        // 2. Borrar datos de Firestore según el rol
        if (role == 'driver') {
          await FirebaseFirestore.instance.collection('drivers').doc(uid).delete().catchError((e) => debugPrint(e.toString()));
          await FirebaseFirestore.instance.collection('aspirantes_conductores').doc(uid).delete().catchError((e) => debugPrint(e.toString()));
        }
        await FirebaseFirestore.instance.collection('users').doc(uid).delete().catchError((e) => debugPrint(e.toString()));

        // 3. Borrar cuenta de Auth
        await user.delete();

        // 4. Limpiar estado
        _userModel = null;
        _driverModel = null;
        _isLoading = false; notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _error = 'Contraseña incorrecta.';
      } else {
        _error = 'Ocurrió un error al intentar eliminar la cuenta.';
      }
      _isLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _error = 'Ocurrió un error inesperado.';
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
}
