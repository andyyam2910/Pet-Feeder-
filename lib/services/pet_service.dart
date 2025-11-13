import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crud_pet_feeder/models/pet.dart';
import 'package:crud_pet_feeder/services/auth_services.dart';
import 'package:flutter/material.dart';

/*
 * Servicio para manejar el CRUD de Mascotas (Pets)
 * Se conecta a la sub-colección /users/{userId}/pets
 */
class PetService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService? _authService;

  Stream<List<Pet>>? _petsStream;

  PetService(this._authService) {

    if (_authService?.user != null) {
      _initPetsStream(_authService!.user!.uid);
    }


    _authService?.addListener(_onAuthChanged);
  }


  Stream<List<Pet>>? get petsStream => _petsStream;

  
  void _onAuthChanged() {
    final user = _authService?.user;
    if (user != null) {
      _initPetsStream(user.uid);
    } else {
      _petsStream = null;
    }
    notifyListeners();
  }

  void _initPetsStream(String userId) {
    final path = 'users/$userId/pets';
    _petsStream = _firestore.collection(path).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Pet.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  String? get _userId => _authService?.user?.uid;

  Future<void> addPet(Pet pet) async {
    if (_userId == null) return;
    final path = 'users/$_userId/pets';
    await _firestore.collection(path).add(pet.toMap());
  }

  Future<void> updatePet(Pet pet) async {
    if (_userId == null || pet.id.isEmpty) return;
    final path = 'users/$_userId/pets';
    await _firestore.collection(path).doc(pet.id).update(pet.toMap());
  }

  Future<void> deletePet(String petId) async {
    if (_userId == null) return;
    final path = 'users/$_userId/pets';
    await _firestore.collection(path).doc(petId).delete();
  }

  @override
  void dispose() {
    _authService?.removeListener(_onAuthChanged);
    super.dispose();
  }
}