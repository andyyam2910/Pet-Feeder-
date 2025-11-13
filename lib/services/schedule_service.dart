import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crud_pet_feeder/models/schedule.dart';
import 'package:crud_pet_feeder/services/auth_services.dart';
import 'package:flutter/material.dart';

/*
 * Servicio para manejar el CRUD de los Horarios (Schedules)
 */
class ScheduleService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService? _authService;
  
  Stream<List<Schedule>>? _schedulesStream;

  ScheduleService(this._authService) {
    if (_authService?.user != null) {
      _initSchedulesStream(_authService!.user!.uid);
    }
    _authService?.addListener(_onAuthChanged);
  }

  Stream<List<Schedule>>? get schedulesStream => _schedulesStream;

  // --- MANEJO DE AUTENTICACIÓN ---
  void _onAuthChanged() {
    final user = _authService?.user;
    if (user != null) {
      _initSchedulesStream(user.uid);
    } else {
      _schedulesStream = null;
    }
    notifyListeners();
  }

  void _initSchedulesStream(String userId) {
    final path = 'users/$userId/schedules';
    _schedulesStream = _firestore.collection(path).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Schedule.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  String? get _userId => _authService?.user?.uid;

  Future<void> addSchedule(Schedule schedule) async {
    if (_userId == null) return;
    final path = 'users/$_userId/schedules';
    await _firestore.collection(path).add(schedule.toMap());
  }

  Future<void> updateSchedule(Schedule schedule) async {
    if (_userId == null || schedule.id.isEmpty) return;
    final path = 'users/$_userId/schedules';
    await _firestore.collection(path).doc(schedule.id).update(schedule.toMap());
  }
  
  Future<void> updateScheduleEnabled(String scheduleId, bool isEnabled) async {
    if (_userId == null) return;
    final path = 'users/$_userId/schedules';
    await _firestore.collection(path).doc(scheduleId).update({
      'isEnabled': isEnabled,
    });
  }

  Future<void> deleteSchedule(String scheduleId) async {
    if (_userId == null) return;
    final path = 'users/$_userId/schedules';
    await _firestore.collection(path).doc(scheduleId).delete();
  }

  @override
  void dispose() {
    _authService?.removeListener(_onAuthChanged);
    super.dispose();
  }
}