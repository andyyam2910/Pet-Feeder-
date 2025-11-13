import 'package:crud_pet_feeder/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  // Estado para el toggle de notificaciones
  bool _notificacionesEnabled = true;

  // --- Diálogo de confirmación para Cerrar Sesión ---
  void _showLogoutConfirmation(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cerrar Sesión'),
              onPressed: () {
                // Cerramos el diálogo y llamamos al servicio de auth
                Navigator.of(dialogContext).pop();
                authService.signOut();
                
                // Navegamos de vuelta al inicio (que mostrará el login)
                // Usamos 'pushAndRemoveUntil' para limpiar el historial de navegación
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el authService (sin escuchar)
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes y Configuración'),
      ),
      body: ListView(
        children: [
          // --- Sección de Cuenta ---
          const ListTile(
            title: Text('Cuenta', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Correo Electrónico'),
            subtitle: Text(authService.user?.email ?? 'No disponible'),
            onTap: () {
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              _showLogoutConfirmation(context, authService);
            },
          ),

          const Divider(),

          // --- Sección de Notificaciones ---
          const ListTile(
            title: Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Activar notificaciones'),
            subtitle: const Text('Recibir alertas de comida dispensada'),
            value: _notificacionesEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificacionesEnabled = value;
              });
            },
          ),

          const Divider(),

          // --- Sección de Ayuda ---
          const ListTile(
            title: Text('Ayuda', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Soporte Técnico'),
            onTap: () {
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Preguntas Frecuentes (FAQs)'),
            onTap: () {
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de Pet Feeder+'),
            subtitle: const Text('Versión 1.0.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}