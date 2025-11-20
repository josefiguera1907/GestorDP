import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../data/repositories/user_repository.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _repository = UserRepository();

  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  // Cargar todos los usuarios
  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await _repository.getAllUsers();
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Crear usuario
  Future<bool> createUser(User user) async {
    try {
      // Verificar si el username ya existe
      final exists = await _repository.usernameExists(user.username);
      if (exists) {
        return false;
      }

      await _repository.createUser(user);
      // Optimización: agregar localmente sin recargar toda la lista
      _users.add(user);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  // Actualizar usuario
  Future<bool> updateUser(User user) async {
    try {
      // Verificar si el username ya existe (excluyendo el usuario actual)
      final exists = await _repository.usernameExists(
        user.username,
        excludeId: user.id,
      );
      if (exists) {
        return false;
      }

      await _repository.updateUser(user);
      // Optimización: actualizar localmente sin recargar toda la lista
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
        notifyListeners();
      }
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Eliminar usuario
  Future<void> deleteUser(String id) async {
    try {
      await _repository.deleteUser(id);
      // Optimización: eliminar localmente sin recargar toda la lista
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  // Cambiar contraseña
  Future<void> changePassword(String userId, String newPassword) async {
    try {
      await _repository.changePassword(userId, newPassword);
      // Optimización: actualizar localmente el usuario
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(password: newPassword);
        notifyListeners();
      }
    } catch (e) {
      print('Error changing password: $e');
    }
  }

  // Activar/Desactivar usuario
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _repository.toggleUserStatus(userId, isActive);
      // Optimización: actualizar localmente el usuario
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(isActive: isActive);
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling user status: $e');
    }
  }

  // Obtener usuario por ID
  Future<User?> getUserById(String id) async {
    try {
      return await _repository.getUserById(id);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
}
