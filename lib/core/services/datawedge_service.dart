import 'dart:async';
import 'package:flutter/services.dart';

/// Servicio para integración con Zebra DataWedge en TC26
/// Maneja los botones laterales (triggers) y escaneo de códigos
class DataWedgeService {
  static const MethodChannel _channel = MethodChannel('datawedge_channel');
  static const EventChannel _scanChannel = EventChannel('datawedge_scan_events');

  // Stream para recibir datos escaneados
  Stream<String>? _scanStream;
  StreamController<String>? _scanController;

  // Nombre del perfil DataWedge para esta app
  static const String profileName = 'PaqueteriaApp';

  /// Inicializar el servicio DataWedge
  Future<void> initialize() async {
    try {
      // Crear stream controller
      _scanController = StreamController<String>.broadcast();

      // Crear perfil DataWedge
      await createDataWedgeProfile();

      // Configurar intent output
      await configureDataWedgeIntents();

      // Habilitar el escáner
      await enableScanner();

      print('DataWedge inicializado correctamente');
    } catch (e) {
      print('Error inicializando DataWedge: $e');
    }
  }

  /// Crear perfil DataWedge para la app
  Future<void> createDataWedgeProfile() async {
    try {
      await _channel.invokeMethod('createProfile', {
        'profileName': profileName,
        'packageName': 'com.paqueteria.paqueteria_app',
      });
    } catch (e) {
      print('Error creando perfil DataWedge: $e');
    }
  }

  /// Configurar DataWedge para enviar datos via Intent
  Future<void> configureDataWedgeIntents() async {
    try {
      await _channel.invokeMethod('configureIntents', {
        'profileName': profileName,
        'intentAction': 'com.paqueteria.SCAN',
        'intentCategory': 'android.intent.category.DEFAULT',
      });
    } catch (e) {
      print('Error configurando intents: $e');
    }
  }

  /// Habilitar el escáner
  Future<void> enableScanner() async {
    try {
      await _channel.invokeMethod('enableScanner');
    } catch (e) {
      print('Error habilitando escáner: $e');
    }
  }

  /// Deshabilitar el escáner
  Future<void> disableScanner() async {
    try {
      await _channel.invokeMethod('disableScanner');
    } catch (e) {
      print('Error deshabilitando escáner: $e');
    }
  }

  /// Obtener stream de códigos escaneados
  Stream<String> get scanStream {
    if (_scanStream == null) {
      _scanStream = _scanChannel
          .receiveBroadcastStream()
          .map((event) => event.toString());
    }
    return _scanStream!;
  }

  /// Simular trigger del botón lateral (para testing)
  Future<void> simulateTrigger() async {
    try {
      await _channel.invokeMethod('softwareTrigger');
    } catch (e) {
      print('Error con software trigger: $e');
    }
  }

  /// Limpiar recursos
  void dispose() {
    _scanController?.close();
  }

  /// Verificar si DataWedge está disponible
  Future<bool> isDataWedgeAvailable() async {
    try {
      final result = await _channel.invokeMethod('checkDataWedge');
      return result == true;
    } catch (e) {
      print('DataWedge no disponible: $e');
      return false;
    }
  }
}
