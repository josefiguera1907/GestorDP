class RateLimiterService {
  static final RateLimiterService _instance = RateLimiterService._internal();

  factory RateLimiterService() => _instance;

  RateLimiterService._internal();

  // Mapeo de usuario -> lista de intentos (timestamps)
  final Map<String, List<int>> _loginAttempts = {};

  // Configuración
  static const int maxAttempts = 5; // Máximo de intentos permitidos
  static const int timeWindowMs = 15 * 60 * 1000; // Ventana de tiempo: 15 minutos

  /// Verifica si un usuario está siendo rate limitado
  bool isRateLimited(String username) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final attempts = _loginAttempts[username] ?? [];

    // Limpiar intentos antiguos fuera de la ventana de tiempo
    final recentAttempts = attempts
        .where((timestamp) => (now - timestamp) < timeWindowMs)
        .toList();

    _loginAttempts[username] = recentAttempts;

    return recentAttempts.length >= maxAttempts;
  }

  /// Registra un intento de login fallido
  void recordFailedAttempt(String username) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final attempts = _loginAttempts[username] ?? [];

    // Limpiar intentos antiguos
    final recentAttempts = attempts
        .where((timestamp) => (now - timestamp) < timeWindowMs)
        .toList();

    recentAttempts.add(now);
    _loginAttempts[username] = recentAttempts;

    if (recentAttempts.length >= maxAttempts) {
      print('⚠️ Rate limit: Usuario $username ha excedido intentos de login');
    }
  }

  /// Limpia los intentos cuando el login es exitoso
  void recordSuccessfulAttempt(String username) {
    _loginAttempts.remove(username);
    print('✅ Rate limit: Intentos de $username limpiados');
  }

  /// Retorna el tiempo (en segundos) hasta que el usuario pueda volver a intentar
  int getSecondsUntilRetry(String username) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final attempts = _loginAttempts[username] ?? [];

    if (attempts.isEmpty) return 0;

    // Encontrar el timestamp más antiguo dentro de la ventana
    final oldestAttempt = attempts.first;
    final timeUntilExpiry = oldestAttempt + timeWindowMs - now;

    return (timeUntilExpiry / 1000).ceil();
  }

  /// Limpia todos los intentos registrados (útil para testing)
  void reset() {
    _loginAttempts.clear();
  }

  /// Obtiene el número de intentos recientes
  int getRecentAttempts(String username) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final attempts = _loginAttempts[username] ?? [];

    final recentAttempts = attempts
        .where((timestamp) => (now - timestamp) < timeWindowMs)
        .toList();

    _loginAttempts[username] = recentAttempts;
    return recentAttempts.length;
  }
}
