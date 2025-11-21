import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import '../../domain/entities/warehouse.dart';
import '../providers/warehouse_provider.dart';
import '../providers/auth_provider.dart';

class WarehousesScreen extends StatelessWidget {
  final Function(String warehouseId)? onWarehouseTap;

  const WarehousesScreen({super.key, this.onWarehouseTap});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canManage = authProvider.currentUser?.canManageWarehouses ?? true;

    return Consumer<WarehouseProvider>(
      // Agregar key para mejorar la gestión del estado y rendimiento
      builder: (context, warehouseProvider, child) {
        if (warehouseProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (warehouseProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(warehouseProvider.error!),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => warehouseProvider.loadWarehouses(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final warehouses = warehouseProvider.warehouses;

        if (warehouses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warehouse_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No hay almacenes registrados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                if (canManage)
                  FilledButton.icon(
                    onPressed: () => _showWarehouseDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Primer Almacén'),
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
                    '${warehouses.length} Almacén(es)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (canManage)
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _confirmDeleteAll(context),
                          icon: const Icon(Icons.delete_sweep),
                          color: Colors.red,
                          tooltip: 'Eliminar todos',
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => _showWarehouseDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Nuevo'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => warehouseProvider.loadWarehouses(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: warehouses.length,
                  physics: const ClampingScrollPhysics(), // Mejora percepción táctil
                  itemBuilder: (context, index) {
                    final warehouse = warehouses[index];
                    return _WarehouseCard(
                      key: ValueKey(warehouse.id),
                      warehouse: warehouse,
                      canManage: canManage,
                      onWarehouseTap: onWarehouseTap,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  void _showWarehouseDialog(BuildContext context, {Warehouse? warehouse}) {
    showDialog(
      context: context,
      builder: (context) => WarehouseFormDialog(warehouse: warehouse),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final warehouseProvider = context.read<WarehouseProvider>();
    final count = warehouseProvider.warehouses.length;

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay almacenes para eliminar')),
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
            '¿Está seguro que desea eliminar TODOS los $count almacén(es)?\n\nEsta acción no se puede deshacer.',
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
      // Eliminar todos los almacenes uno por uno
      final warehouses = List.from(warehouseProvider.warehouses);
      for (final warehouse in warehouses) {
        await warehouseProvider.deleteWarehouse(warehouse.id!);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count almacén(es) eliminado(s)')),
        );
      }
    }
  }
}

class WarehouseFormDialog extends StatefulWidget {
  final Warehouse? warehouse;

  const WarehouseFormDialog({super.key, this.warehouse});

  @override
  State<WarehouseFormDialog> createState() => _WarehouseFormDialogState();
}

class _WarehouseFormDialogState extends State<WarehouseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.warehouse?.name ?? '');
    _addressController = TextEditingController(text: widget.warehouse?.address ?? '');
    _descriptionController = TextEditingController(text: widget.warehouse?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.warehouse == null ? 'Nuevo Almacén' : 'Editar Almacén'),
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
                  labelText: 'Nombre *',
                  prefixIcon: Icon(Icons.warehouse),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el nombre del almacén';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
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
      final warehouse = Warehouse(
        id: widget.warehouse?.id,
        name: _nameController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        isActive: widget.warehouse?.isActive ?? true,
      );

      if (mounted) {
        if (widget.warehouse == null) {
          await context.read<WarehouseProvider>().addWarehouse(warehouse);
        } else {
          await context.read<WarehouseProvider>().updateWarehouse(warehouse);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.warehouse == null
                    ? 'Almacén creado exitosamente'
                    : 'Almacén actualizado exitosamente',
              ),
            ),
          );

          // Forzar recarga de datos para asegurar que se reflejen correctamente
          // en otras pantallas que dependan de la información de almacenes
          Future.delayed(Duration(milliseconds: 500), () {
            context.read<WarehouseProvider>().loadWarehouses();
          });
        }
      }
    }
  }
}

class _WarehouseCard extends StatelessWidget {
  final Warehouse warehouse;
  final bool canManage;
  final Function(String warehouseId)? onWarehouseTap;

  const _WarehouseCard({
    super.key,
    required this.warehouse,
    required this.canManage,
    this.onWarehouseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (onWarehouseTap != null) {
            onWarehouseTap!(warehouse.id!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warehouse,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warehouse.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (warehouse.address != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  warehouse.address!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (canManage)
                    PopupMenuButton(
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          showDialog(
                            context: context,
                            builder: (context) => WarehouseFormDialog(warehouse: warehouse),
                          );
                        } else if (value == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                    ),
                ],
              ),
              if (warehouse.description != null && warehouse.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  warehouse.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Almacén'),
        content: Text(
          '¿Está seguro que desea eliminar "${warehouse.name}"?\n\nEsta acción no se puede deshacer.',
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
      await context.read<WarehouseProvider>().deleteWarehouse(warehouse.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Almacén eliminado')),
        );
      }
    }
  }
}
