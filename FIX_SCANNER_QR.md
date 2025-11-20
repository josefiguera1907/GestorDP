# Fix: Cámara no reconoce códigos QR

## Problema Reportado

La cámara en la pantalla de escaneo no está reaccionando/reconociendo ningún código QR.

## Causas Posibles Identificadas

### 1. Configuración del MobileScannerController
- **DetectionSpeed** estaba configurado como `normal`, lo cual puede ser lento
- **No tenía formatos específicos** habilitados explícitamente
- **Faltaba inicialización explícita** de la cámara

### 2. Falta de feedback visual
- No había indicador de cuándo la cámara estaba lista
- No había logs detallados de lo que el scanner detectaba
- El usuario no sabía si el problema era la cámara o el código QR

### 3. Sincronización del ciclo de vida
- La cámara se iniciaba directamente en `initState()`
- No esperaba a que el widget estuviera completamente montado

## Solución Implementada

### 1. Mejorada configuración del MobileScannerController (scan_screen.dart:19-35)

**ANTES:**
```dart
final MobileScannerController cameraController = MobileScannerController(
  detectionSpeed: DetectionSpeed.normal,
  facing: CameraFacing.back,
  torchEnabled: false,
  returnImage: false,
);
```

**DESPUÉS:**
```dart
final MobileScannerController cameraController = MobileScannerController(
  detectionSpeed: DetectionSpeed.noDuplicates, // Más rápido, evita duplicados
  facing: CameraFacing.back,
  torchEnabled: false,
  returnImage: false,
  // Habilitar todos los formatos de códigos explícitamente
  formats: [
    BarcodeFormat.qrCode,        // QR Codes
    BarcodeFormat.code128,       // Códigos de barras estándar
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.ean13,         // Códigos de productos
    BarcodeFormat.ean8,
    BarcodeFormat.upca,
    BarcodeFormat.upce,
  ],
);
```

**Beneficios:**
- ✅ Detección más rápida y sin duplicados
- ✅ Soporta múltiples formatos de códigos
- ✅ Específica QR Code explícitamente

### 2. Inicialización asíncrona de cámara (scan_screen.dart:58-80)

**AGREGADO:**
```dart
Future<void> _initializeCamera() async {
  try {
    print('📷 Iniciando cámara...');
    await cameraController.start();
    if (mounted) {
      setState(() {
        _cameraInitialized = true;
      });
      print('✅ Cámara iniciada correctamente');
    }
  } catch (e) {
    print('❌ Error al iniciar cámara: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al iniciar cámara: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
```

**Y en initState:**
```dart
@override
void initState() {
  super.initState();
  print('🚀 ScanScreen iniciando...');
  _initializeDataWedge();
  // Esperar a que el widget esté montado completamente
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeCamera();
  });
}
```

**Beneficios:**
- ✅ Espera a que el widget esté completamente montado
- ✅ Manejo de errores con mensajes al usuario
- ✅ Estado `_cameraInitialized` para mostrar UI condicional

### 3. Logging detallado en onDetect (scan_screen.dart:176-217)

**AGREGADO:**
```dart
onDetect: (capture) {
  print('🔍 onDetect llamado - barcodes detectados: ${capture.barcodes.length}');

  // Debug: imprimir información de cada barcode detectado
  for (var i = 0; i < capture.barcodes.length; i++) {
    final barcode = capture.barcodes[i];
    print('   Barcode[$i]: format=${barcode.format}, type=${barcode.type}, rawValue="${barcode.rawValue}"');
  }

  // ... validaciones ...

  for (final barcode in barcodes) {
    final rawValue = barcode.rawValue;
    print('📱 Procesando barcode: type=${barcode.type}, format=${barcode.format}, value="$rawValue"');

    if (rawValue != null && rawValue.isNotEmpty) {
      print('✅ Código válido encontrado, procesando...');
      setState(() {
        _isProcessing = true;
      });
      _processScannedCode(rawValue);
      break;
    } else {
      print('⚠️ Barcode sin valor (rawValue es null o vacío)');
    }
  }
},
```

