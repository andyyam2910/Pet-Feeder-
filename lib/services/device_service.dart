import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crud_pet_feeder/models/device_status.dart';
import 'package:crud_pet_feeder/models/dispense_command.dart';
import 'package:crud_pet_feeder/services/notification_service.dart'; 
import 'package:flutter/material.dart';

/*
 * Servicio para manejar el DISPOSITIVO (Estado y Comandos)
 * Se conecta a /devices/{deviceId}
 */
class DeviceService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _deviceId = 'petfeeder_001'; // ID fijo para el dispositivo
  
  // --- 2. SERVICIO DE NOTIFICACIÓN (Inyectado) ---
  NotificationService? _notificationService;

  Stream<DeviceStatus>? _statusStream;
  
  // Flags para evitar spam de notificaciones
  bool _isLowWaterNotified = false;
  bool _isLowFoodNotified = false;

  // --- 3. CONSTRUCTOR ACTUALIZADO (Acepta el servicio) ---
  DeviceService(this._notificationService) {
    _initStream(); // Inicia el stream al crear el servicio
  }

  // Getter público para la UI
  Stream<DeviceStatus>? get statusStream => _statusStream;

  // Inicializa el listener de Firestore
  void _initStream() {
    final docRef = _firestore.collection('devices').doc(_deviceId);

    _statusStream = docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return DeviceStatus(nivelAgua: 0, nivelAlimento: 0);
      }
      
      final status = DeviceStatus.fromMap(snapshot.data()!);

      // --- 4. LÓGICA DE NOTIFICACIÓN DE NIVEL BAJO ---
      // (Comprueba si el servicio existe antes de llamarlo)
      if (_notificationService != null) {
        // Lógica para Agua
        if (status.nivelAgua < 20 && !_isLowWaterNotified) {
          debugPrint("Disparando notificación de AGUA BAJA");
          _notificationService!.showLowLevelWarning("Agua");
          _isLowWaterNotified = true; 
        } else if (status.nivelAgua >= 20) {
          _isLowWaterNotified = false; 
        }
        
        // Lógica para Alimento
        if (status.nivelAlimento < 20 && !_isLowFoodNotified) {
          debugPrint("Disparando notificación de ALIMENTO BAJO");
          _notificationService!.showLowLevelWarning("Alimento");
          _isLowFoodNotified = true; // Marcamos como notificado
        } else if (status.nivelAlimento >= 20) {
          _isLowFoodNotified = false; // Reseteamos si el nivel sube
        }
      }
      // --- FIN DE LA LÓGICA DE NOTIFICACIÓN ---

      return status;
    });
  }

  // --- MÉTODO PARA ENVIAR COMANDO ---
  Future<void> dispenseNow(DispenseCommand command) async {
    final path = 'devices/$_deviceId/commands';
    try {
      await _firestore.collection(path).add(command.toMap());
      debugPrint("Comando enviado");
    } catch (e) {
      debugPrint("Error al enviar comando: $e");
      throw Exception('Error al enviar comando al dispositivo');
    }
  }
}