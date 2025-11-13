// 'userId' y 'source'
import 'package:cloud_firestore/cloud_firestore.dart';

// --- ENUM 1: TIPO DE CROQUETA ---
enum TipoCroqueta {
  tipoA(1, 'Tipo A', 'Tipo A: Cachorro'),
  tipoB(2, 'Tipo B', 'Tipo B: Adulto'),
  tipoC(3, 'Tipo C', 'Tipo C: Geriátrico');

  final int value;
  final String name;
  final String displayName;
  const TipoCroqueta(this.value, this.name, this.displayName);

  static TipoCroqueta fromName(String? name) {
    return TipoCroqueta.values.firstWhere((e) => e.name == name, orElse: () => TipoCroqueta.tipoA);
  }
  static TipoCroqueta fromValue(int? value) {
    return TipoCroqueta.values.firstWhere((e) => e.value == value, orElse: () => TipoCroqueta.tipoA);
  }
}

// --- ENUM 2: RATIO DE AGUA ---
enum RatioAgua {
  seco(0, 'Seco', 'Seco (Solo alimento)'),
  humedo(1, 'Húmedo', 'Húmedo (Ratio 1.5:1)'),
  caldoso(2, 'Caldoso', 'Caldoso (Ratio 2:1)'),
  sopa(3, 'Sopa', 'Sopa (Ratio 3:1)');

  final int value;
  final String name;
  final String displayName;
  const RatioAgua(this.value, this.name, this.displayName);

  static RatioAgua fromValue(int? value) {
    return RatioAgua.values.firstWhere((e) => e.value == value, orElse: () => RatioAgua.seco);
  }
}

// --- CLASE DEL COMANDO ---
class DispenseCommand {
  final double gramos;
  final TipoCroqueta tipoCroqueta;
  final RatioAgua ratioAgua;
  final Timestamp timestamp;
  
  final String userId; // ID del usuario para el historial
  final String source; // "Manual" o "Programado"

  DispenseCommand({
    required this.gramos,
    required this.tipoCroqueta,
    required this.ratioAgua,
    required this.timestamp,
    required this.userId, 
    required this.source, 
  });

  Map<String, dynamic> toMap() {
    return {
      'gramos': gramos,
      'tipoCroqueta': tipoCroqueta.value,
      'ratioAgua': ratioAgua.value,
      'timestamp': timestamp,
      'userId': userId, 
      'source': source, 
    };
  }
}