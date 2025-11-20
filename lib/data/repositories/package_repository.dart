import 'package:sqflite/sqflite.dart';
import '../../domain/entities/package.dart';
import '../datasources/database_helper.dart';

class PackageRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Package>> getAllPackages({int? limit, int? offset}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'packages',
      orderBy: 'registeredDate DESC',
      limit: limit ?? 100, // Límite por defecto para 2GB RAM
      offset: offset,
    );
    return List.generate(maps.length, (i) => Package.fromMap(maps[i]));
  }

  Future<Package?> getPackageByTrackingNumber(String trackingNumber) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'packages',
      where: 'trackingNumber = ?',
      whereArgs: [trackingNumber],
    );
    if (maps.isEmpty) return null;
    return Package.fromMap(maps.first);
  }

  Future<Package?> getPackageById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'packages',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Package.fromMap(maps.first);
  }

  Future<List<Package>> getPackagesByStatus(String status, {int? limit}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'packages',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'registeredDate DESC',
      limit: limit ?? 50, // Límite por defecto para filtros
    );
    return List.generate(maps.length, (i) => Package.fromMap(maps[i]));
  }

  Future<List<Package>> getPackagesByLocation(String locationId, {int? limit}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'packages',
      where: 'locationId = ?',
      whereArgs: [locationId],
      orderBy: 'registeredDate DESC',
      limit: limit ?? 50, // Límite por defecto para filtros
    );
    return List.generate(maps.length, (i) => Package.fromMap(maps[i]));
  }

  Future<int> insertPackage(Package package) async {
    final db = await _dbHelper.database;
    // No usar ConflictAlgorithm.replace para evitar duplicados
    // Si el tracking number es único (UNIQUE constraint), SQLite lanzará una excepción
    // Esto es mejor para detectar duplicados en lugar de silenciosamente reemplazarlos
    return await db.insert('packages', package.toMap());
  }

  Future<int> updatePackage(Package package) async {
    final db = await _dbHelper.database;
    return await db.update(
      'packages',
      package.toMap(),
      where: 'id = ?',
      whereArgs: [package.id],
    );
  }

  Future<int> deletePackage(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'packages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Búsqueda optimizada de paquetes
  /// Busca primero por exactitud, luego por similitud para mejor rendimiento
  Future<List<Package>> searchPackages(String query, {int? limit}) async {
    if (query.isEmpty) {
      return [];
    }

    final db = await _dbHelper.database;
    final searchLimit = limit ?? 50;
    final trimmedQuery = query.trim();

    try {
      // Primero intentar búsqueda exacta (más rápido)
      final exactMatches = await db.query(
        'packages',
        where: 'trackingNumber = ? OR recipientName = ? OR senderName = ?',
        whereArgs: [trimmedQuery, trimmedQuery, trimmedQuery],
        orderBy: 'registeredDate DESC',
        limit: searchLimit,
      );

      if (exactMatches.isNotEmpty) {
        return List.generate(
          exactMatches.length,
          (i) => Package.fromMap(exactMatches[i]),
        );
      }

      // Si no hay coincidencias exactas, hacer búsqueda por prefijo (más rápido que LIKE %value%)
      final prefixQuery = '$trimmedQuery%';
      final prefixMatches = await db.query(
        'packages',
        where: 'trackingNumber LIKE ? OR recipientName LIKE ? OR senderName LIKE ?',
        whereArgs: [prefixQuery, prefixQuery, prefixQuery],
        orderBy: 'registeredDate DESC',
        limit: searchLimit,
      );

      if (prefixMatches.isNotEmpty) {
        return List.generate(
          prefixMatches.length,
          (i) => Package.fromMap(prefixMatches[i]),
        );
      }

      // Si aún no hay resultados, hacer búsqueda con wildcard completo (menos eficiente)
      final wildcardQuery = '%$trimmedQuery%';
      final wildcardMatches = await db.query(
        'packages',
        where: 'trackingNumber LIKE ? OR recipientName LIKE ? OR senderName LIKE ? OR recipientPhone LIKE ?',
        whereArgs: [wildcardQuery, wildcardQuery, wildcardQuery, wildcardQuery],
        orderBy: 'registeredDate DESC',
        limit: searchLimit,
      );

      return List.generate(
        wildcardMatches.length,
        (i) => Package.fromMap(wildcardMatches[i]),
      );
    } catch (e) {
      print('Error searching packages: $e');
      return [];
    }
  }
}
