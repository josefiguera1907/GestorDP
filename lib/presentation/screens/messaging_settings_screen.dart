import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessagingSettingsScreen extends StatefulWidget {
  const MessagingSettingsScreen({super.key});

  @override
  State<MessagingSettingsScreen> createState() => _MessagingSettingsScreenState();
}

class _MessagingSettingsScreenState extends State<MessagingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageTemplateController = TextEditingController();
  bool _isLoading = false;
  List<String> _savedTemplates = [];
  int? _editingTemplateIndex; // Índice de la plantilla que se está editando

  // Variables disponibles para el template
  final List<Map<String, String>> _availableVariables = [
    {'key': '{guia}', 'desc': 'Número de guía'},
    {'key': '{destinatario}', 'desc': 'Nombre del destinatario'},
    {'key': '{remitente}', 'desc': 'Nombre del remitente'},
    {'key': '{ubicacion}', 'desc': 'Ubicación del paquete'},
    {'key': '{almacen}', 'desc': 'Almacén donde está el paquete'},
    {'key': '{fecha}', 'desc': 'Fecha de registro'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final template = prefs.getString('message_template') ?? _getDefaultTemplate();
      _messageTemplateController.text = template;

      // Cargar plantillas guardadas
      final templatesJson = prefs.getString('saved_message_templates');
      if (templatesJson != null) {
        _savedTemplates = List<String>.from(jsonDecode(templatesJson));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar configuración: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getDefaultTemplate() {
    return '🎉 ¡Hola {destinatario}!\n\n'
        'Tu paquete con guía #{guia} ha sido registrado exitosamente.\n\n'
        '📦 Remitente: {remitente}\n'
        '🏢 Almacén: {almacen}\n'
        '📍 Ubicación: {ubicacion}\n'
        '📅 Fecha: {fecha}\n\n'
        'Gracias por confiar en nosotros.';
  }

  Future<void> _addToTemplateList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final template = _messageTemplateController.text.trim();

    // Si estamos editando una plantilla existente
    if (_editingTemplateIndex != null) {
      setState(() {
        _savedTemplates[_editingTemplateIndex!] = template;
        _editingTemplateIndex = null; // Salir del modo edición
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_message_templates', jsonEncode(_savedTemplates));
        await prefs.setString('message_template', template);

        if (mounted) {
          // Limpiar el campo de texto
          _messageTemplateController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Plantilla actualizada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al actualizar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
      return;
    }

    // Verificar si ya existe (solo al agregar nueva)
    if (_savedTemplates.contains(template)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Esta plantilla ya existe en la lista'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _savedTemplates.add(template);
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Guardar lista de plantillas
      await prefs.setString('saved_message_templates', jsonEncode(_savedTemplates));

      // También guardar como plantilla principal
      await prefs.setString('message_template', template);

      if (mounted) {
        // Limpiar el campo de texto
        _messageTemplateController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Plantilla agregada y guardada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeTemplate(int index) async {
    setState(() {
      _savedTemplates.removeAt(index);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_message_templates', jsonEncode(_savedTemplates));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Plantilla eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadTemplate(int index) {
    setState(() {
      _messageTemplateController.text = _savedTemplates[index];
      _editingTemplateIndex = index; // Activar modo edición
    });
  }

  void _insertVariable(String variable) {
    final text = _messageTemplateController.text;
    final selection = _messageTemplateController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      variable,
    );
    _messageTemplateController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + variable.length,
      ),
    );
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restaurar plantilla'),
          content: const Text('¿Deseas restaurar la plantilla predeterminada?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _messageTemplateController.text = _getDefaultTemplate();
                  _editingTemplateIndex = null; // Salir del modo edición
                });
                Navigator.pop(context);
              },
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );
  }

  void _cancelEdit() {
    setState(() {
      _messageTemplateController.clear();
      _editingTemplateIndex = null;
    });
  }

  @override
  void dispose() {
    _messageTemplateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Mensajería'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: 'Información sobre el cambio',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sistema de Mensajería Actualizado'),
                  content: const Text(
                    'Este sistema de configuración de plantillas está siendo reemplazado por el nuevo sistema de META.\n\n'
                    'Las plantillas aquí configuradas aún pueden ser usadas, pero se recomienda usar la nueva configuración de META.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.message,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Personaliza tu mensaje',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este mensaje se enviará a los destinatarios cuando presiones el botón "Mensaje" en un registro.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Advertencia sobre nuevo sistema
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '⚠️ Este sistema está siendo reemplazado por el nuevo sistema de META. Se recomienda usar la nueva configuración.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Template Field
                    Text(
                      'Plantilla del mensaje',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageTemplateController,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu mensaje aquí...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        helperText: 'Usa las variables para personalizar el mensaje',
                      ),
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa una plantilla de mensaje';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Variables disponibles
                    Text(
                      'Variables disponibles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableVariables.map((variable) {
                        return ActionChip(
                          avatar: const Icon(Icons.add, size: 16),
                          label: Text(variable['key']!),
                          tooltip: variable['desc'],
                          onPressed: () => _insertVariable(variable['key']!),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Buttons row
                    Row(
                      children: [
                        if (_editingTemplateIndex != null) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _cancelEdit,
                              icon: const Icon(Icons.close),
                              label: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _addToTemplateList,
                            icon: Icon(_editingTemplateIndex != null ? Icons.edit : Icons.add),
                            label: Text(_editingTemplateIndex != null ? 'Editar Plantilla' : 'Agregar a Lista'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Saved Templates Section
                    if (_savedTemplates.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.list_alt, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Plantillas guardadas (${_savedTemplates.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.purple.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.purple.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Al enviar mensajes, se alternará entre estas plantillas para evitar ser marcado como spam.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.purple.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _savedTemplates.length,
                        itemBuilder: (context, index) {
                          final template = _savedTemplates[index];
                          final isEditing = _editingTemplateIndex == index;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isEditing ? Colors.blue.shade50 : null,
                            child: ListTile(
                              title: Text(
                                template.length > 80
                                    ? '${template.substring(0, 80)}...'
                                    : template,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isEditing ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              leading: isEditing
                                  ? Icon(Icons.edit, color: Colors.blue.shade700)
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    tooltip: 'Editar plantilla',
                                    onPressed: () => _loadTemplate(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    tooltip: 'Eliminar plantilla',
                                    onPressed: () => _removeTemplate(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Info Card
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Las variables se reemplazarán automáticamente con los datos del paquete al enviar el mensaje.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
