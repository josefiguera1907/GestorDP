class Transfer {
  final String? id;
  final String packageId;
  final String fromLocationId;
  final String toLocationId;
  final DateTime transferDate;
  final String? performedBy;
  final String? reason;

  Transfer({
    this.id,
    required this.packageId,
    required this.fromLocationId,
    required this.toLocationId,
    required this.transferDate,
    this.performedBy,
    this.reason,
  });

  Transfer copyWith({
    String? id,
    String? packageId,
    String? fromLocationId,
    String? toLocationId,
    DateTime? transferDate,
    String? performedBy,
    String? reason,
  }) {
    return Transfer(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      fromLocationId: fromLocationId ?? this.fromLocationId,
      toLocationId: toLocationId ?? this.toLocationId,
      transferDate: transferDate ?? this.transferDate,
      performedBy: performedBy ?? this.performedBy,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageId': packageId,
      'fromLocationId': fromLocationId,
      'toLocationId': toLocationId,
      'transferDate': transferDate.toIso8601String(),
      'performedBy': performedBy,
      'reason': reason,
    };
  }

  factory Transfer.fromMap(Map<String, dynamic> map) {
    return Transfer(
      id: map['id']?.toString(),
      packageId: map['packageId']?.toString() ?? '',
      fromLocationId: map['fromLocationId']?.toString() ?? '',
      toLocationId: map['toLocationId']?.toString() ?? '',
      transferDate: DateTime.parse(map['transferDate'] as String),
      performedBy: map['performedBy'] as String?,
      reason: map['reason'] as String?,
    );
  }
}
