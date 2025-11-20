import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/package_provider.dart';
import '../providers/location_provider.dart';
import '../providers/warehouse_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/services/backup_service.dart';
import 'scan_screen.dart';
import 'warehouses_screen.dart';
import 'locations_screen.dart';
import 'packages_screen.dart';
import 'chatea_settings_screen.dart';
import 'meta_settings_screen.dart';
import 'users_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? preselectedTrackingNumber;

  const HomeScreen({super.key, this.preselectedTrackingNumber});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _pendingTrackingNumber; // Tracking del último escaneo

  @override
  void initState() {
    super.initState();

    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageProvider>().loadPackages();
      context.read<LocationProvider>().loadLocations();
      context.read<WarehouseProvider>().loadWarehouses();
    });
  }

  // Variables para filtros de navegación entre pestañas
  String? _filterWarehouseId;
  String? _filterLocationId;

  void _navigateToTab(int tabIndex, {String? warehouseId, String? locationId}) {
    setState(() {
      _selectedIndex = tabIndex;
      if (tabIndex == 2) {
        // Ubicaciones
        _filterWarehouseId = warehouseId;
      } else if (tabIndex == 3) {
        // Registros
        _filterLocationId = locationId;
      }
    });
  }

  List<Widget> _getWidgetOptions(BuildContext context) {
    return [
      _buildWelcomeScreen(),
      WarehousesScreen(
        onWarehouseTap: (warehouseId) {
          _navigateToTab(2, warehouseId: warehouseId);
        },
      ),
      LocationsScreen(
        filterWarehouseId: _filterWarehouseId,
        onLocationTap: (locationId) {
          _navigateToTab(3, locationId: locationId);
        },
        onFilterClear: () {
          setState(() {
            _filterWarehouseId = null;
          });
        },
      ),
      PackagesScreen(
        key: ValueKey(_pendingTrackingNumber ?? 'packages_default'), // Clave dinámica para forzar rebuild cuando hay nuevo tracking
        preselectedTrackingNumber: _pendingTrackingNumber, // Pasar tracking pendiente para abrir diálogo de traslado
        filterLocationId: _filterLocationId,
        onFilterClear: () {
          setState(() {
            _filterLocationId = null;
            _pendingTrackingNumber = null; // Limpiar cuando se limpia el filtro
          });
        },
        onDialogClosed: () {
          print('🔧 DEBUG: HomeScreen received onDialogClosed, clearing _pendingTrackingNumber');
          setState(() {
            _pendingTrackingNumber = null; // Limpiar cuando se cierra el diálogo de traslado
          });
        },
      ),
    ];
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Header con logo
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/512x512.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Bienvenido a GestorDP!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Descripción
          Text(
            'Funcionalidades principales:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Tarjetas de funcionalidades
          _buildFeatureCard(
            icon: Icons.qr_code_scanner,
            title: 'Escaneo de QR',
            description: 'Registra paquetes rápidamente escaneando códigos QR con el TC26',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.warehouse,
            title: 'Gestión de Almacenes',
            description: 'Administra almacenes y controla el inventario de paquetes',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.location_on,
            title: 'Ubicaciones',
            description: 'Organiza y localiza paquetes en ubicaciones específicas',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.list_alt,
            title: 'Registro de Paquetes',
            description: 'Visualiza y gestiona todos los paquetes registrados en el sistema',
            color: Colors.purple,
          ),
          const SizedBox(height: 32),

          // Botón de acción
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final canScan = authProvider.currentUser?.canScanQR ?? true;
              if (!canScan) return const SizedBox.shrink();

              return Center(
                child: FilledButton.icon(
                  onPressed: _scanQRCode,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Comenzar a escanear'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Limpiar filtros cuando se cambia manualmente de pestaña
      _filterWarehouseId = null;
      _filterLocationId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GestorDP'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: themeProvider.isDarkMode ? 'Modo claro' : 'Modo oscuro',
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              return PopupMenuButton<String>(
                icon: const Icon(Icons.settings),
                onSelected: _handleMenuSelection,
                itemBuilder: (BuildContext context) {
                  final items = <PopupMenuEntry<String>>[];

                  // Usuarios - solo si tiene permiso
                  if (user?.canManageUsers ?? true) {
                    items.add(const PopupMenuItem<String>(
                      value: 'perfiles',
                      child: ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Usuarios'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ));
                  }

                  // META - solo si tiene permiso de mensajería
                  if (user?.canSendMessages ?? true) {
                    items.add(const PopupMenuItem<String>(
                      value: 'meta',
                      child: ListTile(
                        leading: Icon(Icons.chat),
                        title: Text('META'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ));
                  }

                  // Chatea - solo si tiene permiso de mensajería (mantenido para compatibilidad)
                  if (user?.canSendMessages ?? true) {
                    items.add(const PopupMenuItem<String>(
                      value: 'chatea',
                      child: ListTile(
                        leading: Icon(Icons.chat_bubble),
                        title: Text('Chatea (Legacy)'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ));
                  }

                  // Backup - solo si tiene permiso
                  if (user?.canBackupRestore ?? true) {
                    items.add(const PopupMenuItem<String>(
                      value: 'backup',
                      child: ListTile(
                        leading: Icon(Icons.backup),
                        title: Text('Backup'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ));
                  }

                  // Siempre mostrar logout
                  if (items.isNotEmpty) {
                    items.add(const PopupMenuDivider());
                  }
                  items.add(const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Cerrar Sesión',
                          style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ));

                  return items;
                },
              );
            },
          ),
        ],
      ),
      body: _getWidgetOptions(context).elementAt(_selectedIndex),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final canScan = authProvider.currentUser?.canScanQR ?? true;
          if (!canScan) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: _scanQRCode,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear'),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse_outlined),
            activeIcon: Icon(Icons.warehouse),
            label: 'Almacenes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Ubicaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Registros',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'perfiles':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UsersScreen()),
        );
        break;
      case 'meta':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MetaSettingsScreen()),
        );
        break;
      case 'chatea':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChateaSettingsScreen()),
        );
        break;
      case 'backup':
        _showBackupDialog();
        break;
      case 'logout':
        _confirmLogout();
        break;
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 12),
              Text('Cerrar Sesión'),
            ],
          ),
          content: const Text('¿Estás seguro que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await context.read<AuthProvider>().logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Backup de Datos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Seleccione una opción:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Exportar datos'),
                subtitle: const Text('Guardar copia de seguridad'),
                onTap: () {
                  Navigator.pop(context);
                  _exportData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('Importar datos'),
                subtitle: const Text('Restaurar desde backup'),
                onTap: () {
                  Navigator.pop(context);
                  _importData();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportData() async {
    try {
      // Solicitar permisos de almacenamiento
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se requiere permiso de almacenamiento para exportar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Seleccionar directorio donde guardar
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Seleccionar carpeta para guardar backup',
      );

      if (selectedDirectory == null) {
        // Usuario canceló la selección
        return;
      }

      // Mostrar diálogo de progreso
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(child: Text('Exportando datos...')),
              ],
            ),
          ),
        );
      }

      // Exportar datos
      final backupService = BackupService();
      final tempFile = await backupService.exportData();

      // Copiar archivo a la ubicación seleccionada
      final fileName = tempFile.path.split('/').last;
      final destinationPath = '$selectedDirectory/$fileName';
      final destinationFile = File(destinationPath);

      await tempFile.copy(destinationFile.path);
      await tempFile.delete(); // Eliminar temporal

      // Cerrar diálogo de progreso
      if (mounted) Navigator.pop(context);

      if (mounted) {
        // Mostrar opciones al usuario
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('Backup Exportado')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'El backup ha sido guardado en:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      destinationFile.path,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Nombre del archivo:'),
                  const SizedBox(height: 4),
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles(
                    [XFile(destinationFile.path)],
                    subject: 'Backup de Paquetería',
                    text: 'Backup completo de la aplicación de paquetería',
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Compartir'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de progreso si está abierto
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      // Seleccionar archivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final filePath = result.files.single.path!;

      // Confirmar importación
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('Confirmar Importación')),
            ],
          ),
          content: const Text(
            '¿Está seguro que desea importar este backup?\n\n'
            'ADVERTENCIA: Esta acción reemplazará TODOS los datos actuales '
            '(almacenes, ubicaciones, paquetes, usuarios, etc.) con los datos del backup.\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Importar'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Mostrar diálogo de progreso
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Importando datos...'),
              ],
            ),
          ),
        );
      }

      // Importar datos
      final backupService = BackupService();
      await backupService.importData(filePath);

      // Recargar todos los providers
      if (mounted) {
        await context.read<PackageProvider>().loadPackages();
        await context.read<LocationProvider>().loadLocations();
        await context.read<WarehouseProvider>().loadWarehouses();
      }

      // Cerrar diálogo de progreso
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup importado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de progreso si está abierto
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scanQRCode() async {
    // Abrir ScanScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );

    if (result == null || !mounted || result is! String) {
      return; // Usuario canceló o hubo error
    }

    final trackingNumber = result;

    // ========================================
    // FLUJO ÚNICO Y CENTRALIZADO DE ESCANEO
    // ========================================

    // 1. Recargar paquetes (el nuevo paquete ya fue guardado en BD por ScanScreen)
    // Usar reset=true para reemplazar la lista completa en lugar de agregar
    await context.read<PackageProvider>().loadPackages(reset: true);

    // 2. Navegar a Registros
    setState(() {
      _selectedIndex = 3;
      _pendingTrackingNumber = trackingNumber;
      print('🔧 DEBUG: HomeScreen received scan result, _pendingTrackingNumber=$trackingNumber');
    });

    // 3. PackagesScreen abrirá automáticamente el diálogo de traslado
    // en su initState() mediante preselectedTrackingNumber
  }
}
