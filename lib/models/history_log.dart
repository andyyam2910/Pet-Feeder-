import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crud_pet_feeder/models/dispense_command.dart';

/*
 * Modelo para un registro del historial de alimentación.
 * Estos objetos son de "solo lectura" en la app.
 * Se asume que el ESP32 (dispositivo) es quien los escribe.
 */
class HistoryLog {
  final String id;
  final Timestamp timestamp;    // La hora exacta en que se dispensó
  final double gramos;
  final TipoCroqueta tipoCroqueta;
  final RatioAgua ratioAgua;
  final String source;          // Fuente: "Manual" o "Programado"

  HistoryLog({
    required this.id,
    required this.timestamp,
    required this.gramos,
    required this.tipoCroqueta,
    required this.ratioAgua,
    required this.source,
  });

  // Crear un objeto HistoryLog desde un Map de Firebase
  static HistoryLog fromMap(String id, Map<String, dynamic> data) {
    return HistoryLog(
      id: id,
      //  '?? Timestamp.now()' como fallback si el dato viene nulo
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      gramos: (data['gramos'] as num?)?.toDouble() ?? 0.0,
      
      // Reconstruimos los Enums de forma segura
      tipoCroqueta: TipoCroqueta.fromValue(data['tipoCroqueta']),
      ratioAgua: RatioAgua.fromValue(data['ratioAgua']),
      
      source: data['source'] as String? ?? 'Desconocido',
    );
  }
}