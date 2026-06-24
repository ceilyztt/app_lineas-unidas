import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart'; // Importamos la estructura completa de la app que ya creamos
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicialización manual de Firebase con los placeholders que proporcionaste
    // NOTA: Para producción o cuando tengas tu proyecto real, debes usar:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyALFYauQuVREEPzQlK4fXa16KUT3iro7E0', // <--- Revisa letra por letra
        appId: '1:512774131346:android:6774d09429aa74ab4ce04b',
        messagingSenderId: '512774131346',
        projectId: 'lineas-unidas',
        storageBucket: 'lineas-unidas.appspot.com',
      ),
    );
    
    // Inicializar servicio de notificaciones
    await NotificationService().initialize();
  } catch (e) {
    debugPrint("Advertencia - Error inicializando Firebase o Notificaciones: $e");
    // Lo envolvemos en un try-catch para que la app no crashee en el emulador
    // si las credenciales aún son "TU_API_KEY_AQUI", así al menos podrás ver la UI.
  }

  // Lanzamos la aplicación completa (definida en lib/app.dart)
  runApp(const LineasUnidasApp());
}
