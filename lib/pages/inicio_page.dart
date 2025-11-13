import 'package:crud_pet_feeder/models/device_status.dart';
import 'package:crud_pet_feeder/services/auth_services.dart';
import 'package:crud_pet_feeder/services/device_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final deviceService = context.watch<DeviceService>();
    final statusStream = deviceService.statusStream;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pet Feeder+'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Sección de Monitoreo en Tiempo Real ---
            const Text(
              'Estado del Dispositivo',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<DeviceStatus>(
              stream: statusStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                  return const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Conectando al dispositivo...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al conectar: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final status = snapshot.data!;
                return _buildStatusIndicators(context, status);
              },
            ),

            const SizedBox(height: 32),
            
            // --- Sección de Acciones ---
            _buildActionButtons(context),

            const SizedBox(height: 32),

            // --- Sección de Navegación ---
            _buildNavigationButtons(context),
            
            const Spacer(), 
            
            Text(
              'UserID: ${authService.user?.uid ?? "N/A"}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8), // Pequeño espacio al final
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicators(BuildContext context, DeviceStatus status) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildLevelIndicator(
              context,
              icon: Icons.water_drop,
              label: 'Nivel de Agua',
              value: status.nivelAgua,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildLevelIndicator(
              context,
              icon: Icons.pets,
              label: 'Nivel de Alimento',
              value: status.nivelAlimento,
              color: Colors.brown,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelIndicator(BuildContext context, {required IconData icon, required String label, required double value, required Color color}) {
    double progressValue = value / 100.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 12,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.play_circle_fill),
          label: const Text('Dispensar Ahora'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/dispensar');
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.timer),
          label: const Text('Programar Horarios'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
            foregroundColor: Theme.of(context).primaryColor,
            side: BorderSide(color: Theme.of(context).primaryColor),
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/horarios');
          },
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0), // Padding vertical
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribuir horizontalmente
          children: [
            // Botón 1: Mascotas
            _buildNavButton(
              context,
              icon: Icons.pets,
              label: 'Mascotas',
              onPressed: () => Navigator.pushNamed(context, '/perros'),
            ),
            // Botón 2: Historial
            _buildNavButton(
              context,
              icon: Icons.history,
              label: 'Historial',
              onPressed: () => Navigator.pushNamed(context, '/historial'),
            ),
            // Botón 3: Ajustes
            _buildNavButton(
              context,
              icon: Icons.settings,
              label: 'Ajustes',
              onPressed: () => Navigator.pushNamed(context, '/ajustes'),
            ),
          ],
        ),
      ),
    );
  }

  // --- NUEVO HELPER WIDGET ---
  Widget _buildNavButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    final color = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}