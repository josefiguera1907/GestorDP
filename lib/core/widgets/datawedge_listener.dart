import 'package:flutter/material.dart';
import 'dart:async';
import '../services/datawedge_service.dart';

/// Widget que escucha eventos de DataWedge globalmente
class DataWedgeListener extends StatefulWidget {
  final Widget child;
  final Function(String)? onScan;

  const DataWedgeListener({
    super.key,
    required this.child,
    this.onScan,
  });

  @override
  State<DataWedgeListener> createState() => _DataWedgeListenerState();
}

class _DataWedgeListenerState extends State<DataWedgeListener> {
  final DataWedgeService _dataWedgeService = DataWedgeService();
  StreamSubscription<String>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _initializeDataWedge();
  }

  Future<void> _initializeDataWedge() async {
    try {
      await _dataWedgeService.initialize();

      // Escuchar eventos de escaneo
      _scanSubscription = _dataWedgeService.scanStream.listen((scannedData) {
        print('🎯 DataWedgeListener recibió: $scannedData');

        // Mostrar notificación visual
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Código escaneado: ${scannedData.substring(0, scannedData.length > 20 ? 20 : scannedData.length)}...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );

          // Llamar callback si existe
          widget.onScan?.call(scannedData);
        }
      });

      print('✅ DataWedgeListener inicializado');
    } catch (e) {
      print('❌ Error inicializando DataWedgeListener: $e');
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _dataWedgeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
