import 'package:sqflite/sqflite.dart';
import '../../domain/entities/warehouse.dart';
import '../datasources/database_helper.dart';

class WarehouseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Warehouse>> getAllWarehouses() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('warehouses', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Warehouse.fromMap(maps[i]));
  }

  Future<List<Warehouse>> getActiveWarehouses() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'warehouses',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Warehouse.fromMap(maps[i]));
  }

  Future<Warehouse?> getWarehouseById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'warehouses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Warehouse.fromMap(maps.first);
  }

  Future<int> insertWarehouse(Warehouse warehouse) async {
    final db = await _dbHelper.database;
    return await db.insert('warehouses', warehouse.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateWarehouse(Warehouse warehouse) async {
    final db = await _dbHelper.database;
    return await db.update(
      'warehouses',
      warehouse.toMap(),
      where: 'id = ?',
      whereArgs: [warehouse.id],
    );
  }

  Future<int> deleteWarehouse(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'warehouses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
