import 'package:crud_pet_feeder/models/schedule.dart';
import 'package:crud_pet_feeder/services/schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear la hora
import 'package:provider/provider.dart';

class HorariosPage extends StatelessWidget {
  const HorariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el ScheduleService para acceder a su stream
    final scheduleService = context.watch<ScheduleService>();
    final schedulesStream = scheduleService.schedulesStream;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programar Horarios'),
        actions: [
          // Botón para añadir un nuevo horario
          IconButton(
            icon: const Icon(Icons.add_alarm),
            tooltip: 'Añadir Horario',
            onPressed: () {
              // Navegamos a la página del formulario en modo "crear"
              Navigator.pushNamed(context, '/add_schedule');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Schedule>>(
        stream: schedulesStream,
        builder: (context, snapshot) {
          // Caso 1: Esperando datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Caso 2: Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar horarios: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Caso 3: Lista vacía
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return SingleChildScrollView(
              child: Center(
                child: Builder(
                  builder: (context) {
                    final viewportHeight = MediaQuery.of(context).size.height - 
                                            (Scaffold.of(context).appBarMaxHeight ?? kToolbarHeight) -
                                            MediaQuery.of(context).padding.top - 
                                            MediaQuery.of(context).padding.bottom;
                    
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: viewportHeight.clamp(400, double.infinity),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_off, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No tienes horarios programados.',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Presiona el ícono "+" para añadir uno.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ),
            );
          }

          final schedules = List<Schedule>.from(snapshot.data!);
          
          // Ahora es seguro ordenar la copia
          schedules.sort((a, b) => a.timeOfDay.hour.compareTo(b.timeOfDay.hour) == 0 
              ? a.timeOfDay.minute.compareTo(b.timeOfDay.minute) 
              : a.timeOfDay.hour.compareTo(b.timeOfDay.hour));


          return ListView.builder(
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              
              final now = DateTime.now();
              final dt = DateTime(now.year, now.month, now.day, schedule.timeOfDay.hour, schedule.timeOfDay.minute);
              final formattedTime = DateFormat.jm().format(dt); 

              final daysShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
              List<String> activeDays = [];
              for (var day in daysShort) {
                if (schedule.daysOfWeek[day] == true) {
                  activeDays.add(day);
                }
              }
              final daysString = activeDays.isEmpty ? 'Nunca' : activeDays.join(', ');
              
              final foodString = "${schedule.gramos}g, ${schedule.tipoCroqueta.displayName}, ${schedule.ratioAgua.displayName}";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  
                  title: Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.bold,
                      color: schedule.isEnabled ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
                  
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        daysString,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: schedule.isEnabled ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      Text(
                        foodString,
                        style: TextStyle(
                          fontSize: 12,
                          color: schedule.isEnabled ? Colors.black54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true, 

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Para que la Row no se expanda
                    children: [
                      Switch(
                        value: schedule.isEnabled,
                        onChanged: (bool newValue) {
                          scheduleService.updateScheduleEnabled(schedule.id, newValue);
                        },
                      ),
                      
                      InkWell(
                        onTap: () => _showDeleteConfirmation(context, scheduleService, schedule),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                        ),
                      ),
                    ],
                  ),
                  
                  onTap: () {
                    Navigator.pushNamed(context, '/edit_schedule', arguments: schedule);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Diálogo de confirmación para borrar
  void _showDeleteConfirmation(BuildContext context, ScheduleService scheduleService, Schedule schedule) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar este horario? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () async {
                try {
                  await scheduleService.deleteSchedule(schedule.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Horario eliminado.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}