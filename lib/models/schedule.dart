import 'package:crud_pet_feeder/models/dispense_command.dart';
import 'package:flutter/material.dart'; // Necesario para TimeOfDay

class Schedule {
  final String id;
  final TimeOfDay timeOfDay; // La hora (ej: 8:30 AM)
  final Map<String, bool> daysOfWeek; // {'Lun': true, 'Mar': false, ...}
  final double gramos;
  final TipoCroqueta tipoCroqueta;
  final RatioAgua ratioAgua;
  bool isEnabled; // Si el horario está activo o no

  Schedule({
    required this.id,
    required this.timeOfDay,
    required this.daysOfWeek,
    required this.gramos,
    required this.tipoCroqueta,
    required this.ratioAgua,
    required this.isEnabled,
  });

  // Convertir un objeto Schedule a un Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'timeString': '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}',
      'daysOfWeek': daysOfWeek,
      'gramos': gramos,
      
      'tipoCroqueta': tipoCroqueta.value, 
      
      'ratioAgua': ratioAgua.value,
      'isEnabled': isEnabled,
    };
  }

  // Crear un objeto Schedule desde un Map (usado por el service)
  static Schedule fromMap(String id, Map<String, dynamic> data) {
    
    TimeOfDay timeFromString(String timeStr) {
      try {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        return const TimeOfDay(hour: 12, minute: 0);
      }
    }

    final daysData = Map<String, bool>.from(data['daysOfWeek'] ?? {});
    final defaultDays = {
      'Lun': daysData['Lun'] ?? false,
      'Mar': daysData['Mar'] ?? false,
      'Mié': daysData['Mié'] ?? false,
      'Jue': daysData['Jue'] ?? false,
      'Vie': daysData['Vie'] ?? false,
      'Sáb': daysData['Sáb'] ?? false,
      'Dom': daysData['Dom'] ?? false,
    };

    return Schedule(
      id: id,
      timeOfDay: timeFromString(data['timeString'] ?? '12:00'),
      daysOfWeek: defaultDays,
      gramos: (data['gramos'] as num?)?.toDouble() ?? 50.0,
      
      // Leemos el VALOR (int) en lugar del NOMBRE (String)
      tipoCroqueta: TipoCroqueta.fromValue(data['tipoCroqueta']), 
      
      ratioAgua: RatioAgua.fromValue(data['ratioAgua']),
      isEnabled: data['isEnabled'] ?? true,
    );
  }
}