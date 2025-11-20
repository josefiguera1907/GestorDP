class User {
  final String? id;
  final String username;
  final String password;
  final String fullName;
  final String? email;
  final bool isActive;
  final DateTime createdDate;
  final DateTime? lastLogin;

  // Permisos individuales
  final bool canManageUsers;
  final bool canManageWarehouses;
  final bool canManageLocations;
  final bool canManagePackages;
  final bool canDeletePackages;
  final bool canScanQR;
  final bool canSendMessages;
  final bool canConfigureSystem;
  final bool canBackupRestore;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    this.email,
    this.isActive = true,
    required this.createdDate,
    this.lastLogin,
    this.canManageUsers = false,
    this.canManageWarehouses = false,
    this.canManageLocations = false,
    this.canManagePackages = false,
    this.canDeletePackages = false,
    this.canScanQR = true,
    this.canSendMessages = false,
    this.canConfigureSystem = false,
    this.canBackupRestore = false,
  });

  // Helper para saber si tiene todos los permisos (es super admin)
  bool get isAdmin =>
    canManageUsers &&
    canManageWarehouses &&
    canManageLocations &&
    canManagePackages &&
    canDeletePackages &&
    canScanQR &&
    canSendMessages &&
    canConfigureSystem &&
    canBackupRestore;

  User copyWith({
    String? id,
    String? username,
    String? password,
    String? fullName,
    String? email,
    bool? isActive,
    DateTime? createdDate,
    DateTime? lastLogin,
    bool? canManageUsers,
    bool? canManageWarehouses,
    bool? canManageLocations,
    bool? canManagePackages,
    bool? canDeletePackages,
    bool? canScanQR,
    bool? canSendMessages,
    bool? canConfigureSystem,
    bool? canBackupRestore,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate ?? this.createdDate,
      lastLogin: lastLogin ?? this.lastLogin,
      canManageUsers: canManageUsers ?? this.canManageUsers,
      canManageWarehouses: canManageWarehouses ?? this.canManageWarehouses,
      canManageLocations: canManageLocations ?? this.canManageLocations,
      canManagePackages: canManagePackages ?? this.canManagePackages,
      canDeletePackages: canDeletePackages ?? this.canDeletePackages,
      canScanQR: canScanQR ?? this.canScanQR,
      canSendMessages: canSendMessages ?? this.canSendMessages,
      canConfigureSystem: canConfigureSystem ?? this.canConfigureSystem,
      canBackupRestore: canBackupRestore ?? this.canBackupRestore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
      'email': email,
      'isActive': isActive ? 1 : 0,
      'createdDate': createdDate.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'canManageUsers': canManageUsers ? 1 : 0,
      'canManageWarehouses': canManageWarehouses ? 1 : 0,
      'canManageLocations': canManageLocations ? 1 : 0,
      'canManagePackages': canManagePackages ? 1 : 0,
      'canDeletePackages': canDeletePackages ? 1 : 0,
      'canScanQR': canScanQR ? 1 : 0,
      'canSendMessages': canSendMessages ? 1 : 0,
      'canConfigureSystem': canConfigureSystem ? 1 : 0,
      'canBackupRestore': canBackupRestore ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(),
      username: map['username'] as String,
      password: map['password'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String?,
      isActive: map['isActive'] == 1,
      createdDate: DateTime.parse(map['createdDate'] as String),
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'] as String)
          : null,
      canManageUsers: map['canManageUsers'] == 1,
      canManageWarehouses: map['canManageWarehouses'] == 1,
      canManageLocations: map['canManageLocations'] == 1,
      canManagePackages: map['canManagePackages'] == 1,
      canDeletePackages: map['canDeletePackages'] == 1,
      canScanQR: map['canScanQR'] == 1,
      canSendMessages: map['canSendMessages'] == 1,
      canConfigureSystem: map['canConfigureSystem'] == 1,
      canBackupRestore: map['canBackupRestore'] == 1,
    );
  }
}
