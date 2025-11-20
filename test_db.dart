import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  print('🔍 Iniciando test de base de datos...');

  try {
    // Abrir la base de datos
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'paqueteria.db');

    print('📂 Ruta de BD: $path');

    final db = await openDatabase(path);

    print('✅ Base de datos abierta exitosamente');

    // Verificar si existe la tabla users
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='users'"
    );

    print('📊 Tablas encontradas: $tables');

    if (tables.isEmpty) {
      print('❌ ERROR: Tabla "users" no existe!');
      return;
    }

    print('✅ Tabla "users" existe');

    // Listar todos los usuarios
    print('\n👥 Listando todos los usuarios:');
    final allUsers = await db.query('users');
    print('Total usuarios: ${allUsers.length}');

    for (var user in allUsers) {
      print('  - ID: ${user['id']}');
      print('    Username: ${user['username']}');
      print('    Password: ${user['password']}');
      print('    Full Name: ${user['fullName']}');
      print('    Is Active: ${user['isActive']}');
      print('    Created: ${user['createdDate']}');
      print('    ---');
    }

    // Intentar autenticación con admin/admin123
    print('\n🔐 Intentando autenticación: admin/admin123');

    final authResult = await db.query(
      'users',
      where: 'username = ? AND password = ? AND isActive = 1',
      whereArgs: ['admin', 'admin123'],
    );

    if (authResult.isEmpty) {
      print('❌ AUTENTICACIÓN FALLIDA: Usuario no encontrado o inactivo');

      // Verificar si existe el usuario sin verificar contraseña
      final userExists = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: ['admin'],
      );

      if (userExists.isEmpty) {
        print('   ⚠️ El usuario "admin" NO EXISTE en la base de datos');
      } else {
        print('   ⚠️ El usuario "admin" existe pero:');
        print('      Password en BD: ${userExists.first['password']}');
        print('      Password esperado: admin123');
        print('      Is Active: ${userExists.first['isActive']}');
      }
    } else {
      print('✅ AUTENTICACIÓN EXITOSA!');
      print('   Usuario encontrado: ${authResult.first}');
    }

    await db.close();
    print('\n✅ Test completado');

  } catch (e, stackTrace) {
    print('💥 ERROR durante el test: $e');
    print('Stack trace: $stackTrace');
  }
}
