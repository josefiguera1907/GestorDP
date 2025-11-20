import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/location.dart';
import '../providers/location_provider.dart';
import '../providers/warehouse_provider.dart';
import '../providers/package_provider.dart';
import '../providers/auth_provider.dart';

class LocationsScreen extends StatefulWidget {
  final String? filterWarehouseId; // Filtro opcional por almacén
  final Function(String locationId)? onLocationTap;
  final VoidCallback? onFilterClear; // Callback para limpiar filtro

  const LocationsScreen({
    super.key,
    this.filterWarehouseId,
    this.onLocationTap,
    this.onFilterClear,
  });

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  bool _filterApplied = false;

  @override
  void didUpdateWidget(LocationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió el filtro, permitir aplicarlo nuevamente
    if (widget.filterWarehouseId != oldWidget.filterWarehouseId) {
      _filterApplied = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canManage = authProvider.currentUser?.canManageLocations ?? true;

    return Consumer3<WarehouseProvider, LocationProvider, PackageProvider>(
      builder: (context, warehouseProvider, locationProvider, packageProvider, child) {
        // Si hay filtro de almacén y no se ha aplicado todavía, aplicarlo una sola vez
        if (widget.filterWarehouseId != null &&
            !_filterApplied &&
            warehouseProvider.warehouses.isNotEmpty) {
          final filteredWarehouse = warehouseProvider.warehouses.firstWhere(
            (w) => w.id == widget.filterWarehouseId,
            orElse: () => warehouseProvider.warehouses.first,
          );

          // Seleccionar el almacén filtrado solo una vez
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (warehouseProvider.selectedWarehouse?.id != widget.filterWarehouseId) {
              warehouseProvider.selectWarehouse(filteredWarehouse);
              setState(() {
                _filterApplied = true;
              });
            }
          });
        }

        // Warehouse selector
        return Column(
          children: [
            // Chip de filtro activo (si existe)
            if (widget.filterWarehouseId != null)
              Consumer<WarehouseProvider>(
                builder: (context, warehouseProvider, child) {
                  // Obtener nombre del almacén
                  String warehouseName = 'Almacén desconocido';
                  try {
                    final warehouse = warehouseProvider.warehouses.firstWhere(
                      (w) => w.id == widget.filterWarehouseId,
                    );
                    warehouseName = warehouse.name;
                  } catch (e) {
                    warehouseName = 'Almacén #${widget.filterWarehouseId}';
                  }

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, size: 20, color: Colors.purple.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filtrando por: $warehouseName',
                            style: TextStyle(
                              color: Colors.purple.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20, color: Colors.purple.shade700),
                          onPressed: () {
                            // Llamar callback para limpiar filtro
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
            if (warehouseProvider.warehouses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'No hay almacenes disponibles',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Por favor, crea un almacén primero en la pestaña de Almacenes',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warehouse, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: warehouseProvider.selectedWarehouse?.id,
                        decoration: const InputDecoration(
                          labelText: 'Almacén',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: warehouseProvider.activeWarehouses.map((warehouse) {
                          return DropdownMenuItem<String>(
                            value: warehouse.id,
                            child: Text(warehouse.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final selected = warehouseProvider.warehouses
                                .firstWhere((w) => w.id == value);
                            warehouseProvider.selectWarehouse(selected);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Locations list
            Expanded(
              child: _buildLocationsList(
                context,
                warehouseProvider,
                locationProvider,
                packageProvider,
                canManage,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationsList(
    BuildContext context,
    WarehouseProvider warehouseProvider,
    LocationProvider locationProvider,
    PackageProvider packageProvider,
    bool canManage,
  ) {
    if (warehouseProvider.selectedWarehouse == null) {
      return const Center(child: Text('Seleccione un almacén'));
    }

    if (locationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (locationProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(locationProvider.error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => locationProvider.loadLocations(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final warehouseLocations = locationProvider.locations
        .where((l) => l.warehouseId == warehouseProvider.selectedWarehouse!.id)
        .toList();

    if (warehouseLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay ubicaciones en este almacén',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            if (canManage && warehouseProvider.selectedWarehouse?.id != null)
              FilledButton.icon(
                onPressed: () {
                  final warehouseId = warehouseProvider.selectedWarehouse!.id;
                  if (warehouseId != null) {
                    _showLocationDialog(context, warehouseId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: No se pudo obtener el ID del almacén'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear Primera Ubicación'),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${warehouseLocations.length} Ubicación(es)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (canManage)
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _confirmDeleteAll(context, locationProvider),
                      icon: const Icon(Icons.delete_sweep),
                      color: Colors.red,
                      tooltip: 'Eliminar todas',
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: warehouseProvider.selectedWarehouse?.id != null
                          ? () {
                              _showLocationDialog(context, warehouseProvider.selectedWarehouse!.id!);
                            }
                          : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva'),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => locationProvider.loadLocations(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: warehouseLocations.length,
              itemBuilder: (context, index) {
                final location = warehouseLocations[index];
                final packagesInLocation = packageProvider.packages
                    .where((p) => p.locationId == location.id)
                    .length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () {
                      // Usar callback para navegar entre pestañas
                      if (widget.onLocationTap != null) {
                        widget.onLocationTap!(location.id!);
                      }
                    },
                    leading: CircleAvatar(
                      backgroundColor: location.isAvailable
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      child: Icon(
                        location.isAvailable
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: location.isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      location.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          location.name,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (location.section != null)
                          Text(
                            'Sección ${location.section} ${location.shelf != null ? "| Est. ${location.shelf}" : ""} ${location.level != null ? "| Niv. ${location.level}" : ""}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (packagesInLocation > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              packagesInLocation.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) {
                            final items = <PopupMenuEntry>[
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility),
                                    SizedBox(width: 8),
                                    Text('Ver detalles'),
                                  ],
                                ),
                              ),
                            ];

                            if (canManage) {
                              items.addAll([
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ]);
                            }

                            return items;
                          },
                          onSelected: (value) {
                            if (value == 'view') {
                              _showLocationDetails(context, location, packagesInLocation, canManage);
                            } else if (value == 'edit') {
                              _showLocationDialog(
                                context,
                                warehouseProvider.selectedWarehouse!.id!,
                                location: location,
                              );
                            } else if (value == 'delete') {
                              _confirmDeleteLocation(context, location);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showLocationDialog(BuildContext context, String warehouseId, {Location? location}) {
    showDialog(
      context: context,
      builder: (context) => LocationFormDialog(
        warehouseId: warehouseId,
        location: location,
      ),
    );
  }

  void _showLocationDetails(BuildContext context, Location location, int packageCount, bool canManage) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Código: ${location.code}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            if (location.description != null && location.description!.isNotEmpty)
              _buildInfoRow('Descripción', location.description!),
            _buildInfoRow('Sección', location.section ?? 'N/A'),
            _buildInfoRow('Estante', location.shelf ?? 'N/A'),
            _buildInfoRow('Nivel', location.level ?? 'N/A'),
            _buildInfoRow('Estado', location.isAvailable ? 'Disponible' : 'Ocupado'),
            _buildInfoRow('Paquetes', packageCount.toString()),
            const SizedBox(height: 24),
            Row(
              children: [
                if (canManage)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showLocationDialog(context, location.warehouseId, location: location);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                  ),
                if (canManage) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteLocation(BuildContext context, Location location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Ubicación'),
        content: Text(
          '¿Está seguro que desea eliminar la ubicación "${location.code}"?\n\nEsta acción no se puede deshacer.',
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

    if (confirmed == true && context.mounted) {
      await context.read<LocationProvider>().deleteLocation(location.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ubicación eliminada')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, LocationProvider locationProvider) async {
    final count = locationProvider.locations.length;

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ubicaciones para eliminar')),
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
                'Eliminar Todas',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            '¿Está seguro que desea eliminar TODAS las $count ubicación(es)?\n\nEsta acción no se puede deshacer.',
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
            child: const Text('Eliminar Todas'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Eliminar todas las ubicaciones una por una
      final locations = List.from(locationProvider.locations);
      for (final location in locations) {
        await locationProvider.deleteLocation(location.id!);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count ubicación(es) eliminada(s)')),
        );
      }
    }
  }
}

class LocationFormDialog extends StatefulWidget {
  final String warehouseId;
  final Location? location;

  const LocationFormDialog({
    super.key,
    required this.warehouseId,
    this.location,
  });

  @override
  State<LocationFormDialog> createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _sectionController;
  late TextEditingController _shelfController;
  late TextEditingController _levelController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location?.name ?? '');
    _sectionController = TextEditingController(text: widget.location?.section ?? '');
    _shelfController = TextEditingController(text: widget.location?.shelf ?? '');
    _levelController = TextEditingController(text: widget.location?.level ?? '');
    _descriptionController = TextEditingController(text: widget.location?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    _shelfController.dispose();
    _levelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.location == null ? 'Nueva Ubicación' : 'Editar Ubicación'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Ubicación *',
                  hintText: 'Ej: Ubicación A1-01',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el nombre de la ubicación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sectionController,
                decoration: const InputDecoration(
                  labelText: 'Sección',
                  hintText: 'Ej: A',
                  prefixIcon: Icon(Icons.grid_view),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shelfController,
                decoration: const InputDecoration(
                  labelText: 'Estante',
                  hintText: 'Ej: 1',
                  prefixIcon: Icon(Icons.shelves),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _levelController,
                decoration: const InputDecoration(
                  labelText: 'Nivel',
                  hintText: 'Ej: 01',
                  prefixIcon: Icon(Icons.layers),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Descripción de la ubicación',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      try {
        final location = Location(
          id: widget.location?.id,
          name: _nameController.text,
          warehouseId: widget.warehouseId,
          section: _sectionController.text.isEmpty ? null : _sectionController.text,
          shelf: _shelfController.text.isEmpty ? null : _shelfController.text,
          level: _levelController.text.isEmpty ? null : _levelController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          isAvailable: widget.location?.isAvailable ?? true,
        );

        if (mounted) {
          if (widget.location == null) {
            await context.read<LocationProvider>().addLocation(location);
          } else {
            await context.read<LocationProvider>().updateLocation(location);
          }

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.location == null
                      ? 'Ubicación creada exitosamente'
                      : 'Ubicación actualizada exitosamente',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar ubicación: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
