import 'package:sqflite/sqflite.dart';
import '../../domain/entities/location.dart';
import '../datasources/database_helper.dart';

class LocationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Location>> getAllLocations() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('locations', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Location.fromMap(maps[i]));
  }

  Future<List<Location>> getAvailableLocations() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'isAvailable = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Location.fromMap(maps[i]));
  }

  Future<List<Location>> getLocationsByWarehouse(String warehouseId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'warehouseId = ?',
      whereArgs: [warehouseId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Location.fromMap(maps[i]));
  }

  Future<Location?> getLocationByCode(String code) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'name = ?',
      whereArgs: [code],
    );
    if (maps.isEmpty) return null;
    return Location.fromMap(maps.first);
  }

  Future<Location?> getLocationById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Location.fromMap(maps.first);
  }

  Future<int> insertLocation(Location location) async {
    final db = await _dbHelper.database;
    return await db.insert('locations', location.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateLocation(Location location) async {
    final db = await _dbHelper.database;
    return await db.update(
      'locations',
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  Future<int> deleteLocation(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
