import 'package:crud_pet_feeder/services/auth_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitLogin() async {
    // Mostrar indicador de carga
    setState(() { _isLoading = true; });

    // Obtener el servicio (sin escuchar cambios aquí)
    final authService = Provider.of<AuthService>(context, listen: false);

    // Llamar a la función de login
    await authService.signInWithEmail(
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() { _isLoading = false; });
    }

    // Manejar errores (si el login falló, authService.errorMessage tendrá un valor)
    if (authService.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
    // Si el login es exitoso, el AuthWrapper nos moverá a InicioPage automáticamente.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView( // Para evitar overflow si el teclado aparece
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, size: 80, color: Colors.blue[700]),
              const SizedBox(height: 20),
              const Text(
                'Bienvenido a Pet Feeder+',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              // Campo de Usuario
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Correo electrónico",
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Contraseña",
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Botón de Login
              _isLoading
                  ? const CircularProgressIndicator() // Muestra carga
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _submitLogin,
                      child: const Text('Iniciar Sesión'),
                    ),
              
              const SizedBox(height: 20),
              
              // Botón para ir a Registro
              TextButton(
                onPressed: () {
                  // Navega a la página de registro
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('¿No tienes cuenta? Regístrate aquí'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

