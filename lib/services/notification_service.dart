import 'package:crud_pet_feeder/models/history_log.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/*
 * Servicio para manejar las Notificaciones Locales
 * Esta es una clase normal (no un singleton) que será
 * "inyectada" (Provided) a los otros servicios.
 */
class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // --- 1. Detalles del Canal (para Android) ---
  static const AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
    'pet_feeder_channel', // ID único del canal
    'Pet Feeder Notifications', // Nombre visible para el usuario
    channelDescription: 'Notificaciones del dispensador de comida para mascotas',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher', // Usa el ícono de la app
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidNotificationDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // --- 2. Método de Inicialización  ---
  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notificación tocada: ${response.payload}');
      },
    );

    // Pedimos permiso explícitamente (para Android 13+)
    try {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Error pidiendo permiso de notificación en Android: $e');
    }

    _isInitialized = true;
    debugPrint('✅ Notificaciones Locales inicializadas correctamente');
  }

  // --- 3. MÉTODO: Alerta de Nivel Bajo ---
  Future<void> showLowLevelWarning(String resource) async {
    if (!_isInitialized) await init();
    try {
      // Usamos un ID diferente para Agua (1) y Alimento (2)
      final id = resource.toLowerCase() == 'agua' ? 1 : 2;
      
      await _flutterLocalNotificationsPlugin.show(
        id, 
        'Pet Feeder+ 🐾 (Alerta)',
        '¡Nivel bajo! Queda poca $resource en el dispensador.',
        _notificationDetails,
        payload: 'low_level_${resource.toLowerCase()}',
      );
    } catch (e) {
      debugPrint('Error al mostrar notificación de nivel bajo: $e');
    }
  }

  // --- 4. MÉTODO: Confirmación de Dispensado ---
  Future<void> showDispenseConfirmation(HistoryLog log) async {
    if (!_isInitialized) await init();
    
    final petName = "tu mascota"; 
    
    try {
      await _flutterLocalNotificationsPlugin.show(
        0, // ID 0 para la notificación de dispensado
        'Pet Feeder+ 🐾 (Éxito)',
        '¡Se ha alimentado a $petName! (${log.gramos}g, ${log.source})',
        _notificationDetails,
        payload: 'dispense_success_${log.id}',
      );
    } catch (e) {
      debugPrint('Error al mostrar notificación de dispensado: $e');
    }
  }
}