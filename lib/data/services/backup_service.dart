import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../datasources/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Exporta todos los datos de la aplicación a un archivo JSON
  /// Guarda en la carpeta de Downloads del dispositivo
  Future<File> exportData() async {
    final db = await _dbHelper.database;

    // Obtener todos los datos de las tablas
    final warehouses = await db.query('warehouses');
    final locations = await db.query('locations');
    final packages = await db.query('packages');
    final transfers = await db.query('transfers');
    final users = await db.query('users');

    // Crear estructura de backup
    final backupData = {
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      'data': {
        'warehouses': warehouses,
        'locations': locations,
        'packages': packages,
        'transfers': transfers,
        'users': users,
      },
    };

    // Convertir a JSON
    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

    // Guardar archivo en Downloads (Android)
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'backup_paqueteria_$timestamp.json';

    // Intentar guardar en Downloads primero
    Directory? directory;
    try {
      // En Android, intentar acceder a Downloads
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Si no existe, usar descargas públicas
        directory = await getExternalStorageDirectory();
      }
    } catch (e) {
      // Si falla, usar directorio de la app
      directory = await getApplicationDocumentsDirectory();
    }

    final file = File('${directory!.path}/$fileName');
    await file.writeAsString(jsonString);

    return file;
  }

  /// Importa datos desde un archivo JSON
  Future<void> importData(String filePath) async {
    // Leer archivo
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('El archivo no existe');
    }

    final jsonString = await file.readAsString();
    final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

    // Validar versión
    final version = backupData['version'] as int?;
    if (version == null || version != 1) {
      throw Exception('Versión de backup no compatible');
    }

    final data = backupData['data'] as Map<String, dynamic>;
    final db = await _dbHelper.database;

    // Iniciar transacción para asegurar consistencia
    await db.transaction((txn) async {
      // Limpiar tablas existentes (en orden inverso por las foreign keys)
      await txn.delete('transfers');
      await txn.delete('packages');
      await txn.delete('locations');
      await txn.delete('warehouses');
      await txn.delete('users');

      // Importar warehouses
      final warehouses = data['warehouses'] as List<dynamic>;
      for (var warehouse in warehouses) {
        await txn.insert('warehouses', warehouse as Map<String, dynamic>);
      }

      // Importar locations
      final locations = data['locations'] as List<dynamic>;
      for (var location in locations) {
        await txn.insert('locations', location as Map<String, dynamic>);
      }

      // Importar users
      final users = data['users'] as List<dynamic>;
      for (var user in users) {
        await txn.insert('users', user as Map<String, dynamic>);
      }

      // Importar packages
      final packages = data['packages'] as List<dynamic>;
      for (var package in packages) {
        await txn.insert('packages', package as Map<String, dynamic>);
      }

      // Importar transfers
      final transfers = data['transfers'] as List<dynamic>;
      for (var transfer in transfers) {
        await txn.insert('transfers', transfer as Map<String, dynamic>);
      }
    });
  }

  /// Obtiene la ruta del directorio de documentos
  Future<String> getDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Lista los archivos de backup disponibles
  Future<List<File>> listBackupFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);

    if (!await dir.exists()) {
      return [];
    }

    final files = dir.listSync()
        .where((item) => item is File && item.path.contains('backup_paqueteria'))
        .map((item) => item as File)
        .toList();

    // Ordenar por fecha de modificación (más reciente primero)
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return files;
  }
}
