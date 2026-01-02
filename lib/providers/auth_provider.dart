import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../utils/boxes.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _currentUserEmail;
  UserModel? _currentUser;
  String _profileBio = '';
  int? _accentColorValue;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserEmail => _currentUserEmail;
  UserModel? get currentUser => _currentUser;
  String get profileBio => _profileBio;
  int? get accentColorValue => _accentColorValue;

  Future<void> init() async {
    final box = await Hive.openBox(HiveBoxes.user);
    _isAuthenticated = box.get('isAuthenticated', defaultValue: false);
    _currentUserEmail = box.get('email');

    if (_isAuthenticated && _currentUserEmail != null) {
      _loadCurrentUser(_currentUserEmail!);
      _loadProfileExtras(_currentUserEmail!);
    }

    notifyListeners();
  }

  void _loadCurrentUser(String email) {
    final userBox = Hive.box<UserModel>(HiveBoxes.userProfiles);
    _currentUser = userBox.get(email);
  }

  void _loadProfileExtras(String email) {
    final box = Hive.box(HiveBoxes.user);
    _profileBio = box.get('profileBio_$email', defaultValue: '') as String;
    _accentColorValue = box.get('profileColor_$email') as int?;
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
    _loadProfileExtras(email);

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
    _loadProfileExtras(email);

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

  Future<void> updateProfile({
    String? username,
    String? bio,
    int? accentColorValue,
  }) async {
    final email = _currentUserEmail;
    if (email == null) return;

    if (_currentUser != null && username != null) {
      _currentUser!.username = username.trim();
      await _currentUser!.save();
    }

    final box = Hive.box(HiveBoxes.user);
    if (bio != null) {
      _profileBio = bio.trim();
      await box.put('profileBio_$email', _profileBio);
    }

    if (accentColorValue != null) {
      _accentColorValue = accentColorValue;
      await box.put('profileColor_$email', accentColorValue);
    }

    notifyListeners();
  }
}
