import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static bool isChatOpen = false;
  static String? activeRideId;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Inicializar notificaciones
  Future<void> initialize() async {
    // Solicitar permisos
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configurar notificaciones locales
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

    // Crear canal de notificación para Android
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

    // Escuchar mensajes en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Escuchar cuando se toca una notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // Obtener token FCM
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  // Suscribirse a un tema (ej: 'drivers' para todos los conductores)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // Desuscribirse de un tema
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
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
