import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Patrón Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static bool isChatOpen = false;
  static String? activeRideId;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Inicializar notificaciones
  Future<void> initialize() async {
    // 1. Solicitar permisos de Firebase Messaging (FCM) de forma segura
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint("FCM requestPermission error: $e");
    }

    // 2. Configurar notificaciones locales de forma segura
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // Solicitar permiso explícito de notificaciones para Android 13+
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint("Local notifications initialize/permission error: $e");
    }

    // 3. Crear canal de notificación para Android de forma segura
    try {
      const androidChannel = AndroidNotificationChannel(
        'lineas_unidas_channel',
        'Líneas Unidas',
        description: 'Notificaciones de viajes y solicitudes',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    } catch (e) {
      debugPrint("Create notification channel error: $e");
    }

    // 4. Registrar escuchas de Firebase Messaging de forma segura
    try {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    } catch (e) {
      debugPrint("Firebase Messaging listen error: $e");
    }
  }

  // Obtener token FCM
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  // Suscribirse a un tema (ej: 'drivers' para todos los conductores)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint("Error subscribing to topic $topic: $e");
    }
  }

  // Desuscribirse de un tema
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint("Error unsubscribing from topic $topic: $e");
    }
  }

  // Mostrar notificación local
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'lineas_unidas_channel',
      'Líneas Unidas',
      channelDescription: 'Notificaciones de viajes y solicitudes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint("Error showing local notification: $e");
    }
  }

  // Manejar mensajes en primer plano
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'Líneas Unidas',
        body: notification.body ?? '',
        payload: message.data['rideId'],
      );
    }
  }

  // Manejar cuando se abre la app desde una notificación
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Navegar a la pantalla correspondiente basado en el mensaje
    // Esto se puede conectar con el router de la app
  }

  static void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      navigatorKey.currentState?.pushNamed('/chat', arguments: payload);
    }
  }
}
