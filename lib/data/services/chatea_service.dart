import 'dart:convert';
import 'package:http/http.dart' as http;

class ChateaService {
  static const String baseUrl = 'https://chatea.tecnosoft.dev/api/qr/rest';

  /// Limpia un número de teléfono removiendo caracteres no numéricos y normalizando formato venezolano
  static String _cleanPhoneNumber(String phone) {
    // Remover espacios, guiones, paréntesis, signos +, etc.
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Si empieza con 0 (formato local venezolano), reemplazar por 58
    if (cleaned.startsWith('0')) {
      cleaned = '58${cleaned.substring(1)}';
      print('🔧 Número convertido de formato local a internacional: "$phone" -> "$cleaned"');
    } else {
      print('🔧 Número limpiado: "$phone" -> "$cleaned"');
    }

    return cleaned;
  }

  /// Envía un mensaje de prueba para verificar las credenciales
  static Future<ChateaTestResult> testCredentials({
    required String apiKey,
    required String senderPhone,
    required String testRecipient,
  }) async {
    try {
      final url = '$baseUrl/send_message';

      final cleanSenderPhone = _cleanPhoneNumber(senderPhone);
      final cleanRecipientPhone = _cleanPhoneNumber(testRecipient);

      final requestBody = {
        'messageType': 'text',
        'requestType': 'POST',
        'token': apiKey,
        'from': cleanSenderPhone,
        'to': cleanRecipientPhone,
        'text': '🧪 Mensaje de prueba desde Sistema de Paquetería\n\n'
            'Este es un test de verificación de credenciales.\n\n'
            'Fecha: ${DateTime.now().toString()}',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('La solicitud tardó demasiado. Por favor verifica tu conexión a internet.');
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          return ChateaTestResult(
            success: true,
            message: responseData['message'] ?? 'Credenciales verificadas correctamente',
          );
        } else {
          return ChateaTestResult(
            success: false,
            message: _translateErrorMessage(responseData['message'] ?? 'Error desconocido'),
          );
        }
      } else {
        return ChateaTestResult(
          success: false,
          message: 'Error HTTP ${response.statusCode}: ${_translateErrorMessage(responseData['message'] ?? response.body)}',
        );
      }
    } catch (e) {
      return ChateaTestResult(
        success: false,
        message: 'Error de conexión: ${_translateErrorMessage(e.toString())}',
      );
    }
  }

  /// Envía un mensaje a través de Chatea
  static Future<ChateaSendResult> sendMessage({
    required String apiKey,
    required String senderPhone,
    required String recipientPhone,
    required String message,
  }) async {
    try {
      final url = '$baseUrl/send_message';

      final cleanSenderPhone = _cleanPhoneNumber(senderPhone);
      final cleanRecipientPhone = _cleanPhoneNumber(recipientPhone);

      final requestBody = {
        'messageType': 'text',
        'requestType': 'POST',
        'token': apiKey,
        'from': cleanSenderPhone,
        'to': cleanRecipientPhone,
        'text': message,
      };

      print('📤 Enviando mensaje a Chatea...');
      print('URL: $url');
      print('From: $cleanSenderPhone (original: $senderPhone)');
      print('To: $cleanRecipientPhone (original: $recipientPhone)');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('La solicitud tardó demasiado. Por favor verifica tu conexión a internet.');
        },
      );

      print('📥 Respuesta recibida: ${response.statusCode}');
      print('Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          print('✅ Mensaje enviado exitosamente');
          return ChateaSendResult(
            success: true,
            message: responseData['message'] ?? 'Mensaje enviado correctamente',
            messageId: responseData['data']?['messageId'] ?? responseData['messageId'],
          );
        } else {
          print('❌ Error en respuesta: ${responseData['message']}');
          return ChateaSendResult(
            success: false,
            message: _translateErrorMessage(responseData['message'] ?? 'Error desconocido'),
          );
        }
      } else {
        print('❌ Error HTTP ${response.statusCode}');
        return ChateaSendResult(
          success: false,
          message: 'Error HTTP ${response.statusCode}: ${_translateErrorMessage(responseData['message'] ?? response.body)}',
        );
      }
    } catch (e) {
      print('❌ Excepción capturada: $e');
      return ChateaSendResult(
        success: false,
        message: 'Error de conexión: ${_translateErrorMessage(e.toString())}',
      );
    }
  }

  /// Traduce mensajes de error comunes del inglés al español
  static String _translateErrorMessage(String message) {
    // Diccionario de traducciones
    final translations = {
      'Your plan does not allow you to use API feature': 'Tu plan no permite usar la función de API',
      'Please provide your META API keys in the profile section': 'Por favor configura tus claves API de META en la sección de perfil',
      'Invalid phone number format': 'Formato de número de teléfono inválido',
      'Phone number not registered': 'Número de teléfono no registrado',
      'Unauthorized': 'No autorizado - verifica tu API Key',
      'Forbidden': 'Acceso prohibido',
      'Not Found': 'No encontrado',
      'Internal Server Error': 'Error interno del servidor',
      'Bad Request': 'Solicitud incorrecta',
      'Timeout': 'Tiempo de espera agotado',
      'Connection refused': 'Conexión rechazada',
      'No internet connection': 'Sin conexión a internet',
      'Network error': 'Error de red',
      'Failed to connect': 'Error al conectar',
      'SocketException': 'Error de conexión. Verifica tu internet.',
      'HandshakeException': 'Error de seguridad en la conexión',
      'Connection timed out': 'Tiempo de conexión agotado',
      'Connection closed': 'Conexión cerrada inesperadamente',
    };

    // Buscar traducción exacta
    if (translations.containsKey(message)) {
      return translations[message]!;
    }

    // Buscar traducciones parciales
    for (var entry in translations.entries) {
      if (message.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Si no hay traducción, devolver el mensaje original
    return message;
  }
}

class ChateaTestResult {
  final bool success;
  final String message;

  ChateaTestResult({
    required this.success,
    required this.message,
  });
}

class ChateaSendResult {
  final bool success;
  final String message;
  final String? messageId;

  ChateaSendResult({
    required this.success,
    required this.message,
    this.messageId,
  });
}
