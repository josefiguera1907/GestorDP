import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../data/repositories/user_repository.dart';

class AuthProvider with ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _hasCheckedSession = false; // Flag para evitar múltiples checks

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Verificar si hay sesión guardada
  Future<void> checkSession() async {
    // Evitar múltiples llamadas
    if (_hasCheckedSession) {
      print('⚠️ Session already checked, skipping...');
      return;
    }

    print('🔍 Checking session...');
    _hasCheckedSession = true;
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');

      if (userId != null) {
        final user = await _userRepository.getUserById(userId);
        if (user != null && user.isActive) {
          _currentUser = user;
          _isAuthenticated = true;
        } else {
          await logout();
        }
      }
    } catch (e) {
      print('Error checking session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    print('🔐 Login attempt: $username');
    // NO cambiar _isLoading aquí para evitar que MaterialApp.home cambie
    // El LoginScreen maneja su propio estado de loading

    try {
      print('📞 Calling authenticate...');
      final user = await _userRepository.authenticate(username, password);
      print('👤 User result: ${user?.username ?? "null"}');

      if (user != null) {
        print('👤 User ID: ${user.id}');
        print('👤 User isActive: ${user.isActive}');

        if (user.id == null) {
          print('❌ Error: User has no ID');
          return false;
        }

        _currentUser = user;
        final oldAuth = _isAuthenticated;
        _isAuthenticated = true;

        // Guardar sesión
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_id', user.id!);
        print('💾 Session saved with user ID: ${user.id}');

        print('🔔 ANTES notifyListeners: _isAuthenticated=$_isAuthenticated (era $oldAuth)');
        notifyListeners(); // Notificar que ya estamos autenticados
        print('✅ DESPUÉS notifyListeners');
        print('✅ Login successful! isAuthenticated=${_isAuthenticated}');
        return true;
      }

      print('❌ Authentication failed - user is null');
      return false;
    } catch (e, stackTrace) {
      print('💥 Error during login: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    _hasCheckedSession = false; // Permitir verificar sesión de nuevo después de logout

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');

    notifyListeners();
  }

  // Actualizar usuario actual (después de editar perfil)
  Future<void> refreshCurrentUser() async {
    if (_currentUser != null) {
      final user = await _userRepository.getUserById(_currentUser!.id!);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    }
  }
}
