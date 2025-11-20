import 'dart:async';

/// Debouncer para prevenir múltiples taps rápidos en botones
/// Reduce delay percibido al evitar ejecuciones duplicadas
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler para limitar frecuencia de ejecución
/// Útil para scroll events y búsquedas
class Throttler {
  final Duration duration;
  Timer? _timer;
  bool _isReady = true;

  Throttler({this.duration = const Duration(milliseconds: 300)});

  void run(void Function() action) {
    if (_isReady) {
      _isReady = false;
      action();
      _timer = Timer(duration, () {
        _isReady = true;
      });
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
