import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/package_provider.dart';
import '../providers/location_provider.dart';
import '../providers/warehouse_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/package.dart';
import '../../domain/entities/location.dart';
import 'package_details_screen.dart';

class PackagesScreen extends StatefulWidget {
  final String? preselectedTrackingNumber;
  final VoidCallback? onDialogShown;
  final VoidCallback? onDialogClosed; // Callback cuando se cierra el diálogo de traslado
  final String? filterLocationId; // Filtro opcional por ubicación
  final VoidCallback? onFilterClear; // Callback para limpiar filtro

  const PackagesScreen({
    super.key,
    this.preselectedTrackingNumber,
    this.onDialogShown,
    this.onDialogClosed,
    this.filterLocationId,
    this.onFilterClear,
  });

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _lastOpenedTrackingNumber; // Para evitar abrir el mismo diálogo múltiples veces

  @override
  void initState() {
    super.initState();
    // Si hay un tracking number, abrimos el diálogo
    if (widget.preselectedTrackingNumber != null &&
        widget.preselectedTrackingNumber != _lastOpenedTrackingNumber) {
      _lastOpenedTrackingNumber = widget.preselectedTrackingNumber;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openTransferDialogForTracking(widget.preselectedTrackingNumber!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Package> _filterPackages(List<Package> packages, LocationProvider locationProvider) {
    var filtered = packages;

    // Filtrar por ubicación si se especificó
    if (widget.filterLocationId != null) {
      filtered = filtered.where((p) => p.locationId == widget.filterLocationId).toList();
    }

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((package) {
        // Buscar en número de guía
        if (package.trackingNumber.toLowerCase().contains(_searchQuery)) {
          return true;
        }

        // Buscar en nombre de destinatario
        if (package.recipientName.toLowerCase().contains(_searchQuery)) {
          return true;
        }

        // Buscar en nombre de remitente
        if (package.senderName.toLowerCase().contains(_searchQuery)) {
          return true;
        }

        // Buscar en teléfono de destinatario
        if (package.recipientPhone.toLowerCase().contains(_searchQuery)) {
          return true;
        }

        // Buscar en teléfono de remitente
        if (package.senderPhone.toLowerCase().contains(_searchQuery)) {
          return true;
        }

        // Buscar en código de ubicación
        if (package.locationId != null) {
          try {
            final location = locationProvider.locations.firstWhere(
              (l) => l.id == package.locationId,
            );
            if (location.code.toLowerCase().contains(_searchQuery)) {
              return true;
            }
          } catch (e) {
            // Ubicación no encontrada, continuar
          }
        }

        return false;
      }).toList();
    }

    return filtered;
  }


  Future<void> _openTransferDialogForTracking(String trackingNumber) async {
    final packageProvider = context.read<PackageProvider>();
    final package = await packageProvider.getPackageByTrackingNumber(trackingNumber);

    if (package != null && mounted) {
      _showTransferDialog(context, package);
      // Notificar al padre que se mostró el diálogo
      widget.onDialogShown?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PackageProvider, LocationProvider>(
      builder: (context, packageProvider, locationProvider, child) {
        if (packageProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (packageProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(packageProvider.error!),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => packageProvider.loadPackages(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (packageProvider.packages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay registros de paquetes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Escanea un QR para crear el primer registro',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          );
        }

        // Filtrar paquetes según búsqueda y ubicación
        final filteredPackages = _filterPackages(packageProvider.packages, locationProvider);

        return Column(
          children: [
            // Chip de filtro activo (si existe)
            if (widget.filterLocationId != null)
              Consumer<LocationProvider>(
                builder: (context, locationProvider, child) {
                  // Obtener nombre de la ubicación
                  String locationName = 'Ubicación desconocida';
                  try {
                    final location = locationProvider.locations.firstWhere(
                      (l) => l.id == widget.filterLocationId,
                    );
                    locationName = location.code;
                  } catch (e) {
                    locationName = 'Ubicación #${widget.filterLocationId}';
                  }

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, size: 20, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtrando por: $locationName',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: Colors.blue.shade700),
                          onPressed: () {
                            widget.onFilterClear?.call();
                          },
                          tooltip: 'Quitar filtro',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Barra de búsqueda
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por guía, destinatario, remitente, teléfono o ubicación',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Contador y botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredPackages.length} Registro(s)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final canManage = authProvider.currentUser?.canManagePackages ?? true;
                          final canDelete = authProvider.currentUser?.canDeletePackages ?? true;

                          if (canManage) {
                            return Row(
                              children: [
                                if (canDelete)
                                  IconButton(
                                    onPressed: () => _confirmDeleteAll(context, packageProvider),
                                    icon: const Icon(Icons.delete_sweep),
                                    color: Colors.red,
                                    tooltip: 'Eliminar todos',
                                  ),
                                if (canDelete) const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: () => _showTransferDialog(context, null),
                                  icon: const Icon(Icons.sync_alt),
                                  label: const Text('Traslado'),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredPackages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron registros',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Intenta con otros términos de búsqueda',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => packageProvider.loadPackages(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPackages.length,
                        itemBuilder: (context, index) {
                          final package = filteredPackages[index];
                          return _buildPackageCard(context, package);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPackageCard(BuildContext context, Package package) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PackageDetailsScreen(packageId: package.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      package.trackingNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(package.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      package.status,
                      style: TextStyle(
                        color: _getStatusColor(package.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                package.recipientName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Consumer<LocationProvider>(
                      builder: (context, locationProvider, child) {
                        if (package.locationId == null) {
                          return Text(
                            'Sin ubicación',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }

                        try {
                          final location = locationProvider.locations.firstWhere(
                            (l) => l.id == package.locationId,
                          );
                          return Text(
                            'Ubicación: ${location.code}',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        } catch (e) {
                          return Text(
                            'Ubicación: #${package.locationId}',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }
                      },
                    ),
                  ),
                  Icon(
                    package.notified
                        ? Icons.notifications_active
                        : Icons.notifications_off_outlined,
                    size: 16,
                    color: package.notified
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(package.registeredDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en almacén':
        return Colors.blue;
      case 'en tránsito':
        return Colors.orange;
      case 'en reparto':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showTransferDialog(BuildContext context, Package? preselectedPackage) {
    showDialog(
      context: context,
      builder: (context) => TransferDialog(preselectedPackage: preselectedPackage),
    ).then((_) {
      // Limpiar el pending tracking number cuando el diálogo se cierre
      _lastOpenedTrackingNumber = null;
      print('🔧 DEBUG: Transfer dialog closed, notifying parent...');
      // Notificar al parent (HomeScreen) que se cerró el diálogo
      widget.onDialogClosed?.call();
    });
  }

  Future<void> _confirmDeleteAll(BuildContext context, PackageProvider packageProvider) async {
    final count = packageProvider.packages.length;

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay registros para eliminar')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Eliminar Todos',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            '¿Está seguro que desea eliminar TODOS los $count registro(s)?\n\nEsta acción no se puede deshacer.',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar Todos'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Eliminar todos los paquetes uno por uno
      final packages = List.from(packageProvider.packages);
      for (final package in packages) {
        await packageProvider.deletePackage(package.id!);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count registro(s) eliminado(s)')),
        );
      }
    }
  }
}

// Diálogo de Traslado
class TransferDialog extends StatefulWidget {
  final Package? preselectedPackage;

  const TransferDialog({super.key, this.preselectedPackage});

  @override
  State<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<TransferDialog> {
  String? selectedPackageId;
  String? selectedLocationId;
  String? selectedWarehouseId;

  @override
  void initState() {
    super.initState();
    selectedPackageId = widget.preselectedPackage?.id;

    // Cargar datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PackageProvider>().loadPackages();
      context.read<LocationProvider>().loadLocations();
      context.read<WarehouseProvider>().loadWarehouses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight - 100; // 100px de margen

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: availableHeight > 400 ? availableHeight : 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sync_alt,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Traslado de Paquete',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    iconSize: 22,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPackageSelector(),
                    const SizedBox(height: 24),
                    _buildWarehouseSelector(),
                    const SizedBox(height: 16),
                    _buildLocationSelector(),
                    const SizedBox(height: 16), // Padding fijo
                  ],
                ),
              ),
            ),

            // Footer
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: selectedPackageId != null && selectedLocationId != null
                            ? _performTransfer
                            : null,
                        child: const Text('Trasladar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSelector() {
    return Consumer2<PackageProvider, LocationProvider>(
      builder: (context, packageProvider, locationProvider, child) {
        if (packageProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Obtener el paquete seleccionado para mostrar su ubicación actual
        final selectedPackage = selectedPackageId != null
            ? packageProvider.packages.firstWhere(
                (p) => p.id == selectedPackageId,
                orElse: () => packageProvider.packages.first,
              )
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Paquete',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedPackageId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Paquete',
                prefixIcon: const Icon(Icons.inventory_2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              menuMaxHeight: 300,
              items: () {
                // Filtrar IDs duplicados manteniendo el primer paquete
                final seen = <String>{};
                return packageProvider.packages
                    .where((package) {
                      if (package.id == null) return false;
                      if (seen.contains(package.id)) return false;
                      seen.add(package.id!);
                      return true;
                    })
                    .map((package) {
                      return DropdownMenuItem<String>(
                        value: package.id,
                        child: Text(
                          '${package.trackingNumber} - ${package.recipientName}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList();
              }(),
              onChanged: (value) {
                setState(() {
                  selectedPackageId = value;
                });
              },
            ),
            // Mostrar ubicación actual si existe
            if (selectedPackage?.locationId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ubicación actual: ${_getCurrentLocationName(selectedPackage!.locationId!, locationProvider)}\nSe reemplazará por la nueva ubicación',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _getCurrentLocationName(String locationId, LocationProvider provider) {
    try {
      final location = provider.locations.firstWhere((l) => l.id == locationId);
      return location.code;
    } catch (e) {
      return 'Ubicación #$locationId';
    }
  }

  Widget _buildWarehouseSelector() {
    return Consumer<WarehouseProvider>(
      builder: (context, warehouseProvider, child) {
        if (warehouseProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Almacén de Destino',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedWarehouseId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Almacén',
                prefixIcon: const Icon(Icons.warehouse),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              menuMaxHeight: 300,
              items: warehouseProvider.activeWarehouses.map((warehouse) {
                return DropdownMenuItem<String>(
                  value: warehouse.id,
                  child: Text(
                    warehouse.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedWarehouseId = value;
                  selectedLocationId = null; // Reset location when warehouse changes
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationSelector() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        if (locationProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filtrar ubicaciones por almacén seleccionado
        final availableLocations = selectedWarehouseId != null
            ? locationProvider.locations
                .where((l) => l.warehouseId == selectedWarehouseId && l.isAvailable)
                .toList()
            : <Location>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ubicación Específica',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (selectedWarehouseId == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Primero selecciona un almacén',
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              )
            else if (availableLocations.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_outlined, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No hay ubicaciones disponibles en este almacén',
                        style: TextStyle(color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedLocationId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Ubicación',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                menuMaxHeight: 300,
                items: availableLocations.map((location) {
                  return DropdownMenuItem<String>(
                    value: location.id,
                    child: Text(
                      '${location.code} (S:${location.section ?? "N/A"} E:${location.shelf ?? "N/A"} N:${location.level ?? "N/A"})',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedLocationId = value;
                  });
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _performTransfer() async {
    if (selectedPackageId == null || selectedLocationId == null) return;

    try {
      // Obtener el paquete y la ubicación seleccionados
      final packageProvider = context.read<PackageProvider>();
      final locationProvider = context.read<LocationProvider>();

      final selectedPackage = packageProvider.packages.firstWhere(
        (p) => p.id == selectedPackageId,
      );

      final selectedLocation = locationProvider.locations.firstWhere(
        (l) => l.id == selectedLocationId,
      );

      // Obtener ubicación anterior si existe
      String? previousLocationName;
      if (selectedPackage.locationId != null) {
        try {
          final previousLocation = locationProvider.locations.firstWhere(
            (l) => l.id == selectedPackage.locationId,
          );
          previousLocationName = previousLocation.code;
        } catch (e) {
          previousLocationName = 'Ubicación #${selectedPackage.locationId}';
        }
      }

      // Actualizar el paquete con la nueva ubicación (reemplaza la anterior)
      final updatedPackage = selectedPackage.copyWith(
        locationId: selectedLocation.id,
        warehouseId: selectedWarehouseId,
        status: 'En almacén', // Actualizar estado
      );

      await packageProvider.updatePackage(updatedPackage);

      if (mounted) {
        Navigator.pop(context);

        // Mensaje diferente si había ubicación anterior o no
        final message = previousLocationName != null
            ? 'Paquete ${selectedPackage.trackingNumber} trasladado de "$previousLocationName" a "${selectedLocation.code}"'
            : 'Paquete ${selectedPackage.trackingNumber} asignado a "${selectedLocation.code}"';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                // Opcional: navegar a detalles del paquete
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar el traslado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
