import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 


class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String? _errorMessage; 


  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get errorMessage => _errorMessage; 

  AuthService() {

    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Manejador interno para cambios de estado
  void _onAuthStateChanged(User? user) {
    _user = user;
    _errorMessage = null; 
    notifyListeners();
  }

  // Función de INICIO DE SESIÓN
  Future<void> signInWithEmail(String email, String password) async {
    try {
      _errorMessage = null;
      notifyListeners(); // Limpiar errores en UI
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Manejo de errores comunes
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        _errorMessage = 'Usuario o contraseña incorrectos.';
      } else {
        _errorMessage = 'Error: ${e.message}';
      }
      debugPrint(_errorMessage);
      notifyListeners(); 
    }
  }

  // Función de REGISTRO
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      _errorMessage = null;
      notifyListeners(); 
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _errorMessage = 'La contraseña es muy débil (6 caracteres min).';
      } else if (e.code == 'email-already-in-use') {
        _errorMessage = 'El correo ya está en uso.';
      } else {
        _errorMessage = 'Error: ${e.message}';
      }
      debugPrint(_errorMessage);
      notifyListeners(); 
    }
  }

  // Función de CERRAR SESIÓN
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

