import 'package:flutter/foundation.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';
import '../services/api_config.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._repository);

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> login(String username, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _repository.login(username, password);
      // Store token in ApiConfig
      if (_user?.token != null) {
        await ApiConfig.setAuthToken(_user!.token!);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
      // Clear token from ApiConfig
      await ApiConfig.removeAuthToken();
      _user = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final hasToken = await ApiConfig.hasToken();
      if (hasToken) {
        await refreshToken();
      } else {
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      await logout();
    }
  }

  Future<void> refreshToken() async {
    try {
      if (_user?.refreshToken != null) {
        final newUser = await _repository.refreshToken(_user!.refreshToken!);
        _user = newUser;
        if (_user?.token != null) {
          await ApiConfig.setAuthToken(_user!.token!);
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      await logout();
      notifyListeners();
      throw e;
    }
  }

  // Add register method
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.register(
        username: username,
        email: email,
        password: password,
        role: role,
        firstName: firstName,
        lastName: lastName,
      );

      // Automatically login after successful registration
      await login(username, password);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
