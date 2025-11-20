import 'package:flutter/material.dart';
import '../../domain/entities/package.dart';
import '../../data/repositories/package_repository.dart';

class PackageProvider with ChangeNotifier {
  final PackageRepository _repository = PackageRepository();
  List<Package> _packages = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  // Paginación para dispositivos de 2GB RAM
  static const int _pageSize = 50; // Cargar 50 items a la vez

  List<Package> get packages => _packages;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadPackages({bool reset = true}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    // Por defecto siempre reemplazar la lista para evitar duplicados
    _hasMore = true;
    _packages.clear();

    notifyListeners();

    try {
      final newPackages = await _repository.getAllPackages();

      // Siempre reemplazar completamente para evitar duplicados
      _packages = newPackages;

      // Verificar si hay más datos
      _hasMore = newPackages.length >= _pageSize;
    } catch (e) {
      _error = 'Error al cargar paquetes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Liberar memoria cuando no se necesita
  void dispose() {
    _packages.clear();
    super.dispose();
  }

  Future<Package?> getPackageByTrackingNumber(String trackingNumber) async {
    try {
      return await _repository.getPackageByTrackingNumber(trackingNumber);
    } catch (e) {
      _error = 'Error al buscar paquete: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Package?> getPackageById(String id) async {
    try {
      return await _repository.getPackageById(id);
    } catch (e) {
      _error = 'Error al buscar paquete: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> addPackage(Package package) async {
    try {
      await _repository.insertPackage(package);
      // NO recargar la lista aquí - evita duplicados innecesarios
      // El paquete se agregó correctamente a la BD
      // Los listeners se actualizarán cuando sea necesario
    } catch (e) {
      _error = 'Error al agregar paquete: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePackage(Package package) async {
    try {
      await _repository.updatePackage(package);
      // Optimización: actualizar localmente sin recargar toda la lista
      final index = _packages.indexWhere((p) => p.id == package.id);
      if (index != -1) {
        _packages[index] = package;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al actualizar paquete: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePackage(String id) async {
    try {
      await _repository.deletePackage(id);
      // Optimización: eliminar localmente sin recargar toda la lista
      _packages.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar paquete: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Package>> searchPackages(String query) async {
    try {
      return await _repository.searchPackages(query);
    } catch (e) {
      _error = 'Error al buscar: $e';
      notifyListeners();
      return [];
    }
  }

  List<Package> getPackagesByStatus(String status) {
    return _packages.where((p) => p.status == status).toList();
  }
}
