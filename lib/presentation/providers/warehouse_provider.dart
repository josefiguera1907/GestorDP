import 'package:flutter/material.dart';
import '../../domain/entities/warehouse.dart';
import '../../data/repositories/warehouse_repository.dart';

class WarehouseProvider with ChangeNotifier {
  final WarehouseRepository _repository = WarehouseRepository();
  List<Warehouse> _warehouses = [];
  Warehouse? _selectedWarehouse;
  bool _isLoading = false;
  String? _error;

  List<Warehouse> get warehouses => _warehouses;
  List<Warehouse> get activeWarehouses => _warehouses.where((w) => w.isActive).toList();
  Warehouse? get selectedWarehouse => _selectedWarehouse;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWarehouses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _warehouses = await _repository.getAllWarehouses();
      // No seleccionar automáticamente un almacén; esperar a que el usuario lo seleccione explícitamente
      // Solo mantener seleccionado si ya había uno seleccionado previamente
      if (_warehouses.isNotEmpty && _selectedWarehouse != null) {
        // Verificar que el almacén seleccionado aún exista
        final exists = _warehouses.any((w) => w.id == _selectedWarehouse!.id);
        if (!exists) {
          _selectedWarehouse = null;
        }
      } else if (_warehouses.isEmpty) {
        _selectedWarehouse = null;
      }
    } catch (e) {
      _error = 'Error al cargar almacenes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectWarehouse(Warehouse warehouse) {
    _selectedWarehouse = warehouse;
    notifyListeners();
  }

  Future<void> addWarehouse(Warehouse warehouse) async {
    try {
      await _repository.insertWarehouse(warehouse);
      // Reload all warehouses to ensure consistency with database
      await loadWarehouses();
    } catch (e) {
      _error = 'Error al agregar almacén: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateWarehouse(Warehouse warehouse) async {
    try {
      await _repository.updateWarehouse(warehouse);
      // Reload all warehouses to ensure consistency with database
      await loadWarehouses();
    } catch (e) {
      _error = 'Error al actualizar almacén: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteWarehouse(String id) async {
    try {
      await _repository.deleteWarehouse(id);
      // Reload all warehouses to ensure consistency with database
      await loadWarehouses();
    } catch (e) {
      _error = 'Error al eliminar almacén: $e';
      notifyListeners();
      rethrow;
    }
  }
}
