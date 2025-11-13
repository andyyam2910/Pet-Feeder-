// Este modelo define la estructura de datos
// del documento de estado del dispositivo en Firebase
class DeviceStatus {
  final double nivelAgua; // Espera un valor de 0 a 100
  final double nivelAlimento; // Espera un valor de 0 a 100

  DeviceStatus({
    required this.nivelAgua,
    required this.nivelAlimento,
  });

  // Este es un "constructor de fábrica" que crea una instancia de DeviceStatus
  // a partir de un Map (que es lo que nos da Firebase).
  factory DeviceStatus.fromMap(Map<String, dynamic> map) {
    // Usamos 'as num?' para ser flexibles (Firebase puede enviar int o double).
    // Usamos '?? 0.0' como valor por defecto si el campo no existe.
    return DeviceStatus(
      nivelAgua: (map['nivelAgua'] as num?)?.toDouble() ?? 0.0,
      nivelAlimento: (map['nivelAlimento'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

