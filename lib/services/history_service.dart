import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crud_pet_feeder/models/history_log.dart';
import 'package:crud_pet_feeder/services/auth_services.dart';
import 'package:crud_pet_feeder/services/notification_service.dart'; 
import 'package:flutter/material.dart';

/*
 * Servicio para LEER el historial de alimentación.
 * AHORA: También escucha los nuevos registros para disparar notificaciones.
 */
class HistoryService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // --- 2. SERVICIOS INYECTADOS ---
  AuthService? _authService;
  NotificationService? _notificationService;
  
 
  List<HistoryLog> _logs = [];

  StreamSubscription? _historySubscription;

  bool _isInitialHistoryLoad = true;

  // --- 3. CONSTRUCTOR ACTUALIZADO ---
  HistoryService(this._authService, this._notificationService) {
    if (_authService?.user != null) {
      _initStream(_authService!.user!.uid);
    }
    _authService?.addListener(_onAuthChanged);
  }

  // Getter público para la UI
  List<HistoryLog> get logs => _logs;

  // --- MANEJO DE AUTENTICACIÓN ---
  void _onAuthChanged() {
    final user = _authService?.user;
    if (user != null) {
      _initStream(user.uid);
    } else {
      _cancelStream(); // Si cierra sesión, limpiamos todo
    }
  }

  void _cancelStream() {
    _historySubscription?.cancel();
    _historySubscription = null;
    _logs = [];
    notifyListeners();
  }

  void _initStream(String userId) {
    _cancelStream();
    _isInitialHistoryLoad = true; 
    
    final path = 'users/$userId/history';
    
    _historySubscription = _firestore
        .collection(path)
        .orderBy('timestamp', descending: true)
        .limit(50) 
        .snapshots()
        .listen((snapshot) { 
          
          // Actualizamos la lista completa
          _logs = snapshot.docs.map((doc) {
            return HistoryLog.fromMap(doc.id, doc.data());
          }).toList();

          if (!_isInitialHistoryLoad) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                if (_notificationService != null) {
                  debugPrint("Disparando notificación de DISPENSADO");
                  final newLog = HistoryLog.fromMap(change.doc.id, change.doc.data()!);
                  _notificationService!.showDispenseConfirmation(newLog);
                }
              }
            }
          }
          
          _isInitialHistoryLoad = false;

          notifyListeners();
          
        }, onError: (error) {
          debugPrint('Error en el stream de historial: $error');
          _logs = [];
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    _authService?.removeListener(_onAuthChanged);
    super.dispose();
  }
}