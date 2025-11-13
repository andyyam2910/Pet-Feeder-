import 'package:crud_pet_feeder/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'inicio_page.dart';
import 'login_page.dart';

// Este Widget es la "puerta" de la aplicación.
// Escucha al AuthService y decide qué página mostrar.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    //  context.watch para "escuchar" los cambios en AuthService
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoggedIn) {
      // Si el usuario está logueado, va a la página de Inicio
      return const InicioPage();
    } else {
      // Si no, va a la página de Login
      return const LoginPage();
    }
  }
}