**Y agregados callbacks adicionales:**
```dart
onScannerStarted: (arguments) {
  print('✅ Scanner iniciado: $arguments');
},
onDetectorError: (error, stackTrace) {
  print('❌ Error del detector: $error');
  print('   Stack trace: $stackTrace');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error del escáner: ${error.errorCode}'),
        backgroundColor: Colors.red,
      ),
    );
  }
},
```

**Beneficios:**
- ✅ Logs detallados para debugging
- ✅ Muestra formato y tipo de cada código detectado
- ✅ Notifica errores al usuario inmediatamente
- ✅ Permite diagnosticar si el problema es detección vs procesamiento

### 4. Indicadores visuales de estado (scan_screen.dart:244-303)

**AGREGADO:**
```dart
// Indicador mientras la cámara se inicializa
if (!_cameraInitialized && !_dataWedgeAvailable)
  Positioned.fill(
    child: Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Iniciando cámara...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    ),
  ),

// Mensaje con estado en tiempo real
child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      _dataWedgeAvailable
          ? 'Use el botón lateral para escanear'
          : 'Coloque el código QR dentro del marco',
      // ...
    ),
    if (_cameraInitialized && !_dataWedgeAvailable) ...[
      const SizedBox(height: 4),
      Text(
        _isProcessing ? '🔄 Procesando...' : '📷 Cámara lista',
        style: TextStyle(
          color: _isProcessing ? Colors.orange : Colors.green,
          fontSize: 12,
        ),
      ),
    ],
  ],
),
```

**Beneficios:**
- ✅ Usuario sabe cuándo la cámara está lista
- ✅ Feedback visual durante inicialización
- ✅ Indica si está procesando un código
- ✅ Diferentes mensajes para DataWedge vs cámara

## Cómo Probar el Fix

### 1. Compilar y desplegar
```bash
cd /home/xeonix/Documentos/gdp/paqueteria_app
flutter clean
flutter pub get
flutter build apk --release
```

### 2. Instalar en dispositivo
```bash
flutter install
# O manualmente transferir el APK y instalarlo
```

### 3. Testing con logs
Conectar dispositivo y ver logs en tiempo real:
```bash
adb logcat | grep -E "(Scanner|Camera|QR|onDetect|Barcode)"
```

### 4. Checklist de pruebas

**Prueba 1: Inicialización**
- [ ] Abrir pantalla de escaneo
- [ ] Debería aparecer "Iniciando cámara..." por 1-2 segundos
- [ ] Luego debe cambiar a "📷 Cámara lista"
- [ ] Vista previa de cámara debe ser visible

**Prueba 2: Detección de QR**
- [ ] Colocar un código QR frente a la cámara
- [ ] En los logs debería aparecer: `🔍 onDetect llamado - barcodes detectados: 1`
- [ ] Seguido de: `Barcode[0]: format=qrCode, type=..., rawValue="..."`
- [ ] El texto debería cambiar a "🔄 Procesando..."
- [ ] Debe aparecer el diálogo de carga

**Prueba 3: Códigos de barras**
- [ ] Probar con código de barras EAN-13 (productos)
- [ ] Debe detectar y procesar igualmente
- [ ] Verificar en logs el formato detectado

**Prueba 4: Errores**
- [ ] Si hay error de cámara, debe mostrar SnackBar rojo
- [ ] Si hay error de detector, debe mostrar mensaje específico
- [ ] Los logs deben mostrar el error completo

## Diagnóstico si el Problema Persiste

### Caso 1: "Iniciando cámara..." nunca desaparece

**Posible causa:** Error al obtener acceso a la cámara

**Diagnóstico:**
```bash
# Ver logs específicos
adb logcat | grep "Error al iniciar cámara"

# Verificar permisos
adb shell pm list permissions -d -g | grep CAMERA
adb shell dumpsys package com.paqueteria.paqueteria_app | grep "CAMERA"
```

**Solución:**
1. Ir a Ajustes > Aplicaciones > Paquetería App > Permisos
2. Asegurar que "Cámara" está permitido
3. Si persiste, reinstalar la app

