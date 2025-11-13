import 'package:crud_pet_feeder/services/history_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final historyService = context.watch<HistoryService>();
    final logs = historyService.logs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Alimentación'),
      ),
      // --- 2. LÓGICA DE UI SIMPLIFICADA ---
      body: logs.isEmpty
          ? const Center( // (Aquí también podríamos tener un 'snapshot.connectionState')
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aún no hay registros.',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Los dispensados aparecerán aquí.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];

                // Formateamos la fecha y hora
                final formattedDate = DateFormat.yMMMd().format(log.timestamp.toDate());
                final formattedTime = DateFormat.jm().format(log.timestamp.toDate());
                final formattedDateTime = '$formattedDate a las $formattedTime';
                
                // Configuramos el ícono
                IconData icon;
                Color iconColor;
                if (log.source == 'Manual') {
                  icon = Icons.play_circle_fill;
                  iconColor = Colors.blue;
                } else if (log.source == 'Programado') {
                  icon = Icons.timer;
                  iconColor = Colors.green;
                } else {
                  icon = Icons.question_mark;
                  iconColor = Colors.grey;
                }

                // Creamos el string de la comida
                final foodString = "${log.gramos}g, ${log.tipoCroqueta.displayName}, ${log.ratioAgua.displayName}";

                return ListTile(
                  leading: Icon(icon, color: iconColor, size: 30),
                  title: Text(
                    'Dispensado ${log.source}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('$foodString\n$formattedDateTime'),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}