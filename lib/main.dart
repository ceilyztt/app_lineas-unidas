import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'app.dart'; // Importamos la estructura completa de la app que ya creamos
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      // Inicialización para entorno Web
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBuwq3vk-XpkFcrZzRR2I-r3YL2F75zxgw',
          authDomain: 'lineas-unidas.firebaseapp.com',
          projectId: 'lineas-unidas',
          storageBucket: 'lineas-unidas.firebasestorage.app',
          messagingSenderId: '512774131346',
          appId: '1:512774131346:web:5a11e4fd4c5c1e484ce04b',
          measurementId: 'G-VL2128ESSD',
        ),
      );
    } else {
      // Inicialización para entorno Móvil (Android)
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyALFYauQuVREEPzQlK4fXa16KUT3iro7E0',
          appId: '1:512774131346:android:6774d09429aa74ab4ce04b',
          messagingSenderId: '512774131346',
          projectId: 'lineas-unidas',
          storageBucket: 'lineas-unidas.appspot.com',
        ),
      );
    }
  } catch (e) {
    debugPrint("Advertencia - Error inicializando Firebase: $e");
  }

  try {
    // Inicializar servicio de notificaciones (incluye OneSignal)
    await NotificationService().initialize();
  } catch (e) {
    debugPrint("Advertencia - Error inicializando Servicio de Notificaciones: $e");
  }

  // Lanzamos la aplicación completa (definida en lib/app.dart)
  runApp(const LineasUnidasApp());
}
