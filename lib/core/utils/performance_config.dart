import 'package:flutter/material.dart';

class PerformanceConfig {
  // Optimizaciones para dispositivos de baja RAM
  static const Map<String, dynamic> lowRamSettings = {
    // Reducir tamaño de cache de imágenes
    'image_cache_size': 50, // Reducido de 1000
    'text_scale_factor': 0.95, // Ligeramente menor para ahorrar espacio
    'scroll_physics': ClampingScrollPhysics(), // Rendimiento superior en dispositivos lentos
    'animation_complexity': 'low', // Reducir animaciones complejas
    'enable_shader_warmup': false, // Ahorro de recursos en arranque
  };

  // Configuraciones de rendimiento basadas en el dispositivo
  static void applyOptimizations() {
    // Configurar tamaño de cache de imágenes
    PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024; // 20MB
    PaintingBinding.instance.imageCache.maximumSize = PerformanceConfig.lowRamSettings['image_cache_size'];

    // Ajustar comportamiento de scroll global
    // Esto se aplica en main.dart
  }

  // Obtener configuración específica para un widget
  static dynamic getSetting(String key) {
    return lowRamSettings[key];
  }
}