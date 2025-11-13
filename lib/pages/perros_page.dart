
import 'package:crud_pet_feeder/models/pet.dart';
import 'package:crud_pet_feeder/services/pet_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PerrosPage extends StatelessWidget {
  const PerrosPage({super.key});

  @override
  Widget build(BuildContext context) {

    final petService = context.watch<PetService>();
    final petsStream = petService.petsStream;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mascotas'),
        actions: [

          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Añadir Mascota',
            onPressed: () {

              Navigator.pushNamed(context, '/add_pet');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Pet>>(
        stream: petsStream,
        builder: (context, snapshot) {
          // Caso 1: Esperando datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Caso 2: Error
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar mascotas: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Caso 3: Lista vacía
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tienes mascotas registradas.',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Presiona el ícono "+" para añadir una.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Caso 4: Mostrar la lista de mascotas
          final pets = snapshot.data!;
          return ListView.builder(
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              
              // Fecha de nacimiento formateada
              final formattedDate = "${pet.fechaNacimiento.day}/${pet.fechaNacimiento.month}/${pet.fechaNacimiento.year}";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    child: const Icon(Icons.pets, color: Colors.white),
                  ),
                  title: Text(
                    pet.nombre,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nacimiento: $formattedDate (${pet.peso} Kg)'),
                      Text('Actividad: ${pet.actividad.displayName}'),
                      Text('Alimento: ${pet.tipoAlimento.displayName}'),
                    ],
                  ),
                  isThreeLine: true, 
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón de Editar
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          // Navegamos a la página de formulario en modo "editar"
                          Navigator.pushNamed(context, '/edit_pet', arguments: pet);
                        },
                      ),
                      // Botón de Borrar
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmation(context, petService, pet);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Diálogo de confirmación para borrar
  void _showDeleteConfirmation(BuildContext context, PetService petService, Pet pet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar a ${pet.nombre}? Esta acción no se puede deshacer.'),
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
                  await petService.deletePet(pet.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mascota eliminada.'),
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

