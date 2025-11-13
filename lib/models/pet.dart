import 'package:cloud_firestore/cloud_firestore.dart';

// --- ENUM 1: NIVEL DE ACTIVIDAD ---
enum TipoActividad {
  // Casos del Enum
  baja,
  moderada,
  alta;

  // Propiedad 'displayName' para mostrar en la UI
  String get displayName {
    switch (this) {
      case TipoActividad.baja:
        return 'Baja (Paseos cortos)';
      case TipoActividad.moderada:
        return 'Moderada (Juego/Paseos)';
      case TipoActividad.alta:
        return 'Alta (Muy activo)';
    }
  }

  // Constructor 'fromString' para leer desde Firebase
  static TipoActividad fromString(String? name) {
    return TipoActividad.values.firstWhere(
      (e) => e.name == name,
      orElse: () => TipoActividad.moderada, // Valor por defecto
    );
  }
}

// --- ENUM 2: TIPO DE ALIMENTO ---
enum TipoAlimento {
  // Casos del Enum
  seco,
  humedecido, // "Enlatado" cambiado por "Humedecido"
  secoHumedecido; // Nueva opción

  // Propiedad 'displayName' para mostrar en la UI
  String get displayName {
    switch (this) {
      case TipoAlimento.seco:
        return 'Seco';
      case TipoAlimento.humedecido:
        return 'Humedecido'; // "Enlatado" cambiado por "Humedecido"
      case TipoAlimento.secoHumedecido:
        return 'Seco y Humedecido'; // Nueva opción
    }
  }

  // Constructor 'fromString' para leer desde Firebase
  static TipoAlimento fromString(String? name) {
    return TipoAlimento.values.firstWhere(
      (e) => e.name == name,
      orElse: () => TipoAlimento.seco, // Valor por defecto
    );
  }
}


// --- CLASE PRINCIPAL: Pet ---
class Pet {
  final String id;
  final String nombre;
  final DateTime fechaNacimiento;
  final double peso;
  final TipoActividad actividad;
  final TipoAlimento tipoAlimento;

  Pet({
    required this.id,
    required this.nombre,
    required this.fechaNacimiento,
    required this.peso,
    required this.actividad,
    required this.tipoAlimento,
  });

  // Convertir un objeto Pet a un Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'fechaNacimiento': Timestamp.fromDate(fechaNacimiento),
      'peso': peso,
      'actividad': actividad.name, // Guardamos el nombre (ej: "baja")
      'tipoAlimento': tipoAlimento.name, // Guardamos el nombre (ej: "seco")
    };
  }

  // Crear un objeto Pet desde un Map (usado por el service)
  static Pet fromMap(String id, Map<String, dynamic> data) {
    return Pet(
      id: id,
      nombre: data['nombre'] ?? 'Sin Nombre',
      // Manejo seguro de Timestamps nulos o de tipo incorrecto
      fechaNacimiento: (data['fechaNacimiento'] is Timestamp)
          ? (data['fechaNacimiento'] as Timestamp).toDate()
          : DateTime.now(),
      peso: (data['peso'] as num?)?.toDouble() ?? 0.0,
      actividad: TipoActividad.fromString(data['actividad']),
      tipoAlimento: TipoAlimento.fromString(data['tipoAlimento']),
    );
  }
}

