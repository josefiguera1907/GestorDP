class Package {
  final String? id;
  final String trackingNumber;

  // Datos del remitente
  final String senderName;
  final String senderPhone;
  final String? senderEmail;
  final String? senderIdType; // 'DNI', 'Pasaporte', 'RUC', etc.
  final String? senderIdNumber;

  // Datos del destinatario
  final String recipientName;
  final String recipientPhone;
  final String? recipientIdType;
  final String? recipientIdNumber;

  // Detalles del paquete
  final double? weight; // en kg

  // Status y ubicación
  final String status; // 'Pendiente', 'En tránsito', 'Entregado'
  final String? locationId;
  final String? warehouseId;

  // Fechas y notificaciones
  final DateTime registeredDate;
  final DateTime? deliveredDate;
  final bool notified;
  final String? notes;

  // QR original completo
  final String? originalQRData;

  Package({
    this.id,
    required this.trackingNumber,
    required this.senderName,
    required this.senderPhone,
    this.senderEmail,
    this.senderIdType,
    this.senderIdNumber,
    required this.recipientName,
    required this.recipientPhone,
    this.recipientIdType,
    this.recipientIdNumber,
    this.weight,
    this.status = 'Pendiente',
    this.locationId,
    this.warehouseId,
    required this.registeredDate,
    this.deliveredDate,
    this.notified = false,
    this.notes,
    this.originalQRData,
  });

  Package copyWith({
    String? id,
    String? trackingNumber,
    String? senderName,
    String? senderPhone,
    String? senderEmail,
    String? senderIdType,
    String? senderIdNumber,
    String? recipientName,
    String? recipientPhone,
    String? recipientIdType,
    String? recipientIdNumber,
    double? weight,
    String? status,
    String? locationId,
    String? warehouseId,
    DateTime? registeredDate,
    DateTime? deliveredDate,
    bool? notified,
    String? notes,
    String? originalQRData,
  }) {
    return Package(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      senderEmail: senderEmail ?? this.senderEmail,
      senderIdType: senderIdType ?? this.senderIdType,
      senderIdNumber: senderIdNumber ?? this.senderIdNumber,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientIdType: recipientIdType ?? this.recipientIdType,
      recipientIdNumber: recipientIdNumber ?? this.recipientIdNumber,
      weight: weight ?? this.weight,
      status: status ?? this.status,
      locationId: locationId ?? this.locationId,
      warehouseId: warehouseId ?? this.warehouseId,
      registeredDate: registeredDate ?? this.registeredDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      notified: notified ?? this.notified,
      notes: notes ?? this.notes,
      originalQRData: originalQRData ?? this.originalQRData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'senderEmail': senderEmail,
      'senderIdType': senderIdType,
      'senderIdNumber': senderIdNumber,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'recipientIdType': recipientIdType,
      'recipientIdNumber': recipientIdNumber,
      'weight': weight,
      'status': status,
      'locationId': locationId,
      'warehouseId': warehouseId,
      'registeredDate': registeredDate.toIso8601String(),
      'deliveredDate': deliveredDate?.toIso8601String(),
      'notified': notified ? 1 : 0,
      'notes': notes,
      'originalQRData': originalQRData,
    };
  }

  factory Package.fromMap(Map<String, dynamic> map) {
    return Package(
      id: map['id']?.toString(),
      trackingNumber: map['trackingNumber'] as String,
      senderName: map['senderName'] as String,
      senderPhone: map['senderPhone'] as String,
      senderEmail: map['senderEmail'] as String?,
      senderIdType: map['senderIdType'] as String?,
      senderIdNumber: map['senderIdNumber'] as String?,
      recipientName: map['recipientName'] as String,
      recipientPhone: map['recipientPhone'] as String,
      recipientIdType: map['recipientIdType'] as String?,
      recipientIdNumber: map['recipientIdNumber'] as String?,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      status: map['status'] as String? ?? 'Pendiente',
      locationId: map['locationId']?.toString(),
      warehouseId: map['warehouseId']?.toString(),
      registeredDate: DateTime.parse(map['registeredDate'] as String),
      deliveredDate: map['deliveredDate'] != null
          ? DateTime.parse(map['deliveredDate'] as String)
          : null,
      notified: map['notified'] == 1,
      notes: map['notes'] as String?,
      originalQRData: map['originalQRData'] as String?,
    );
  }
}
