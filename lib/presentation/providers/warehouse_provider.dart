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
      // Set first warehouse as selected if none selected
      if (_selectedWarehouse == null && _warehouses.isNotEmpty) {
        _selectedWarehouse = _warehouses.first;
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
      // Optimización: agregar localmente sin recargar toda la lista
      _warehouses.add(warehouse);
      // Set as selected if none selected
      if (_selectedWarehouse == null) {
        _selectedWarehouse = warehouse;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error al agregar almacén: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateWarehouse(Warehouse warehouse) async {
    try {
      await _repository.updateWarehouse(warehouse);
      // Optimización: actualizar localmente sin recargar toda la lista
      final index = _warehouses.indexWhere((w) => w.id == warehouse.id);
      if (index != -1) {
        _warehouses[index] = warehouse;
        // Update selected warehouse if it's the one being updated
        if (_selectedWarehouse?.id == warehouse.id) {
          _selectedWarehouse = warehouse;
        }
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al actualizar almacén: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteWarehouse(String id) async {
    try {
      await _repository.deleteWarehouse(id);
      // Clear selected warehouse if it's the one being deleted
      if (_selectedWarehouse?.id == id) {
        _selectedWarehouse = null;
      }
      // Optimización: eliminar localmente sin recargar toda la lista
      _warehouses.removeWhere((w) => w.id == id);
      // Set first warehouse as selected if none selected and list not empty
      if (_selectedWarehouse == null && _warehouses.isNotEmpty) {
        _selectedWarehouse = _warehouses.first;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar almacén: $e';
      notifyListeners();
      rethrow;
    }
  }
}
