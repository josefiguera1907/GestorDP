import 'dart:async';
import 'dart:io';

/// Gestor de memoria para dispositivos de 2GB RAM
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  Timer? _cleanupTimer;
  final _cleanupCallbacks = <void Function()>[];

  /// Iniciar monitoreo de memoria
  void startMonitoring() {
    // Limpiar cada 5 minutos
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performCleanup();
    });
  }

  /// Detener monitoreo
  void stopMonitoring() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// Registrar callback de limpieza
  void registerCleanupCallback(void Function() callback) {
    _cleanupCallbacks.add(callback);
  }

  /// Remover callback de limpieza
  void unregisterCleanupCallback(void Function() callback) {
    _cleanupCallbacks.remove(callback);
  }

  /// Forzar limpieza de memoria
  Future<void> forceCleanup() async {
    _performCleanup();
  }

  void _performCleanup() {
    // Ejecutar callbacks de limpieza
    for (final callback in _cleanupCallbacks) {
      try {
        callback();
      } catch (e) {
        // Silenciar errores de limpieza
      }
    }

    // Sugerir recolección de basura
    if (Platform.isAndroid || Platform.isIOS) {
      // La VM de Dart manejará esto automáticamente
    }
  }

  /// Obtener información de memoria (solo debug)
  Map<String, dynamic> getMemoryInfo() {
    return {
      'cleanup_callbacks': _cleanupCallbacks.length,
      'monitoring': _cleanupTimer?.isActive ?? false,
    };
  }

  void dispose() {
    stopMonitoring();
    _cleanupCallbacks.clear();
  }
}
