import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      print('📂 Database path: $dbPath');

      // Asegurar que el directorio existe
      final directory = Directory(dbPath);
      if (!await directory.exists()) {
        print('📁 Creando directorio de base de datos...');
        await directory.create(recursive: true);
      }

      final path = join(dbPath, 'paqueteria.db');
      print('📄 Database file: $path');

      return await openDatabase(
        path,
        version: 10, // Incrementado para forzar upgrade y verificar usuario admin
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          // Configuraciones optimizadas para dispositivos de baja RAM
          try {
            // Modo WAL para mejor rendimiento
            await db.rawQuery('PRAGMA journal_mode = WAL');
            print('✅ WAL mode habilitado');

            // Ajustes para bajo uso de memoria RAM
            await db.rawQuery('PRAGMA cache_size = 1000'); // Reducido de default 2000
            await db.rawQuery('PRAGMA temp_store = MEMORY'); // Almacenamiento temporal en RAM
            await db.rawQuery('PRAGMA mmap_size = 268435456'); // 256MB, adecuado para bajo recurso
            print('⚙️ Configuraciones de bajo consumo aplicadas');
          } catch (e) {
            print('⚠️ No se pudieron configurar optimizaciones: $e');
            // Continuar con valores por defecto
          }
        },
      );
    } catch (e, stackTrace) {
      print('💥 Error crítico al inicializar base de datos: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Recrear la tabla de ubicaciones con el nuevo esquema
      await db.execute('DROP TABLE IF EXISTS transfers');
      await db.execute('DROP TABLE IF EXISTS packages');
      await db.execute('DROP TABLE IF EXISTS locations');

      await db.execute('''
        CREATE TABLE locations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          warehouseId INTEGER NOT NULL,
          section TEXT,
          shelf TEXT,
          level TEXT,
          description TEXT,
          isAvailable INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (warehouseId) REFERENCES warehouses (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE packages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          trackingNumber TEXT NOT NULL UNIQUE,
          customerName TEXT NOT NULL,
          customerPhone TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'En almacén',
          locationId INTEGER,
          warehouseId INTEGER,
          registeredDate TEXT NOT NULL,
          deliveredDate TEXT,
          notified INTEGER NOT NULL DEFAULT 0,
          notes TEXT,
          FOREIGN KEY (locationId) REFERENCES locations (id),
          FOREIGN KEY (warehouseId) REFERENCES warehouses (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE transfers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          packageId INTEGER NOT NULL,
          fromLocationId INTEGER NOT NULL,
          toLocationId INTEGER NOT NULL,
          transferDate TEXT NOT NULL,
          performedBy TEXT,
          reason TEXT,
          FOREIGN KEY (packageId) REFERENCES packages (id),
          FOREIGN KEY (fromLocationId) REFERENCES locations (id),
          FOREIGN KEY (toLocationId) REFERENCES locations (id)
        )
      ''');
    }

    if (oldVersion < 3) {
      // Actualizar tabla de paquetes con nuevos campos
      await db.execute('DROP TABLE IF EXISTS transfers');
      await db.execute('DROP TABLE IF EXISTS packages');

      await db.execute('''
        CREATE TABLE packages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          trackingNumber TEXT NOT NULL UNIQUE,
          senderName TEXT NOT NULL,
          senderPhone TEXT NOT NULL,
          senderEmail TEXT,
          senderIdType TEXT,
          senderIdNumber TEXT,
          recipientName TEXT NOT NULL,
          recipientPhone TEXT NOT NULL,
          recipientIdType TEXT,
          recipientIdNumber TEXT,
          weight REAL,
          status TEXT NOT NULL DEFAULT 'Pendiente',
          locationId INTEGER,
          warehouseId INTEGER,
          registeredDate TEXT NOT NULL,
          deliveredDate TEXT,
          notified INTEGER NOT NULL DEFAULT 0,
          notes TEXT,
          FOREIGN KEY (locationId) REFERENCES locations (id),
          FOREIGN KEY (warehouseId) REFERENCES warehouses (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE transfers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          packageId INTEGER NOT NULL,
          fromLocationId INTEGER NOT NULL,
          toLocationId INTEGER NOT NULL,
          transferDate TEXT NOT NULL,
          performedBy TEXT,
          reason TEXT,
          FOREIGN KEY (packageId) REFERENCES packages (id),
          FOREIGN KEY (fromLocationId) REFERENCES locations (id),
          FOREIGN KEY (toLocationId) REFERENCES locations (id)
        )
      ''');
    }

    if (oldVersion < 4) {
      // Insertar registro de ejemplo
      await db.insert('packages', {
        'trackingNumber': 'PKG-2025-001234',
        'senderName': 'Juan Pérez García',
        'senderPhone': '987654321',
        'senderEmail': 'juan.perez@email.com',
        'senderIdType': 'DNI',
        'senderIdNumber': '12345678',
        'recipientName': 'María López Sánchez',
        'recipientPhone': '912345678',
        'recipientIdType': 'DNI',
        'recipientIdNumber': '87654321',
        'weight': 2.5,
        'status': 'Pendiente',
        'locationId': null,
        'warehouseId': null,
        'registeredDate': DateTime.now().toIso8601String(),
        'deliveredDate': null,
        'notified': 0,
        'notes': 'Paquete de ejemplo - Contiene documentos importantes',
      });
    }

    if (oldVersion < 5) {
      // Crear tabla de usuarios
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          fullName TEXT NOT NULL,
          email TEXT,
          role TEXT NOT NULL DEFAULT 'operator',
          isActive INTEGER NOT NULL DEFAULT 1,
          createdDate TEXT NOT NULL,
          lastLogin TEXT
        )
      ''');

      // Usuario administrador debe ser creado manualmente durante setup
      // No insertar credenciales hardcodeadas por seguridad
    }

    if (oldVersion < 6) {
      // Migrar de roles a sistema de permisos

      // Crear tabla temporal con el nuevo esquema
      await db.execute('''
        CREATE TABLE users_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          fullName TEXT NOT NULL,
          email TEXT,
          isActive INTEGER NOT NULL DEFAULT 1,
          createdDate TEXT NOT NULL,
          lastLogin TEXT,
          canManageUsers INTEGER NOT NULL DEFAULT 0,
          canManageWarehouses INTEGER NOT NULL DEFAULT 0,
          canManageLocations INTEGER NOT NULL DEFAULT 0,
          canManagePackages INTEGER NOT NULL DEFAULT 0,
          canDeletePackages INTEGER NOT NULL DEFAULT 0,
          canScanQR INTEGER NOT NULL DEFAULT 1,
          canSendMessages INTEGER NOT NULL DEFAULT 0,
          canConfigureSystem INTEGER NOT NULL DEFAULT 0,
          canBackupRestore INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Migrar datos existentes convirtiendo roles a permisos
      final List<Map<String, dynamic>> existingUsers = await db.query('users');

      for (var user in existingUsers) {
        final role = user['role'] as String;

        // Convertir rol a permisos
        int allPermissions = role == 'admin' ? 1 : 0;
        int operatorPermissions = (role == 'admin' || role == 'operator') ? 1 : 0;

        await db.insert('users_new', {
          'id': user['id'],
          'username': user['username'],
          'password': user['password'],
          'fullName': user['fullName'],
          'email': user['email'],
          'isActive': user['isActive'],
          'createdDate': user['createdDate'],
          'lastLogin': user['lastLogin'],
          'canManageUsers': allPermissions,
          'canManageWarehouses': operatorPermissions,
          'canManageLocations': operatorPermissions,
          'canManagePackages': operatorPermissions,
          'canDeletePackages': allPermissions,
          'canScanQR': 1, // Todos pueden escanear por defecto
          'canSendMessages': operatorPermissions,
          'canConfigureSystem': allPermissions,
          'canBackupRestore': allPermissions,
        });
      }

      // Reemplazar tabla antigua con la nueva
      await db.execute('DROP TABLE users');
      await db.execute('ALTER TABLE users_new RENAME TO users');
    }

    if (oldVersion < 7) {
      // Agregar campo originalQRData a la tabla packages
      await db.execute('''
        ALTER TABLE packages ADD COLUMN originalQRData TEXT
      ''');
    }

    if (oldVersion < 8) {
      // Agregar campo originalQRData si no existe (ya se hizo en v7)
      try {
        await db.execute('ALTER TABLE packages ADD COLUMN originalQRData TEXT');
      } catch (e) {
        // La columna ya existe, ignorar
      }
    }

    if (oldVersion < 9) {
      // NO crear índices aquí para evitar bloqueo
      // Los índices se crean en background después del inicio
    }

    if (oldVersion < 10) {
      // Vacío: Las migraciones se hacen en el método anterior
      // No crear usuario admin aquí por seguridad
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de almacenes
    await db.execute('''
      CREATE TABLE warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        description TEXT,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Tabla de ubicaciones
    await db.execute('''
      CREATE TABLE locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        warehouseId INTEGER NOT NULL,
        section TEXT,
        shelf TEXT,
        level TEXT,
        description TEXT,
        isAvailable INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (warehouseId) REFERENCES warehouses (id)
      )
    ''');

    // Tabla de paquetes
    await db.execute('''
      CREATE TABLE packages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trackingNumber TEXT NOT NULL UNIQUE,
        senderName TEXT NOT NULL,
        senderPhone TEXT NOT NULL,
        senderEmail TEXT,
        senderIdType TEXT,
        senderIdNumber TEXT,
        recipientName TEXT NOT NULL,
        recipientPhone TEXT NOT NULL,
        recipientIdType TEXT,
        recipientIdNumber TEXT,
        weight REAL,
        status TEXT NOT NULL DEFAULT 'Pendiente',
        locationId INTEGER,
        warehouseId INTEGER,
        registeredDate TEXT NOT NULL,
        deliveredDate TEXT,
        notified INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        originalQRData TEXT,
        FOREIGN KEY (locationId) REFERENCES locations (id),
        FOREIGN KEY (warehouseId) REFERENCES warehouses (id)
      )
    ''');

    // Tabla de traslados
    await db.execute('''
      CREATE TABLE transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        packageId INTEGER NOT NULL,
        fromLocationId INTEGER NOT NULL,
        toLocationId INTEGER NOT NULL,
        transferDate TEXT NOT NULL,
        performedBy TEXT,
        reason TEXT,
        FOREIGN KEY (packageId) REFERENCES packages (id),
        FOREIGN KEY (fromLocationId) REFERENCES locations (id),
        FOREIGN KEY (toLocationId) REFERENCES locations (id)
      )
    ''');

    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        fullName TEXT NOT NULL,
        email TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdDate TEXT NOT NULL,
        lastLogin TEXT,
        canManageUsers INTEGER NOT NULL DEFAULT 0,
        canManageWarehouses INTEGER NOT NULL DEFAULT 0,
        canManageLocations INTEGER NOT NULL DEFAULT 0,
        canManagePackages INTEGER NOT NULL DEFAULT 0,
        canDeletePackages INTEGER NOT NULL DEFAULT 0,
        canScanQR INTEGER NOT NULL DEFAULT 1,
        canSendMessages INTEGER NOT NULL DEFAULT 0,
        canConfigureSystem INTEGER NOT NULL DEFAULT 0,
        canBackupRestore INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insertar datos de ejemplo
    await _insertInitialData(db);

    // NO crear índices en onCreate para inicio instantáneo
    // Los índices se crean en background
  }

  // Crear solo índices críticos (más importantes)
  Future<void> _createCriticalIndexes(Database db) async {
    // Solo los índices más críticos para evitar delay en startup
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_trackingNumber ON packages(trackingNumber)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_status ON packages(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_registeredDate ON packages(registeredDate DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_locations_warehouseId ON locations(warehouseId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)');
  }

  // Crear todos los índices (llamar en background después del inicio)
  Future<void> _createIndexes(Database db) async {
    // Índices para la tabla packages (más consultada)
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_trackingNumber ON packages(trackingNumber)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_status ON packages(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_locationId ON packages(locationId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_warehouseId ON packages(warehouseId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_registeredDate ON packages(registeredDate DESC)');

    // Índices compuestos para búsquedas comunes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_status_date ON packages(status, registeredDate DESC)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_location_status ON packages(locationId, status)');

    // Índices para búsquedas de texto (LIKE queries)
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_recipientName ON packages(recipientName)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_packages_senderName ON packages(senderName)');

    // Índices para la tabla locations
    await db.execute('CREATE INDEX IF NOT EXISTS idx_locations_warehouseId ON locations(warehouseId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_locations_isAvailable ON locations(isAvailable)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_locations_warehouse_available ON locations(warehouseId, isAvailable)');

    // Índices para la tabla warehouses
    await db.execute('CREATE INDEX IF NOT EXISTS idx_warehouses_isActive ON warehouses(isActive)');

    // Índices para la tabla users
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_isActive ON users(isActive)');

    // Índices para la tabla transfers
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transfers_packageId ON transfers(packageId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transfers_transferDate ON transfers(transferDate DESC)');

    // Analizar tablas para actualizar estadísticas del query optimizer
    await db.execute('ANALYZE');
  }

  Future<void> _insertInitialData(Database db) async {
    // NO insertar usuario administrador con credenciales hardcodeadas por seguridad
    // El primer usuario admin debe ser creado manualmente durante la configuración inicial

    // Insertar un registro de ejemplo para demostración
    await db.insert('packages', {
      'trackingNumber': 'PKG-2025-001234',
      'senderName': 'Juan Pérez García',
      'senderPhone': '987654321',
      'senderEmail': 'juan.perez@email.com',
      'senderIdType': 'DNI',
      'senderIdNumber': '12345678',
      'recipientName': 'María López Sánchez',
      'recipientPhone': '912345678',
      'recipientIdType': 'DNI',
      'recipientIdNumber': '87654321',
      'weight': 2.5,
      'status': 'Pendiente',
      'locationId': null,
      'warehouseId': null,
      'registeredDate': DateTime.now().toIso8601String(),
      'deliveredDate': null,
      'notified': 0,
      'notes': 'Paquete de ejemplo - Contiene documentos importantes',
    });
  }

  // Crear índices restantes en background (no bloquea el inicio)
  Future<void> createRemainingIndexes() async {
    final db = await database;
    await _createIndexes(db);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    try {
      // Cerrar la base de datos si está abierta
      if (_database != null) {
        print('🔒 Cerrando base de datos...');
        await _database!.close();
        _database = null;
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'paqueteria.db');

      print('📂 Ruta de BD: $path');

      // Verificar si el archivo existe antes de intentar eliminarlo
      final file = File(path);
      if (await file.exists()) {
        print('🗑️  Eliminando archivo de base de datos...');
        await file.delete();
        print('✅ Archivo eliminado');

        // También eliminar archivos relacionados (WAL, SHM)
        final walFile = File('$path-wal');
        if (await walFile.exists()) {
          await walFile.delete();
          print('✅ Archivo WAL eliminado');
        }

        final shmFile = File('$path-shm');
        if (await shmFile.exists()) {
          await shmFile.delete();
          print('✅ Archivo SHM eliminado');
        }
      } else {
        print('⚠️ El archivo de base de datos no existe');
      }

      // Asegurar que _database está null para forzar recreación
      _database = null;
      print('✅ Base de datos marcada para recreación');
    } catch (e, stackTrace) {
      print('💥 Error al eliminar base de datos: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
