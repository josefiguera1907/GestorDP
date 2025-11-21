import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Gestor de memoria optimizado para dispositivos de 1GB RAM
class MemoryManager {
  static const int LOW_MEMORY_THRESHOLD = 300; // MB
  static const int VERY_LOW_MEMORY_THRESHOLD = 150; // MB
  static const int MEMORY_POLL_INTERVAL = 15000; // 15 segundos
  static const int CACHE_CLEANUP_THRESHOLD = 50; // Elementos antes de limpiar

  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  Timer? _cleanupTimer;
  Timer? _memoryMonitorTimer;
  final _cleanupCallbacks = <void Function()>[];
  int _cacheItemCount = 0; // Contador para optimizar el uso de cache

  /// Parámetros de optimización para dispositivos bajos recursos
  static const Map<String, dynamic> resourceLimits = {
    'max_cached_images': 5,
    'max_list_items_before_pagination': 10,
    'auto_refresh_interval': 120000, // 2 minutos en lugar de 30 seg
    'image_quality': 30, // Calidad reducida para bajo consumo
    'batch_size': 5, // Tamaño de lote reducido para procesamiento
  };

  /// Verifica si el dispositivo tiene poca memoria
  bool get isLowMemoryDevice {
    return true; // Consideramos todos los dispositivos como potencialmente bajos recursos
  }

  /// Iniciar monitoreo de memoria
  void startMonitoring() {
    // Monitoreo más frecuente para dispositivos de baja memoria
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = Timer.periodic(
      Duration(milliseconds: MEMORY_POLL_INTERVAL),
      _checkMemoryUsage,
    );

    // Programar limpiezas más frecuentes
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _performCleanup();
    });

    if (kDebugMode) {
      print('📱 Monitor de memoria iniciado (optimizado para 1GB RAM)');
    }
  }

  /// Verifica el uso de memoria y aplica optimizaciones
  void _checkMemoryUsage(Timer timer) {
    // En dispositivos móviles, usamos estimaciones para determinar uso de memoria
    final estimatedUsage = _estimateMemoryUsage();

    if (estimatedUsage > LOW_MEMORY_THRESHOLD) {
      _applyOptimizations();
    } else if (estimatedUsage > VERY_LOW_MEMORY_THRESHOLD) {
      _applyAggressiveOptimizations();
    }
  }

  /// Estima el uso de memoria basado en elementos cacheados
  int _estimateMemoryUsage() {
    // Estimación basada en el tamaño aproximado de objetos en memoria
    return (5 + (_cacheItemCount * 0.3)).round(); // Aproximación en MB
  }

  /// Aplica optimizaciones básicas
  void _applyOptimizations() {
    if (kDebugMode) {
      print('📉 Aplicando optimizaciones básicas (Memoria estimada: ~${_estimateMemoryUsage()}MB)');
    }

    // Reduce calidad de imágenes
    // Limpia caches ligeros
    _cleanupLightCache();
  }

  /// Aplica optimizaciones agresivas
  void _applyAggressiveOptimizations() {
    if (kDebugMode) {
      print('⚠️ Aplicando optimizaciones agresivas (Memoria baja estimada: ~${_estimateMemoryUsage()}MB)');
    }

    // Limpia caches pesadas
    _cleanupHeavyCache();

    // Reduce tamaño de listas
    // resourceLimits['max_list_items_before_pagination'] = 5;

    // Deshabilita animaciones si es posible
    _disableResourceIntensiveFeatures();
  }

  /// Limpia caches livianas
  void _cleanupLightCache() {
    _cacheItemCount = _cacheItemCount ~/ 2; // Reduce cache a la mitad
  }

  /// Limpia caches pesadas
  void _cleanupHeavyCache() {
    _cacheItemCount = _cacheItemCount ~/ 3; // Reduce cache a 1/3
  }

  /// Deshabilita características intensivas en recursos
  void _disableResourceIntensiveFeatures() {
    // Aquí iría lógica para deshabilitar características intensivas
    // que no se pueden implementar directamente en este archivo
  }

  /// Incrementa contador de elementos en cache
  void incrementCacheCount() {
    _cacheItemCount++;
    // Realiza limpieza anticipada si es necesario
    if (_cacheItemCount > CACHE_CLEANUP_THRESHOLD) {
      _cleanupLightCache();
    }
  }

  /// Detener monitoreo
  void stopMonitoring() {
    _cleanupTimer?.cancel();
    _memoryMonitorTimer?.cancel();
    _cleanupTimer = null;
    _memoryMonitorTimer = null;
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

    // Limpia contador de cache
    _cacheItemCount = _cacheItemCount ~/ 2;

    // Sugerir recolección de basura
    if (Platform.isAndroid || Platform.isIOS) {
      // La VM de Dart manejará esto automáticamente
    }
  }

  /// Obtener límites de recursos optimizados para bajo consumo
  Map<String, dynamic> getResourceLimits() {
    if (isLowMemoryDevice) {
      return {
        'max_cached_images': 3, // Reducido de 5
        'max_list_items_before_pagination': 8, // Reducido de 10
        'auto_refresh_interval': 180000, // Aumentado a 3 min para reducir operaciones
        'image_quality': 20, // Aún más reducido para bajo consumo
        'batch_size': 3, // Muy pequeño para bajo recurso
      };
    }
    return resourceLimits;
  }

  /// Obtener información de memoria (solo debug)
  Map<String, dynamic> getMemoryInfo() {
    return {
      'cleanup_callbacks': _cleanupCallbacks.length,
      'monitoring': _cleanupTimer?.isActive ?? false,
      'estimated_memory_mb': _estimateMemoryUsage(),
      'cache_item_count': _cacheItemCount,
      'resource_limits': getResourceLimits(),
    };
  }

  void dispose() {
    stopMonitoring();
    _cleanupCallbacks.clear();
  }
}