### Caso 2: Cámara funciona pero nunca dice "onDetect llamado"

**Posible causa:** Problema con la librería mobile_scanner o API nativa

**Diagnóstico:**
```bash
# Ver si el scanner se inició
adb logcat | grep "Scanner iniciado"

# Ver si hay errores del detector
adb logcat | grep "Error del detector"
```

**Solución:**
1. Verificar que el dispositivo tiene cámara con autofocus
2. Actualizar librería mobile_scanner
3. Probar con códigos QR de alta calidad (impresos, no en pantalla)
4. Asegurar buena iluminación

### Caso 3: "onDetect" se llama pero "barcodes.length" es 0

**Posible causa:** El scanner detecta algo pero no puede leer el código

**Diagnóstico:**
```bash
adb logcat | grep "Lista de barcodes vacía"
```

**Solución:**
1. Mejorar iluminación (usar el flash)
2. Acercar/alejar el código QR
3. Asegurar que el código QR está dentro del marco cuadrado
4. Probar con otro código QR diferente
5. Limpiar lente de la cámara

### Caso 4: Detecta pero rawValue es null

**Posible causa:** Código QR corrupto o formato no soportado

**Diagnóstico:**
```bash
adb logcat | grep "Barcode sin valor"
```

**Solución:**
1. Verificar que el código QR es válido
2. Usar generador de QR diferente
3. Probar con un QR simple (texto plano) primero

### Caso 5: Solo funciona con DataWedge, no con cámara

**Esperado:** En dispositivos TC26 es normal

**No es problema:** DataWedge es preferible por ser más rápido y confiable

**Si se necesita cámara:**
1. Asegurar que DataWedge no esté interfiriendo
2. Deshabilitar DataWedge temporalmente
3. Verificar `_dataWedgeAvailable = false` en los logs

## Comandos Útiles de Diagnóstico

```bash
# Ver TODOS los logs relevantes del scanner
adb logcat -c && adb logcat | grep -E "(🔍|📷|✅|❌|⚠️|Scanner|Camera|Barcode|QR|onDetect)"

# Solo errores
adb logcat *:E | grep paqueteria

# Verificar permisos en tiempo real
adb shell dumpsys package com.paqueteria.paqueteria_app | grep permission

# Ver actividad de la cámara a nivel del sistema
adb logcat | grep -i camera

# Limpiar logs y ver desde cero
adb logcat -c
adb logcat | grep paqueteria
```

## Testing con Códigos QR de Prueba

### QR Simple (para testing básico)
Crear un QR con este texto:
```
TEST-001
```

### QR Formato Completo (formato de la app)
```
PKG-2025-999999;;2025-01-20T10:00:00;Juan Test;999999999;test@email.com;DNI;12345678;Maria Test;888888888;Lima;;;;;;;;;;;;5.5;;;;;;;COURIER TEST
```

### Generadores de QR recomendados
- https://www.qr-code-generator.com/
- https://www.the-qrcode-generator.com/
- Usar tamaño grande (300x300 px mínimo)
- Usar corrección de errores HIGH

## Archivos Modificados

- `lib/presentation/screens/scan_screen.dart`
  - Líneas 19-35: Configuración mejorada del controller
  - Líneas 46-80: Inicialización asíncrona de cámara
  - Líneas 176-232: Callbacks detallados de detección
  - Líneas 244-303: Indicadores visuales de estado

## Próximos Pasos (Opcional)

Si después de este fix todavía hay problemas:

1. **Considerar usar plugin alternativo:**
   - `qr_code_scanner` (más antiguo pero muy estable)
   - `flutter_barcode_scanner` (específico para QR)

2. **Agregar botón de "Test Scanner":**
   - Que muestre info detallada del dispositivo
   - Estado de permisos
   - Capacidades de la cámara

3. **Implementar scanner manual:**
   - Opción de ingresar código manualmente
   - Útil si la cámara tiene problemas persistentes

## Versión

**Fix aplicado**: 2025-01-20
**Archivos modificados**: 1
**Tipo de fix**: Mejora de detección + debugging
