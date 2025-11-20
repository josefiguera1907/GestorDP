class Warehouse {
  final String? id;
  final String name;
  final String? address;
  final String? description;
  final bool isActive;

  Warehouse({
    this.id,
    required this.name,
    this.address,
    this.description,
    this.isActive = true,
  });

  Warehouse copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    bool? isActive,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'description': description,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Warehouse.fromMap(Map<String, dynamic> map) {
    return Warehouse(
      id: map['id']?.toString(),
      name: map['name'] as String,
      address: map['address'] as String?,
      description: map['description'] as String?,
      isActive: map['isActive'] == 1,
    );
  }
}
