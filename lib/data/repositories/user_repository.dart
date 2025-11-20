import '../../domain/entities/user.dart';
import '../datasources/database_helper.dart';
import '../services/password_service.dart';
import '../services/rate_limiter_service.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final RateLimiterService _rateLimiter = RateLimiterService();

  // Autenticar usuario con rate limiting y verificación de contraseña hasheada
  Future<User?> authenticate(String username, String password) async {
    print('🔍 Repository: Starting authentication for: $username');

    try {
      // Verificar si el usuario está siendo rate limitado
      if (_rateLimiter.isRateLimited(username)) {
        final secondsUntilRetry = _rateLimiter.getSecondsUntilRetry(username);
        print('❌ Repository: User $username is rate limited. Retry in $secondsUntilRetry seconds');
        throw Exception('Demasiados intentos fallidos. Intenta de nuevo en $secondsUntilRetry segundos.');
      }

      print('📂 Repository: Getting database...');
      final db = await _dbHelper.database;
      print('✅ Repository: Database obtained');

      print('🔎 Repository: Querying users table by username...');
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'username = ? AND isActive = 1',
        whereArgs: [username],
      );

      print('📊 Repository: Query returned ${maps.length} results');

      if (maps.isEmpty) {
        print('❌ Repository: No matching user found');
        _rateLimiter.recordFailedAttempt(username);
        return null;
      }

      final user = maps.first;
      print('👤 Repository: User found, verifying password...');

      // Verificar contraseña usando hashing
      final storedHash = user['password'] as String;
      final isPasswordValid = PasswordService.verifyPassword(password, storedHash);

      if (!isPasswordValid) {
        print('❌ Repository: Invalid password');
        _rateLimiter.recordFailedAttempt(username);
        return null;
      }

      print('✅ Repository: Password verified');

      // Limpiar intentos fallidos si el login es exitoso
      _rateLimiter.recordSuccessfulAttempt(username);

      // Actualizar último login
      print('⏰ Repository: Updating lastLogin...');
      await db.update(
        'users',
        {'lastLogin': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [user['id']],
      );
      print('✅ Repository: lastLogin updated');

      final userObject = User.fromMap(user);
      print('✅ Repository: User object created: ${userObject.username}');
      return userObject;
    } catch (e, stackTrace) {
      print('💥 Repository: Error during authentication: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Obtener todos los usuarios
  Future<List<User>> getAllUsers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      orderBy: 'createdDate DESC',
    );

    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  // Obtener usuario por ID
  Future<User?> getUserById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // Crear usuario con contraseña hasheada
  Future<int> createUser(User user) async {
    final db = await _dbHelper.database;

    // Hash la contraseña antes de guardar
    final userMap = user.toMap();
    if (userMap['password'] != null) {
      userMap['password'] = PasswordService.hashPassword(userMap['password'] as String);
    }

    return await db.insert('users', userMap);
  }

  // Actualizar usuario
  Future<int> updateUser(User user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Eliminar usuario
  Future<int> deleteUser(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Verificar si el username ya existe
  Future<bool> usernameExists(String username, {String? excludeId}) async {
    final db = await _dbHelper.database;
    String where = 'username = ?';
    List<dynamic> whereArgs = [username];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: where,
      whereArgs: whereArgs,
    );

    return maps.isNotEmpty;
  }

  // Cambiar contraseña con hashing
  Future<int> changePassword(String userId, String newPassword) async {
    final db = await _dbHelper.database;
    final hashedPassword = PasswordService.hashPassword(newPassword);
    return await db.update(
      'users',
      {'password': hashedPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Activar/Desactivar usuario
  Future<int> toggleUserStatus(String userId, bool isActive) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
