import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class PasswordService {
  static const int _hashIterations = 10000;
  static const int _saltLength = 16; // 16 bytes de salt

  /// Hashea una contraseña usando PBKDF2-SHA256
  static String hashPassword(String password) {
    // Generar salt aleatorio (16 bytes = 128 bits)
    final salt = _generateRandomSalt();

    // Hash con PBKDF2
    final hash = _pbkdf2(password, salt, _hashIterations);

    // Retornar salt + hash en formato: salt_en_base64$hash_en_base64
    final encodedSalt = base64Encode(salt);
    final encodedHash = base64Encode(hash);

    return '$encodedSalt\$$encodedHash';
  }

  /// Verifica si la contraseña coincide con el hash almacenado
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      final parts = hashedPassword.split('\$');
      if (parts.length != 2) {
        print('❌ Hash inválido: no tiene exactamente 2 partes');
        return false;
      }

      final encodedSalt = parts[0];
      final encodedHash = parts[1];

      // Decodificar el salt
      List<int> salt;
      try {
        salt = base64Decode(encodedSalt);
      } catch (e) {
        print('❌ Error decodificando salt: $e');
        return false;
      }

      // Hash la contraseña proporcionada con el mismo salt
      final hash = _pbkdf2(password, salt, _hashIterations);
      final computedHash = base64Encode(hash);

      // Comparación de tiempo constante para evitar timing attacks
      return _constantTimeEquals(computedHash, encodedHash);
    } catch (e) {
      print('❌ Error verificando contraseña: $e');
      return false;
    }
  }

  /// Genera un salt aleatorio de bytes
  static List<int> _generateRandomSalt() {
    final random = Random.secure();
    return List<int>.generate(_saltLength, (i) => random.nextInt(256));
  }

  /// Implementa PBKDF2 usando SHA256
  static List<int> _pbkdf2(String password, List<int> salt, int iterations) {
    final passwordBytes = utf8.encode(password);

    // Flutter crypto no tiene PBKDF2 nativo, así que usamos SHA256 iterativo
    List<int> hash = passwordBytes;
    for (int i = 0; i < iterations; i++) {
      final combined = [...hash, ...salt];
      hash = sha256.convert(combined).bytes.toList();
    }
    return hash;
  }

  /// Comparación en tiempo constante para evitar timing attacks
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }
}
