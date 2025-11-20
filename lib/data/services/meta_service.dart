import 'dart:convert';
import 'package:http/http.dart' as http;

class MetaService {
  static const String baseUrl = 'https://graph.facebook.com/v18.0';

  /// Envía un mensaje de prueba para verificar las credenciales
  static Future<MetaTestResult> testCredentials({
    required String phoneId,
    required String accessToken,
  }) async {
    try {
      // URL para verificar el número de teléfono
      final url = '$baseUrl/$phoneId?access_token=$accessToken';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('La solicitud tardó demasiado. Por favor verifica tu conexión a internet.');
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return MetaTestResult(
          success: true,
          message: 'Credenciales verificadas correctamente. Número de teléfono: ${responseData['id']}',
        );
      } else {
        return MetaTestResult(
          success: false,
          message: 'Error: ${_translateErrorMessage(responseData['error']['message'] ?? 'Error desconocido')}',
        );
      }
    } catch (e) {
      return MetaTestResult(
        success: false,
        message: 'Error de conexión: ${_translateErrorMessage(e.toString())}',
      );
    }
  }

  /// Obtiene las plantillas de mensajes disponibles
  static Future<MetaTemplatesResult> getTemplates({
    required String phoneId,
    required String accessToken,
  }) async {
    try {
      // Para esta implementación, usamos exclusivamente la plantilla hello_world
      return MetaTemplatesResult(
        success: true,
        templates: ['Hello {{1}}'], // Plantilla hello_world con parámetro posicional
        message: 'Plantilla hello_world cargada',
      );
    } catch (e) {
      return MetaTemplatesResult(
        success: false,
        templates: ['Hello {{1}}'], // Plantilla por defecto
        message: 'Error al cargar plantillas: ${_translateErrorMessage(e.toString())}',
      );
    }
  }

  /// Envía un mensaje a través del API de META usando la plantilla hello_world
  static Future<MetaSendResult> sendMessage({
    required String phoneId,
    required String accessToken,
    required String recipientPhone,
    required String message,
  }) async {
    try {
      final url = '$baseUrl/$phoneId/messages';

      // Limpiar el número de teléfono removiendo caracteres no numéricos
      String cleanRecipientPhone = recipientPhone.replaceAll(RegExp(r'[^\d]'), '');

      // Si empieza con 0 (formato local), reemplazar por el código de país adecuado
      if (cleanRecipientPhone.startsWith('0')) {
        cleanRecipientPhone = '58${cleanRecipientPhone.substring(1)}';
      }

      // Asegurarse de que el número tenga el código de país
      if (!cleanRecipientPhone.startsWith('+') && cleanRecipientPhone.length > 10) {
        if (cleanRecipientPhone.length < 10) {
          cleanRecipientPhone = '58$cleanRecipientPhone';
        }
      }

      // Enviar usando el formato de plantilla como especificaste
      final requestBody = {
        'messaging_product': 'whatsapp',
        'to': cleanRecipientPhone,
        'type': 'template',
        'template': {
          'name': 'hello_world',
          'language': {'code': 'en_US'}
        }
      };

      print('📤 Enviando mensaje a META usando plantilla hello_world...');
      print('URL: $url');
      print('To: $cleanRecipientPhone (original: $recipientPhone)');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
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
        if (responseData['messages'] != null && responseData['messages'].length > 0) {
          print('✅ Mensaje enviado exitosamente');
          return MetaSendResult(
            success: true,
            message: responseData['messages'][0]['message_status'] ?? 'Mensaje enviado correctamente',
            messageId: responseData['messages'][0]['id'],
          );
        } else if (responseData['message_id'] != null) {
          print('✅ Mensaje enviado exitosamente');
          return MetaSendResult(
            success: true,
            message: 'Mensaje enviado correctamente',
            messageId: responseData['message_id'],
          );
        } else {
          print('❌ Error en respuesta: Mensaje no enviado');
          return MetaSendResult(
            success: false,
            message: 'Mensaje no enviado - respuesta inesperada',
          );
        }
      } else {
        print('❌ Error HTTP ${response.statusCode}');
        String errorMessage = 'Error desconocido';
        if (responseData['error'] != null) {
          errorMessage = responseData['error']['message'] ?? errorMessage;
        } else if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        }

        return MetaSendResult(
          success: false,
          message: 'Error HTTP ${response.statusCode}: ${_translateErrorMessage(errorMessage)}',
        );
      }
    } catch (e) {
      print('❌ Excepción capturada: $e');
      return MetaSendResult(
        success: false,
        message: 'Error de conexión: ${_translateErrorMessage(e.toString())}',
      );
    }
  }

  /// Traduce mensajes de error comunes del inglés al español
  static String _translateErrorMessage(String message) {
    // Diccionario de traducciones
    final translations = {
      'Your account is not verified': 'Tu cuenta no está verificada',
      'Recipient is not a valid phone number': 'El destinatario no es un número de teléfono válido',
      'Recipient is not a WhatsApp user': 'El destinatario no es usuario de WhatsApp',
      'Message failed to send': 'El mensaje falló al enviar',
      'Invalid access token': 'Token de acceso inválido',
      'Account not found': 'Cuenta no encontrada',
      'Insufficient permissions': 'Permisos insuficientes',
      'Rate limit exceeded': 'Límite de velocidad excedido',
      'Message type not enabled': 'Tipo de mensaje no habilitado',
      'Profile not verified': 'Perfil no verificado',
      'Please provide your META API keys in the profile section': 'Por favor configura tus claves API de META en la sección de perfil',
      'Invalid phone number format': 'Formato de número de teléfono inválido',
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

class MetaTestResult {
  final bool success;
  final String message;

  MetaTestResult({
    required this.success,
    required this.message,
  });
}

class MetaTemplatesResult {
  final bool success;
  final List<String> templates;
  final String message;

  MetaTemplatesResult({
    required this.success,
    required this.templates,
    required this.message,
  });
}

class MetaSendResult {
  final bool success;
  final String message;
  final String? messageId;

  MetaSendResult({
    required this.success,
    required this.message,
    this.messageId,
  });
}