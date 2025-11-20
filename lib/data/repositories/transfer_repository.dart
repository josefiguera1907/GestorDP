import 'package:sqflite/sqflite.dart';
import '../../domain/entities/transfer.dart';
import '../datasources/database_helper.dart';

class TransferRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Transfer>> getAllTransfers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('transfers', orderBy: 'transferDate DESC');
    return List.generate(maps.length, (i) => Transfer.fromMap(maps[i]));
  }

  Future<List<Transfer>> getTransfersByPackage(String packageId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transfers',
      where: 'packageId = ?',
      whereArgs: [packageId],
      orderBy: 'transferDate DESC',
    );
    return List.generate(maps.length, (i) => Transfer.fromMap(maps[i]));
  }

  Future<int> insertTransfer(Transfer transfer) async {
    final db = await _dbHelper.database;
    return await db.insert('transfers', transfer.toMap());
  }

  Future<int> deleteTransfer(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'transfers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
