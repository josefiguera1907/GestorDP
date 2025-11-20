class Location {
  final String? id;
  final String name; // Nombre de la ubicación
  final String warehouseId;
  final String? section; // Sección
  final String? shelf; // Estante
  final String? level; // Nivel
  final String? description; // Descripción
  final bool isAvailable;

  Location({
    this.id,
    required this.name,
    required this.warehouseId,
    this.section,
    this.shelf,
    this.level,
    this.description,
    this.isAvailable = true,
  });

  // Genera un código automático basado en sección, estante y nivel
  String get code {
    if (section != null && shelf != null && level != null) {
      return '$section-$shelf-$level';
    }
    return name;
  }

  Location copyWith({
    String? id,
    String? name,
    String? warehouseId,
    String? section,
    String? shelf,
    String? level,
    String? description,
    bool? isAvailable,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      warehouseId: warehouseId ?? this.warehouseId,
      section: section ?? this.section,
      shelf: shelf ?? this.shelf,
      level: level ?? this.level,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'warehouseId': warehouseId,
      'section': section,
      'shelf': shelf,
      'level': level,
      'description': description,
      'isAvailable': isAvailable ? 1 : 0,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id']?.toString(),
      name: map['name'] as String,
      warehouseId: map['warehouseId']?.toString() ?? '',
      section: map['section'] as String?,
      shelf: map['shelf'] as String?,
      level: map['level'] as String?,
      description: map['description'] as String?,
      isAvailable: map['isAvailable'] == 1,
    );
  }
}
