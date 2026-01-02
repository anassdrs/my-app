import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../utils/boxes.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentUserEmail;
  UserModel? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserEmail => _currentUserEmail;
  UserModel? get currentUser => _currentUser;

  Future<void> init() async {
    final box = await Hive.openBox(HiveBoxes.user);
    _isAuthenticated = box.get('isAuthenticated', defaultValue: false);
    _currentUserEmail = box.get('email');

    if (_isAuthenticated && _currentUserEmail != null) {
      _loadCurrentUser(_currentUserEmail!);
    }

    notifyListeners();
  }

  void _loadCurrentUser(String email) {
    final userBox = Hive.box<UserModel>(HiveBoxes.userProfiles);
    _currentUser = userBox.get(email);
  }

  Future<String?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network

    if (!_isValidEmail(email)) {
      return "Invalid email format";
    }

    final userBox = Hive.box<UserModel>(HiveBoxes.userProfiles);
    final user = userBox.get(email);

    if (user == null) {
      return "User not found";
    }

    if (user.password != password) {
      return "Incorrect password";
    }

    final box = Hive.box(HiveBoxes.user);
    await box.put('isAuthenticated', true);
    await box.put('email', email);

    _isAuthenticated = true;
    _currentUserEmail = email;
    _currentUser = user;

    notifyListeners();
    return null; // Success
  }

  Future<String?> register(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network

    if (!_isValidEmail(email)) {
      return "Invalid email format";
    }

    if (password.length < 6) {
      return "Password must be at least 6 characters";
    }

    final userBox = Hive.box<UserModel>(HiveBoxes.userProfiles);

    if (userBox.containsKey(email)) {
      return "User already exists";
    }

    final newUser = UserModel(
      email: email,
      password: password,
      username: email.split('@')[0],
    );

    await userBox.put(email, newUser);

    final box = Hive.box(HiveBoxes.user);
    await box.put('isAuthenticated', true);
    await box.put('email', email);

    _isAuthenticated = true;
    _currentUserEmail = email;
    _currentUser = newUser;

    notifyListeners();
    return null; // Success
  }

  void addExperience(int amount) {
    if (_currentUser != null) {
      int oldLevel = _currentUser!.level;
      _currentUser!.addXp(amount);
      _currentUser!.save();

      if (_currentUser!.level > oldLevel) {
        notifyListeners();
      }

      notifyListeners();
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<void> logout() async {
    final box = Hive.box(HiveBoxes.user);
    await box.put('isAuthenticated', false);
    _isAuthenticated = false;
    _currentUserEmail = null;
    notifyListeners();
  }
}
