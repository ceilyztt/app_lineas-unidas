import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_upload_service.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrar como cliente
  Future<UserModel?> registerClient({
    required String email,
    required String password,
    required String name,
    required String phone,
    File? profilePhoto,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;
      final String uid = credential.user!.uid;

      String? uploadedPhotoUrl;
      if (profilePhoto != null) {
        uploadedPhotoUrl = await _uploadImage(profilePhoto, uid, 'profile', folder: 'clients');
      }

      final user = UserModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        role: 'client',
        photoUrl: uploadedPhotoUrl,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Registrar como conductor
  Future<DriverModel?> registerDriver({
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
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return null;
      final String uid = credential.user!.uid;

      // Subir fotos a Firebase Storage
      String? uploadedDriverPhotoUrl;
      String? uploadedVehicleFrontUrl;
      String? uploadedVehicleBackUrl;
      String? uploadedVehicleInteriorUrl;

      if (driverPhoto != null) uploadedDriverPhotoUrl = await _uploadImage(driverPhoto, uid, 'profile');
      if (vehiclePhotoFront != null) uploadedVehicleFrontUrl = await _uploadImage(vehiclePhotoFront, uid, 'vehicle_front');
      if (vehiclePhotoBack != null) uploadedVehicleBackUrl = await _uploadImage(vehiclePhotoBack, uid, 'vehicle_back');
      if (vehiclePhotoInterior != null) uploadedVehicleInteriorUrl = await _uploadImage(vehiclePhotoInterior, uid, 'vehicle_interior');

      // Crear documento en users
      final user = UserModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        role: 'driver',
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(user.toMap());

      // Crear documento en drivers
      final driver = DriverModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        photoUrl: uploadedDriverPhotoUrl,
        address: address,
        age: age,
        yearsOfExperience: yearsOfExperience,
        affiliatedLine: affiliatedLine,
        vehicleBrand: vehicleBrand,
        vehicleModel: vehicleModel,
        vehicleColor: vehicleColor,
        vehiclePlate: vehiclePlate,
        vehicleCategory: 'Pendiente', // Asignado posteriormente por el administrador
        hasAirConditioning: hasAirConditioning,
        mechanicalCondition: mechanicalCondition,
        hasGoodTires: hasGoodTires,
        cleanlinessLevel: cleanlinessLevel,
        seatingMaterial: seatingMaterial,
        vehiclePhotoFrontUrl: uploadedVehicleFrontUrl,
        vehiclePhotoBackUrl: uploadedVehicleBackUrl,
        vehiclePhotoInteriorUrl: uploadedVehicleInteriorUrl,
        isApproved: false, 
        isAvailable: false,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('drivers').doc(uid).set(driver.toMap());

      return driver;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<String?> _uploadImage(File file, String uid, String pathName, {String folder = 'drivers'}) async {
    return await ApiUploadService.subirImagenAInternet(file);
  }

  // Iniciar sesión
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Ocurrió un error inesperado al iniciar sesión.';
    }
  }

  // Iniciar sesión como invitado (Bypass para pruebas)
  Future<User?> signInAsGuest(String role) async {
    try {
      final credential = await _auth.signInAnonymously();
      if (credential.user == null) return null;
      final uid = credential.user!.uid;

      // Crear documento dummy en users
      final user = UserModel(
        uid: uid,
        name: role == 'driver' ? 'Conductor Demo' : 'Pasajero Demo',
        email: 'demo_$uid@prueba.com',
        phone: '1234567890',
        role: role,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(user.toMap());

      if (role == 'driver') {
        final driver = DriverModel(
          uid: uid,
          name: 'Conductor Demo',
          email: 'demo_$uid@prueba.com',
          phone: '1234567890',
          address: 'Dirección de Prueba',
          age: 30,
          yearsOfExperience: 5,
          affiliatedLine: 'Líneas Unidas Test',
          vehicleBrand: 'Toyota',
          vehicleModel: 'Vehículo de Prueba',
          vehicleColor: 'Blanco',
          vehiclePlate: 'TEST-123',
          vehicleCategory: 'Pendiente',
          hasAirConditioning: true,
          mechanicalCondition: 'Sin fallas',
          hasGoodTires: true,
          cleanlinessLevel: 'Impecable',
          seatingMaterial: 'Cuero',
          isApproved: true, // Auto-aprobado para facilitar pruebas
          isAvailable: false,
          createdAt: DateTime.now(),
          bankName: 'Banesco',
          bankPhone: '04121234567',
          bankDni: 'V-12345678',
        );
        await _firestore.collection('drivers').doc(uid).set(driver.toMap());
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      _auth.setLanguageCode('es'); // Forzar idioma a Español
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Obtener rol del usuario
  Future<String?> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['role'] as String?;
    }
    return null;
  }

  // Obtener datos del usuario
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Obtener datos del conductor
  Future<DriverModel?> getDriverData(String uid) async {
    final doc = await _firestore.collection('drivers').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return DriverModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Manejar errores de Firebase Auth
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'user-not-found':
        return 'Correo no registrado.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Correo no registrado o contraseña incorrecta.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
