import 'package:flutter/material.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;

  User? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  bool get isPremium => _user?.isPremium ?? false;

  Future<bool> checkAuth() async {
    final token = await ApiService.getAccessToken();
    if (token == null) return false;
    final profile = await ApiService.getProfile();
    if (profile != null && profile['user'] != null) {
      final userBase = User.fromJson(profile['user'] as Map<String, dynamic>);
      _user = userBase.copyWith(isPremium: profile['is_premium'] as bool? ?? false);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    final result = await ApiService.login(email: email, password: password);
    _loading = false;
    if (result['status'] == 200) {
      // Fetch full profile to get is_premium
      await checkAuth();
      return null;
    }
    notifyListeners();
    final data = result['data'];
    if (data is Map) {
      return data['detail']?.toString() ?? data['non_field_errors']?.toString() ?? 'Login failed';
    }
    return 'Login failed';
  }

  Future<String?> register(String email, String password, String firstName, String lastName) async {
    _loading = true;
    notifyListeners();
    final result = await ApiService.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
    _loading = false;
    if (result['status'] == 201) {
      await checkAuth();
      return null;
    }
    notifyListeners();
    final errors = result['data'];
    if (errors is Map) {
      return errors.values.first?.toString() ?? 'Registration failed';
    }
    return 'Registration failed';
  }

  Future<void> refreshPremiumStatus() async {
    final profile = await ApiService.getProfile();
    if (profile != null && _user != null) {
      _user = _user!.copyWith(isPremium: profile['is_premium'] as bool? ?? false);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.clearTokens();
    _user = null;
    notifyListeners();
  }
}
