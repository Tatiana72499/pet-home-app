import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pethome_app/src/core/network/api_client.dart';

class NotificationService {
  NotificationService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  FirebaseMessaging? get _safeMessaging {
    if (kIsWeb) {
      return null;
    }

    return _messaging ??= FirebaseMessaging.instance;
  }

  static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'pethome_high_importance_channel', // id
    'Notificaciones de PetHome', // title
    description: 'Canal para notificaciones importantes de la veterinaria.',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('Notificaciones deshabilitadas en web');
      }
      return;
    }

    final messaging = _safeMessaging;
    if (messaging == null) {
      return;
    }

    // 1. Solicitar permisos (especialmente importante en iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('Permisos de notificaciones concedidos');
      }
      
      // 2. Obtener el token y registrarlo
      await _registerDeviceToken();

      // 3. Inicializar notificaciones locales
      await _initializeLocalNotifications();

      // 4. Configurar listeners de mensajes
      _configureListeners();
    } else {
      if (kDebugMode) {
        print('Permisos de notificaciones denegados');
      }
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      final messaging = _safeMessaging;
      if (messaging == null) {
        return;
      }

      String? token = await messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('Token FCM Móvil: $token');
        }

        // Registrar en el backend
        await _apiClient.send(
          method: 'POST',
          path: '/api/gestion/notificaciones/dispositivos/registrar/',
          body: {
            'token_fcm': token,
            'plataforma': kIsWeb ? 'WEB' : (Platform.isAndroid ? 'ANDROID' : 'IOS'),
          },
        );
        
        if (kDebugMode) {
          print('Token móvil registrado exitosamente en el backend');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al registrar token móvil: $e');
      }
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin, // Cambiado de darwin a iOS
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar click
      },
    );

    // Crear el canal en Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _configureListeners() {
    // Foreground: Cuando la app está abierta
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          id: notification.hashCode, // Ahora con nombre 'id'
          title: notification.title, // Ahora con nombre 'title'
          body: notification.body,   // Ahora con nombre 'body'
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,   // Posicional de nuevo
              _channel.name, // Posicional de nuevo
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
            ),
          ),
          payload: message.data['link']?.toString(),
        );
      }
      
      if (kDebugMode) {
        print('Mensaje recibido en primer plano: ${notification?.title}');
      }
    });

    // Background: Cuando el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('App abierta desde notificación: ${message.data}');
      }
      // Aquí podrías navegar a una pantalla específica
    });
  }

  /// Desactiva el dispositivo en el backend (útil para el logout)
  Future<void> uninitialize() async {
    try {
      final messaging = _safeMessaging;
      if (messaging == null) {
        return;
      }

      String? token = await messaging.getToken();
      if (token != null) {
        await _apiClient.send(
          method: 'POST',
          path: '/api/gestion/notificaciones/dispositivos/desactivar/',
          body: {'token_fcm': token},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al desactivar notificaciones: $e');
      }
    }
  }
}
