import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/package.dart';
import '../providers/package_provider.dart';
import '../providers/location_provider.dart';
import '../providers/warehouse_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/services/chatea_service.dart';
import '../../data/services/meta_service.dart';

class PackageDetailsScreen extends StatefulWidget {
  final String packageId;

  const PackageDetailsScreen({
    super.key,
    required this.packageId,
  });

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  Package? package;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackage();
  }

  Future<void> _loadPackage() async {
    final packageProvider = context.read<PackageProvider>();
    final loadedPackage = await packageProvider.getPackageById(widget.packageId);
    setState(() {
      package = loadedPackage;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalles del Registro')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (package == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalles del Registro')),
        body: const Center(child: Text('Registro no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Registro'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBasicInfo(),
            _buildSenderInfo(),
            _buildRecipientInfo(),
            _buildPackageDetails(),
            _buildInventoryInfo(),
            _buildStatusSection(),
            _buildActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_2, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Información Básica',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Número de Guía', package!.trackingNumber),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Fecha/Hora de Registro',
              dateFormat.format(package!.registeredDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenderInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Datos del Remitente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Nombre', package!.senderName),
            const SizedBox(height: 8),
            _buildInfoRow('Teléfono', package!.senderPhone),
            if (package!.senderEmail != null && package!.senderEmail!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Email', package!.senderEmail!),
            ],
            if (package!.senderIdType != null && package!.senderIdType!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Tipo de ID', package!.senderIdType!),
            ],
            if (package!.senderIdNumber != null && package!.senderIdNumber!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Número de ID', package!.senderIdNumber!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Datos del Destinatario',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Nombre', package!.recipientName),
            const SizedBox(height: 8),
            _buildInfoRow('Teléfono', package!.recipientPhone),
            if (package!.recipientIdType != null && package!.recipientIdType!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Tipo de ID', package!.recipientIdType!),
            ],
            if (package!.recipientIdNumber != null && package!.recipientIdNumber!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Número de ID', package!.recipientIdNumber!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackageDetails() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Detalles del Paquete',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (package!.weight != null)
              _buildInfoRow('Peso', '${package!.weight} kg')
            else
              _buildInfoRow('Peso', 'No especificado'),
            if (package!.notes != null && package!.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Notas', package!.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryInfo() {
    return Consumer2<LocationProvider, WarehouseProvider>(
      builder: (context, locationProvider, warehouseProvider, child) {
        String warehouseName = 'Sin asignar';
        String locationName = 'Sin asignar';

        if (package!.warehouseId != null) {
          final warehouse = warehouseProvider.warehouses
              .where((w) => w.id == package!.warehouseId)
              .firstOrNull;
          if (warehouse != null) {
            warehouseName = warehouse.name;
          }
        }

        if (package!.locationId != null) {
          final location = locationProvider.locations
              .where((l) => l.id == package!.locationId)
              .firstOrNull;
          if (location != null) {
            locationName = location.code;
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warehouse, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Información de Inventario',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow('Almacén', warehouseName),
                const SizedBox(height: 8),
                _buildInfoRow('Ubicación', locationName),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Status del Paquete',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            Center(
              child: _buildStatusChip(package!.status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final canManagePackages = authProvider.currentUser?.canManagePackages ?? true;
        final canDeletePackages = authProvider.currentUser?.canDeletePackages ?? true;
        final canSendMessages = authProvider.currentUser?.canSendMessages ?? true;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showQRPreview,
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Ver QR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canSendMessages ? _sendMessage : null,
                      icon: const Icon(Icons.message),
                      label: const Text('Mensajes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canManagePackages ? _editPackage : null,
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                  ),
                ],
              ),
              if (canDeletePackages) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Eliminar Registro', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pendiente':
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;
      case 'en tránsito':
      case 'en transito':
        color = Colors.blue;
        icon = Icons.local_shipping;
        break;
      case 'en reparto':
        color = Colors.purple;
        icon = Icons.delivery_dining;
        break;
      case 'entregado':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'en almacén':
        color = Colors.grey;
        icon = Icons.inventory;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showQRPreview() {
    // Generar QR con la información del registro (sin ubicación ni almacén)
    final completeQRData = [
      package!.trackingNumber, // 0: Número de guía
      '', // 1: Campo reservado
      '', // 2: Campo reservado
      package!.recipientName, // 3: Nombre destinatario
      package!.recipientPhone, // 4: Teléfono destinatario
      package!.recipientIdType ?? '', // 5: Tipo ID destinatario
      package!.recipientIdNumber ?? '', // 6: Número ID destinatario
      '', // 7: Campo reservado
      package!.senderName, // 8: Nombre remitente
      package!.senderPhone, // 9: Teléfono remitente
      package!.senderEmail ?? '', // 10: Email remitente
      package!.senderIdType ?? '', // 11: Tipo ID remitente
      package!.senderIdNumber ?? '', // 12: Número ID remitente
      '', // 13-21: Campos reservados
      '', '', '', '', '', '', '', '', '',
      package!.weight?.toString() ?? '0', // 22: Peso
      package!.status, // 23: Estado
      DateFormat('dd/MM/yyyy HH:mm').format(package!.registeredDate), // 24: Fecha registro
      package!.notes ?? '', // 25: Notas
    ].join(';');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Código QR Completo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: QrImageView(
                  data: completeQRData,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guía: ${package!.trackingNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Remitente: ${package!.senderName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Destinatario: ${package!.recipientName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Peso: ${package!.weight ?? 0} kg',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (package == null) return;

    // Verificar configuración de META
    final prefs = await SharedPreferences.getInstance();
    final phoneId = prefs.getString('meta_phone_id');
    final accessToken = prefs.getString('meta_access_token');

    if (phoneId == null || phoneId.isEmpty || accessToken == null || accessToken.isEmpty) {
      // Verificar si hay configuración de Chatea como respaldo
      final chateaApiKey = prefs.getString('chatea_api_key');
      final chateaSenderPhone = prefs.getString('chatea_sender_phone');

      if (chateaApiKey == null || chateaApiKey.isEmpty || chateaSenderPhone == null || chateaSenderPhone.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Configuración requerida'),
              content: const Text('Por favor configura tu Identificador de número de teléfono y Token de acceso de API en Ajustes → META antes de enviar mensajes.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      } else {
        // Si hay configuración de Chatea pero no de META, usar el sistema antiguo
        await _sendUsingChatea();
        return;
      }
    }

    // Obtener plantillas de mensaje para META
    List<String> templates = [];
    try {
      final result = await MetaService.getTemplates(
        phoneId: phoneId,
        accessToken: accessToken,
      );

      if (result.success) {
        templates = result.templates;
      } else {
        // Si no se pueden obtener las plantillas del sistema, usar las guardadas o predeterminadas
        final templatesJson = prefs.getString('saved_message_templates');
        if (templatesJson != null) {
          templates = List<String>.from(jsonDecode(templatesJson));
        } else {
          templates = [_getDefaultMessageTemplate()];
        }
      }
    } catch (e) {
      // Si hay error de conexión, usar las guardadas o predeterminadas
      final templatesJson = prefs.getString('saved_message_templates');
      if (templatesJson != null) {
        templates = List<String>.from(jsonDecode(templatesJson));
      } else {
        templates = [_getDefaultMessageTemplate()];
      }
    }

    // Mostrar vista previa directa del mensaje para la plantilla hello_world
    String locationName = 'Sin ubicación';
    if (package!.locationId != null && mounted) {
      try {
        final location = Provider.of<LocationProvider>(context, listen: false)
            .locations.firstWhere((l) => l.id == package!.locationId);
        locationName = location.code;
      } catch (e) {
        locationName = 'Ubicación #${package!.locationId}';
      }
    }

    // Vista previa del mensaje que se enviará
    String previewMessage = 'Hello World'; // Vista previa del mensaje hello_world

    // Mostrar diálogo de confirmación
    if (mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar envío'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Destinatario: ${package!.recipientName}'),
              Text('Teléfono: ${package!.recipientPhone}'),
              const SizedBox(height: 16),
              const Text('Mensaje:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  previewMessage, // Mostrar la vista previa del mensaje
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Mostrar indicador de carga
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Enviar mensaje a través de META usando la plantilla hello_world
      final result = await MetaService.sendMessage(
        phoneId: phoneId,
        accessToken: accessToken,
        recipientPhone: package!.recipientPhone,
        message: 'Hello {{1}}', // Enviar la plantilla hello_world como se especificó
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga

        // Mostrar resultado
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: result.success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Text(result.success ? 'Mensaje enviado' : 'Error al enviar'),
              ],
            ),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Función para enviar usando el sistema antiguo (Chatea) como respaldo
  Future<void> _sendUsingChatea() async {
    if (package == null) return;

    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('chatea_api_key');
    final senderPhone = prefs.getString('chatea_sender_phone');

    if (apiKey == null || apiKey.isEmpty || senderPhone == null || senderPhone.isEmpty) return;

    // Obtener plantillas de mensaje
    String messageTemplate;
    final templatesJson = prefs.getString('saved_message_templates');

    if (templatesJson != null) {
      try {
        final List<String> templates = List<String>.from(jsonDecode(templatesJson));
        if (templates.isNotEmpty) {
          // Obtener índice de la última plantilla usada
          final lastIndex = prefs.getInt('last_template_index') ?? -1;
          final nextIndex = (lastIndex + 1) % templates.length;

          // Usar la siguiente plantilla en rotación
          messageTemplate = templates[nextIndex];

          // Guardar el índice para la próxima vez
          await prefs.setInt('last_template_index', nextIndex);

          print('📋 Usando plantilla ${nextIndex + 1} de ${templates.length}');
        } else {
          messageTemplate = prefs.getString('message_template') ?? _getDefaultMessageTemplate();
        }
      } catch (e) {
        print('⚠️ Error al cargar plantillas: $e');
        messageTemplate = prefs.getString('message_template') ?? _getDefaultMessageTemplate();
      }
    } else {
      messageTemplate = prefs.getString('message_template') ?? _getDefaultMessageTemplate();
    }

    // Obtener nombre de ubicación
    String locationName = 'Sin ubicación';
    if (package!.locationId != null && mounted) {
      try {
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        final location = locationProvider.locations.firstWhere((l) => l.id == package!.locationId);
        locationName = location.code;
      } catch (e) {
        locationName = 'Ubicación #${package!.locationId}';
      }
    }

    // Obtener nombre de almacén
    String warehouseName = 'Sin almacén';
    if (package!.warehouseId != null && mounted) {
      try {
        final warehouseProvider = Provider.of<WarehouseProvider>(context, listen: false);
        final warehouse = warehouseProvider.warehouses.firstWhere((w) => w.id == package!.warehouseId);
        warehouseName = warehouse.name;
      } catch (e) {
        warehouseName = 'Almacén #${package!.warehouseId}';
      }
    }

    // Reemplazar variables en la plantilla
    final personalizedMessage = messageTemplate
        .replaceAll('{guia}', package!.trackingNumber)
        .replaceAll('{tracking}', package!.trackingNumber) // Mantener compatibilidad
        .replaceAll('{destinatario}', package!.recipientName)
        .replaceAll('{recipient}', package!.recipientName) // Mantener compatibilidad
        .replaceAll('{remitente}', package!.senderName)
        .replaceAll('{sender}', package!.senderName) // Mantener compatibilidad
        .replaceAll('{ubicacion}', locationName)
        .replaceAll('{location}', locationName) // Mantener compatibilidad
        .replaceAll('{almacen}', warehouseName)
        .replaceAll('{warehouse}', warehouseName) // Mantener compatibilidad
        .replaceAll('{fecha}', DateFormat('dd/MM/yyyy HH:mm').format(package!.registeredDate))
        .replaceAll('{date}', DateFormat('dd/MM/yyyy HH:mm').format(package!.registeredDate)); // Mantener compatibilidad

    // Mostrar diálogo de confirmación
    if (mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar envío'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Destinatario: ${package!.recipientName}'),
              Text('Teléfono: ${package!.recipientPhone}'),
              const SizedBox(height: 16),
              const Text('Mensaje:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  personalizedMessage, // Para la función de respaldo, usar el mensaje personalizado
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enviar'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Mostrar indicador de carga
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Enviar mensaje
      final result = await ChateaService.sendMessage(
        apiKey: apiKey,
        senderPhone: senderPhone,
        recipientPhone: package!.recipientPhone,
        message: personalizedMessage,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga

        // Mostrar resultado
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: result.success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Text(result.success ? 'Mensaje enviado' : 'Error al enviar'),
              ],
            ),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  String _getDefaultMessageTemplate() {
    return '🎉 ¡Hola {recipient}!\n\n'
        'Tu paquete con guía #{tracking} ha sido registrado exitosamente.\n\n'
        '📦 Remitente: {sender}\n'
        '📍 Ubicación: {location}\n'
        '📅 Fecha: {date}\n\n'
        'Gracias por confiar en nosotros.';
  }

  Future<void> _exportPDF() async {
    if (package == null) return;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generar QR con la información del registro (sin ubicación ni almacén)
      final completeQRData = [
        package!.trackingNumber,
        '', '',
        package!.recipientName,
        package!.recipientPhone,
        package!.recipientIdType ?? '',
        package!.recipientIdNumber ?? '',
        '',
        package!.senderName,
        package!.senderPhone,
        package!.senderEmail ?? '',
        package!.senderIdType ?? '',
        package!.senderIdNumber ?? '',
        '', '', '', '', '', '', '', '', '',
        package!.weight?.toString() ?? '0',
        package!.status,
        DateFormat('dd/MM/yyyy HH:mm').format(package!.registeredDate),
        package!.notes ?? '',
      ].join(';');

      // Obtener información de ubicación y almacén
      String warehouseName = 'Sin asignar';
      String locationName = 'Sin asignar';

      if (package!.warehouseId != null && mounted) {
        try {
          final warehouseProvider = Provider.of<WarehouseProvider>(context, listen: false);
          final warehouse = warehouseProvider.warehouses.firstWhere((w) => w.id == package!.warehouseId);
          warehouseName = warehouse.name;
        } catch (e) {
          warehouseName = 'Almacén #${package!.warehouseId}';
        }
      }

      if (package!.locationId != null && mounted) {
        try {
          final locationProvider = Provider.of<LocationProvider>(context, listen: false);
          final location = locationProvider.locations.firstWhere((l) => l.id == package!.locationId);
          locationName = location.code;
        } catch (e) {
          locationName = 'Ubicación #${package!.locationId}';
        }
      }

      // Generar imagen del QR
      final qrValidationResult = QrValidator.validate(
        data: completeQRData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: true,
        );

        final picData = await painter.toImageData(300, format: ui.ImageByteFormat.png);
        final qrImageBytes = picData!.buffer.asUint8List();

        // Crear el PDF
        final pdf = pw.Document();
        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (context) => [
              // Encabezado
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'REGISTRO DE PAQUETE',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      dateFormat.format(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Código QR
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400, width: 2),
                      ),
                      child: pw.Image(
                        pw.MemoryImage(qrImageBytes),
                        width: 200,
                        height: 200,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      package!.trackingNumber,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Información del Paquete
              _buildPdfSection('INFORMACIÓN BÁSICA', [
                _buildPdfRow('Número de Guía', package!.trackingNumber),
                _buildPdfRow('Fecha/Hora de Registro', dateFormat.format(package!.registeredDate)),
                _buildPdfRow('Estado', package!.status),
              ]),

              pw.SizedBox(height: 20),

              // Datos del Remitente
              _buildPdfSection('DATOS DEL REMITENTE', [
                _buildPdfRow('Nombre', package!.senderName),
                _buildPdfRow('Teléfono', package!.senderPhone),
                if (package!.senderEmail != null && package!.senderEmail!.isNotEmpty)
                  _buildPdfRow('Email', package!.senderEmail!),
                if (package!.senderIdType != null && package!.senderIdType!.isNotEmpty)
                  _buildPdfRow('Tipo de ID', package!.senderIdType!),
                if (package!.senderIdNumber != null && package!.senderIdNumber!.isNotEmpty)
                  _buildPdfRow('Número de ID', package!.senderIdNumber!),
              ]),

              pw.SizedBox(height: 20),

              // Datos del Destinatario
              _buildPdfSection('DATOS DEL DESTINATARIO', [
                _buildPdfRow('Nombre', package!.recipientName),
                _buildPdfRow('Teléfono', package!.recipientPhone),
                if (package!.recipientIdType != null && package!.recipientIdType!.isNotEmpty)
                  _buildPdfRow('Tipo de ID', package!.recipientIdType!),
                if (package!.recipientIdNumber != null && package!.recipientIdNumber!.isNotEmpty)
                  _buildPdfRow('Número de ID', package!.recipientIdNumber!),
              ]),

              pw.SizedBox(height: 20),

              // Detalles del Paquete
              _buildPdfSection('DETALLES DEL PAQUETE', [
                _buildPdfRow('Peso', package!.weight != null ? '${package!.weight} kg' : 'No especificado'),
                if (package!.notes != null && package!.notes!.isNotEmpty)
                  _buildPdfRow('Notas', package!.notes!),
              ]),

              pw.SizedBox(height: 20),

              // Información de Inventario
              _buildPdfSection('INFORMACIÓN DE INVENTARIO', [
                _buildPdfRow('Almacén', warehouseName),
                _buildPdfRow('Ubicación', locationName),
              ]),

              pw.SizedBox(height: 30),

              // Pie de página
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Sistema de Gestión de Paquetería',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ),
        );

        // Cerrar indicador de carga
        if (mounted) {
          Navigator.pop(context);

          // Mostrar diálogo de vista previa e impresión
          await Printing.layoutPdf(
            onLayout: (format) async => pdf.save(),
            name: 'Paquete_${package!.trackingNumber}.pdf',
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al generar el código QR'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            border: pw.Border(
              left: pw.BorderSide(color: PdfColors.blue, width: 3),
            ),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _editPackage() async {
    if (package == null) return;

    // Controladores para los campos
    final senderNameController = TextEditingController(text: package!.senderName);
    final senderPhoneController = TextEditingController(text: package!.senderPhone);
    final senderEmailController = TextEditingController(text: package!.senderEmail ?? '');
    final senderIdTypeController = TextEditingController(text: package!.senderIdType ?? '');
    final senderIdNumberController = TextEditingController(text: package!.senderIdNumber ?? '');

    final recipientNameController = TextEditingController(text: package!.recipientName);
    final recipientPhoneController = TextEditingController(text: package!.recipientPhone);
    final recipientIdTypeController = TextEditingController(text: package!.recipientIdType ?? '');
    final recipientIdNumberController = TextEditingController(text: package!.recipientIdNumber ?? '');

    final weightController = TextEditingController(text: package!.weight?.toString() ?? '');
    final notesController = TextEditingController(text: package!.notes ?? '');

    String selectedStatus = package!.status;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Registro'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remitente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: senderNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: senderPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: senderEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: senderIdTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Tipo ID',
                          prefixIcon: Icon(Icons.badge),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: senderIdNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Número ID',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Destinatario',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: recipientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: recipientPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: recipientIdTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Tipo ID',
                          prefixIcon: Icon(Icons.badge),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: recipientIdNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Número ID',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Detalles del Paquete',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Peso (kg)',
                    prefixIcon: Icon(Icons.scale),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    prefixIcon: Icon(Icons.local_shipping),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                    DropdownMenuItem(value: 'En tránsito', child: Text('En tránsito')),
                    DropdownMenuItem(value: 'En reparto', child: Text('En reparto')),
                    DropdownMenuItem(value: 'Entregado', child: Text('Entregado')),
                    DropdownMenuItem(value: 'En almacén', child: Text('En almacén')),
                  ],
                  onChanged: (value) {
                    if (value != null) selectedStatus = value;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Actualizar el paquete con los nuevos datos
      final updatedPackage = package!.copyWith(
        senderName: senderNameController.text,
        senderPhone: senderPhoneController.text,
        senderEmail: senderEmailController.text.isEmpty ? null : senderEmailController.text,
        senderIdType: senderIdTypeController.text.isEmpty ? null : senderIdTypeController.text,
        senderIdNumber: senderIdNumberController.text.isEmpty ? null : senderIdNumberController.text,
        recipientName: recipientNameController.text,
        recipientPhone: recipientPhoneController.text,
        recipientIdType: recipientIdTypeController.text.isEmpty ? null : recipientIdTypeController.text,
        recipientIdNumber: recipientIdNumberController.text.isEmpty ? null : recipientIdNumberController.text,
        weight: double.tryParse(weightController.text),
        status: selectedStatus,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );

      // Guardar en la base de datos
      await context.read<PackageProvider>().updatePackage(updatedPackage);

      // Recargar el paquete
      await _loadPackage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    // Limpiar controladores
    senderNameController.dispose();
    senderPhoneController.dispose();
    senderEmailController.dispose();
    senderIdTypeController.dispose();
    senderIdNumberController.dispose();
    recipientNameController.dispose();
    recipientPhoneController.dispose();
    recipientIdTypeController.dispose();
    recipientIdNumberController.dispose();
    weightController.dispose();
    notesController.dispose();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: Text(
          '¿Está seguro que desea eliminar el registro del paquete "${package!.trackingNumber}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<PackageProvider>().deletePackage(package!.id!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro eliminado')),
        );
      }
    }
  }
}

