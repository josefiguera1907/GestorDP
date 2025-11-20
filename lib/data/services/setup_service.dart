import '../datasources/database_helper.dart';
import '../repositories/user_repository.dart';
import '../../domain/entities/user.dart';

class SetupService {
  static final SetupService _instance = SetupService._internal();

  factory SetupService() => _instance;

  SetupService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final UserRepository _userRepository = UserRepository();

  /// Verifica si la aplicación necesita setup inicial (no hay usuarios)
  Future<bool> isFirstTimeSetup() async {
    try {
      final users = await _userRepository.getAllUsers();
      return users.isEmpty;
    } catch (e) {
      print('Error verificando setup: $e');
      return true; // Asumir que es primera vez si hay error
    }
  }

  /// Crea el usuario administrador inicial
  Future<User?> createInitialAdmin({
    required String username,
    required String password,
    required String fullName,
    String? email,
  }) async {
    try {
      final user = User(
        username: username,
        password: password,
        fullName: fullName,
        email: email,
        isActive: true,
        createdDate: DateTime.now(),
        lastLogin: null,
        canManageUsers: true,
        canManageWarehouses: true,
        canManageLocations: true,
        canManagePackages: true,
        canDeletePackages: true,
        canScanQR: true,
        canSendMessages: true,
        canConfigureSystem: true,
        canBackupRestore: true,
      );

      await _userRepository.createUser(user);

      // Obtener el usuario nuevamente para obtener el ID generado
      final allUsers = await _userRepository.getAllUsers();
      final createdUser = allUsers.firstWhere(
        (u) => u.username == username,
        orElse: () => throw Exception('Usuario no encontrado después de crear'),
      );
      print('✅ Usuario admin inicial creado exitosamente con ID: ${createdUser.id}');
      return createdUser;
    } catch (e) {
      print('❌ Error creando usuario admin inicial: $e');
      rethrow;
    }
  }

  /// Obtiene el número de usuarios en el sistema
  Future<int> getUserCount() async {
    try {
      final users = await _userRepository.getAllUsers();
      return users.length;
    } catch (e) {
      return 0;
    }
  }
}
