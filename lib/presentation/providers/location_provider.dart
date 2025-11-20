import 'package:flutter/material.dart';
import '../../domain/entities/location.dart';
import '../../data/repositories/location_repository.dart';

class LocationProvider with ChangeNotifier {
  final LocationRepository _repository = LocationRepository();
  List<Location> _locations = [];
  bool _isLoading = false;
  String? _error;

  List<Location> get locations => _locations;
  List<Location> get availableLocations => _locations.where((l) => l.isAvailable).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLocations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _locations = await _repository.getAllLocations();
    } catch (e) {
      _error = 'Error al cargar ubicaciones: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Location?> getLocationByCode(String code) async {
    try {
      return await _repository.getLocationByCode(code);
    } catch (e) {
      _error = 'Error al buscar ubicación: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> addLocation(Location location) async {
    try {
      final id = await _repository.insertLocation(location);
      // Recargar desde la BD para obtener el ID generado y datos completos
      await loadLocations();
    } catch (e) {
      _error = 'Error al agregar ubicación: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateLocation(Location location) async {
    try {
      await _repository.updateLocation(location);
      // Optimización: actualizar localmente sin recargar toda la lista
      final index = _locations.indexWhere((l) => l.id == location.id);
      if (index != -1) {
        _locations[index] = location;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al actualizar ubicación: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      await _repository.deleteLocation(id);
      // Optimización: eliminar localmente sin recargar toda la lista
      _locations.removeWhere((l) => l.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar ubicación: $e';
      notifyListeners();
      rethrow;
    }
  }
}
