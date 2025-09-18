import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos_rp/models/user_model.dart';
import 'package:pos_rp/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  Future<void>? _initFuture;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  /// A future that completes when the user's session has been loaded.
  Future<void>? get isReady => _initFuture;

  AuthProvider() {
    _initFuture = _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('loggedInUserId');
    if (userId != null) {
      _currentUser = await DatabaseHelper.instance.readUser(userId);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final user = await DatabaseHelper.instance.readUserByEmail(email);

    _isLoading = false;
    if (user != null && user.password == password) {
      // In real app, check hashed password
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('loggedInUserId', user.id);
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final existingUser = await DatabaseHelper.instance.readUserByEmail(email);
    if (existingUser != null) {
      _isLoading = false;
      notifyListeners();
      return false; // User already exists
    }

    final newUser = User(
      id: const Uuid().v4(),
      name: name,
      email: email,
      password: password, // Should be hashed
    );

    await DatabaseHelper.instance.createUser(newUser);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> updateUserProfile(User updatedUser) async {
    await DatabaseHelper.instance.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUserId');
    notifyListeners();
  }

  Future<void> updateUserImage(File imageFile) async {
    if (_currentUser == null) return;
    // Logic to save file and get path is in ProfileScreen, here we just update the model
    final updatedUser = User(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      password: _currentUser!.password,
      imagePath: imageFile.path,
    );
    await updateUserProfile(updatedUser);
  }
}
