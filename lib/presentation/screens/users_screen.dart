import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/user.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Agregar usuario',
              onPressed: () => _showUserDialog(context),
            ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay usuarios registrados',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.users.length,
            itemBuilder: (context, index) {
              final user = provider.users[index];
              final isCurrentUser = user.id == authProvider.currentUser?.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.isActive
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.grey[300],
                    child: Icon(
                      user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                      color: user.isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600],
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tú',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('@${user.username}'),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (user.isAdmin) _buildAdminChip(),
                          if (user.isAdmin) const SizedBox(width: 8),
                          _buildStatusChip(user.isActive),
                        ],
                      ),
                      if (user.lastLogin != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Último acceso: ${_formatDate(user.lastLogin!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: isAdmin
                      ? PopupMenuButton<String>(
                          onSelected: (value) =>
                              _handleMenuAction(context, value, user),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 12),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'password',
                              child: Row(
                                children: [
                                  Icon(Icons.lock_reset, size: 20),
                                  SizedBox(width: 12),
                                  Text('Cambiar contraseña'),
                                ],
                              ),
                            ),
                            // Solo mostrar activar/desactivar si NO es admin
                            if (!user.isAdmin)
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      user.isActive
                                          ? Icons.block
                                          : Icons.check_circle,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(user.isActive
                                        ? 'Desactivar'
                                        : 'Activar'),
                                  ],
                                ),
                              ),
                            // Solo mostrar eliminar si NO es admin y NO es el usuario actual
                            if (!user.isAdmin && !isCurrentUser)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text('Eliminar',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAdminChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: const Text(
        'Admin',
        style: TextStyle(
          fontSize: 11,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Text(
        isActive ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 11,
          color: isActive ? Colors.green : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  void _handleMenuAction(BuildContext context, String action, User user) {
    switch (action) {
      case 'edit':
        _showUserDialog(context, user: user);
        break;
      case 'password':
        _showPasswordDialog(context, user);
        break;
      case 'toggle':
        _toggleUserStatus(context, user);
        break;
      case 'delete':
        _confirmDelete(context, user);
        break;
    }
  }

  void _showUserDialog(BuildContext context, {User? user}) {
    final isEdit = user != null;
    final usernameController = TextEditingController(text: user?.username);
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController(text: user?.fullName);
    final emailController = TextEditingController(text: user?.email);

    // Permisos individuales
    bool canManageUsers = user?.canManageUsers ?? false;
    bool canManageWarehouses = user?.canManageWarehouses ?? false;
    bool canManageLocations = user?.canManageLocations ?? false;
    bool canManagePackages = user?.canManagePackages ?? false;
    bool canDeletePackages = user?.canDeletePackages ?? false;
    bool canScanQR = user?.canScanQR ?? true;
    bool canSendMessages = user?.canSendMessages ?? false;
    bool canConfigureSystem = user?.canConfigureSystem ?? false;
    bool canBackupRestore = user?.canBackupRestore ?? false;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEdit ? 'Editar Usuario' : 'Nuevo Usuario'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (!isEdit)
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña *',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      if (value.length < 4) {
                        return 'Mínimo 4 caracteres';
                      }
                      return null;
                    },
                  ),
                if (!isEdit) const SizedBox(height: 12),
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (opcional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Permisos del Usuario',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        CheckboxListTile(
                          title: const Text('Gestionar Usuarios'),
                          subtitle: const Text('Crear, editar y eliminar usuarios'),
                          value: canManageUsers,
                          onChanged: (value) {
                            setState(() => canManageUsers = value ?? false);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Gestionar Almacenes'),
                          subtitle: const Text('Crear y editar almacenes'),
                          value: canManageWarehouses,
                          onChanged: (value) {
                            setState(() => canManageWarehouses = value ?? false);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Gestionar Ubicaciones'),
                          subtitle: const Text('Crear y editar ubicaciones'),
                          value: canManageLocations,
                          onChanged: (value) {
                            setState(() => canManageLocations = value ?? false);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Gestionar Paquetes'),
                          subtitle: const Text('Registrar y editar paquetes'),
                          value: canManagePackages,
                          onChanged: (value) {
                            setState(() => canManagePackages = value ?? false);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Eliminar Paquetes'),
                          subtitle: const Text('Eliminar registros de paquetes'),
                          value: canDeletePackages,
                          onChanged: (value) {
                            setState(() => canDeletePackages = value ?? false);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Escanear Códigos QR'),
                          subtitle: const Text('Usar escáner para registrar paquetes'),
                          value: canScanQR,
                          onChanged: (value) {
                            setState(() => canScanQR = value ?? false);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Enviar Mensajes'),
                          subtitle: const Text('Notificar a clientes vía WhatsApp'),
                          value: canSendMessages,
                          onChanged: (value) {
                            setState(() => canSendMessages = value ?? false);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Configurar Sistema'),
                          subtitle: const Text('Acceder a configuraciones'),
                          value: canConfigureSystem,
                          onChanged: (value) {
                            setState(() => canConfigureSystem = value ?? false);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          title: const Text('Backup y Restauración'),
                          subtitle: const Text('Exportar e importar datos'),
                          value: canBackupRestore,
                          onChanged: (value) {
                            setState(() => canBackupRestore = value ?? false);
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final provider = context.read<UserProvider>();
              bool success;

              if (isEdit) {
                final updatedUser = user.copyWith(
                  username: usernameController.text.trim(),
                  fullName: fullNameController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  canManageUsers: canManageUsers,
                  canManageWarehouses: canManageWarehouses,
                  canManageLocations: canManageLocations,
                  canManagePackages: canManagePackages,
                  canDeletePackages: canDeletePackages,
                  canScanQR: canScanQR,
                  canSendMessages: canSendMessages,
                  canConfigureSystem: canConfigureSystem,
                  canBackupRestore: canBackupRestore,
                );
                success = await provider.updateUser(updatedUser);
              } else {
                final newUser = User(
                  username: usernameController.text.trim(),
                  password: passwordController.text,
                  fullName: fullNameController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  createdDate: DateTime.now(),
                  canManageUsers: canManageUsers,
                  canManageWarehouses: canManageWarehouses,
                  canManageLocations: canManageLocations,
                  canManagePackages: canManagePackages,
                  canDeletePackages: canDeletePackages,
                  canScanQR: canScanQR,
                  canSendMessages: canSendMessages,
                  canConfigureSystem: canConfigureSystem,
                  canBackupRestore: canBackupRestore,
                );
                success = await provider.createUser(newUser);
              }

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre de usuario ya existe'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit
                          ? 'Usuario actualizado'
                          : 'Usuario creado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, User user) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Usuario: ${user.username}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo requerido';
                  }
                  if (value.length < 4) {
                    return 'Mínimo 4 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value != passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final provider = context.read<UserProvider>();
              await provider.changePassword(
                user.id!,
                passwordController.text,
              );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contraseña actualizada'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(BuildContext context, User user) {
    // Si intenta desactivar un administrador, mostrar advertencia
    if (user.isAdmin && user.isActive) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Text('Acción no permitida'),
            ],
          ),
          content: const Text(
            'No se puede desactivar a un usuario administrador.\n\n'
            'Los administradores deben permanecer activos para garantizar el acceso al sistema.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final provider = context.read<UserProvider>();
    provider.toggleUserStatus(user.id!, !user.isActive);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user.isActive ? 'Usuario desactivado' : 'Usuario activado',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmDelete(BuildContext context, User user) {
    // Si intenta eliminar un administrador, mostrar advertencia
    if (user.isAdmin) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Text('Acción no permitida'),
            ],
          ),
          content: const Text(
            'No se puede eliminar a un usuario administrador.\n\n'
            'Para eliminar este usuario, primero debe remover todos sus permisos de administrador.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text(
          '¿Está seguro que desea eliminar al usuario "${user.fullName}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final provider = context.read<UserProvider>();
              provider.deleteUser(user.id!);

              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Usuario eliminado'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
