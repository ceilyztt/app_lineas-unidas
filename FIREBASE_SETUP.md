# Guía de Configuración — Firebase y Google Maps

## Paso 1: Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Haz clic en **"Agregar proyecto"**
3. Nombre del proyecto: `lineas-unidas`
4. Desactiva Google Analytics (opcional para MVP)
5. Clic en **"Crear proyecto"**

## Paso 2: Configurar Authentication

1. En Firebase Console, ve a **Authentication** → **Sign-in method**
2. Habilita **"Correo electrónico/contraseña"**
3. Guarda cambios

## Paso 3: Crear Base de Datos Firestore

1. Ve a **Firestore Database** → **Crear base de datos**
2. Selecciona **"Modo de producción"** (o "prueba" para desarrollo)
3. Elige la ubicación más cercana a Venezuela (ej: `us-east1`)

### Reglas de Firestore sugeridas:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios autenticados pueden leer/escribir sus propios datos
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /drivers/{driverId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == driverId;
    }
    match /rides/{rideId} {
      allow read, write: if request.auth != null;
    }
    match /ratings/{ratingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
    match /national_fares/{fareId} {
      allow read: if request.auth != null;
    }
    match /config/{docId} {
      allow read: if request.auth != null;
    }
  }
}
```

## Paso 4: Agregar App Android

1. En Firebase Console → **Configuración del proyecto** → **Agregar app** → Android
2. Nombre del paquete: `com.lineasunidas.lineas_unidas`
3. Apodo: `Líneas Unidas Android`
4. Descarga `google-services.json`
5. Cópialo a: `android/app/google-services.json`

## Paso 5: Agregar App iOS (opcional)

1. En Firebase Console → **Agregar app** → iOS
2. Bundle ID: `com.lineasunidas.lineasUnidas`
3. Descarga `GoogleService-Info.plist`
4. Cópialo a: `ios/Runner/GoogleService-Info.plist`

## Paso 6: Instalar Firebase CLI (FlutterFire)

Ejecuta en la terminal:
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=lineas-unidas
```
Esto generará automáticamente `firebase_options.dart`.

Luego actualiza `main.dart` para usar las opciones:
```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LineasUnidasApp());
}
```

## Paso 7: Configurar Google Maps

### Obtener API Key:
1. Ve a [Google Cloud Console](https://console.cloud.google.com)
2. Crea un proyecto (o usa el mismo de Firebase)
3. Ve a **APIs y servicios** → **Biblioteca**
4. Habilita:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Directions API
   - Geocoding API
5. Ve a **Credenciales** → **Crear credencial** → **API Key**
6. Copia tu API Key

### Android — Agregar API Key:
Edita `android/app/src/main/AndroidManifest.xml` y agrega dentro de `<application>`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI"/>
```

### iOS — Agregar API Key:
Edita `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("TU_API_KEY_AQUI")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Paso 8: Permisos de Ubicación

### Android (`android/app/src/main/AndroidManifest.xml`):
Agrega antes de `<application>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (`ios/Runner/Info.plist`):
Agrega dentro de `<dict>`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrarte en el mapa y encontrar conductores cercanos.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para el seguimiento del viaje.</string>
```

## Paso 9: Datos Iniciales en Firestore

### Configuración de tarifas (colección `config`, documento `fares`):
```json
{
  "fareBase": 2.0,
  "pricePerKm": 1.5
}
```

### Ejemplo de tarifa nacional (colección `national_fares`):
```json
{
  "fareId": "barinas-caracas",
  "origin": "Barinas",
  "destination": "Caracas",
  "price": 150.0,
  "description": "Viaje directo, aprox. 8 horas"
}
```

## Paso 10: Compilar y Ejecutar

```bash
cd lineas_unidas
flutter pub get
flutter run
```

Para generar APK:
```bash
flutter build apk --release
```
El APK estará en: `build/app/outputs/flutter-apk/app-release.apk`
