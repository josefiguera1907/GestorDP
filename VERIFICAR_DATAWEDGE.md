# 🔍 Verificar que DataWedge está enviando datos

## Paso 1: Verificar logs en tiempo real

Conecta el TC26 via USB y ejecuta:

```bash
adb logcat | grep -i datawedge
```

Luego presiona el botón lateral y escanea un QR. Deberías ver:

```
D/DataWedge: ✅ BroadcastReceiver registrado para: com.paqueteria.SCAN
D/DataWedge: 📡 BroadcastReceiver activado
D/DataWedge: Action recibido: com.paqueteria.SCAN
D/DataWedge: ✅ Datos escaneados: 013501610002408;;2025-06-19 10:15:00;...
D/DataWedge: 📤 Enviando a Flutter...
D/DataWedge: ✅ Datos enviados a Flutter
```

## Paso 2: Verificar configuración de DataWedge

En el TC26:

1. Abre **DataWedge**
2. Selecciona perfil **"PaqueteriaApp"**
3. Verifica:

### ✅ Associated Apps
```
Package: com.paqueteria.paqueteria_app
Activity: *
```

### ✅ Barcode Input
```
Enabled: ✓
Decoder: QR Code ✓
```

### ✅ Intent Output
```
Enabled: ✓
Intent action: com.paqueteria.SCAN
Intent category: android.intent.category.DEFAULT
Intent delivery: 2 - Broadcast intent
```

### ✅ Intent Output > Intent Data
```
Source: Scanners
String enabled: ✓
String data: com.symbol.datawedge.data_string
```

## Paso 3: Probar con app de prueba

Si quieres verificar que DataWedge funciona sin la app:

1. Descarga **Intent Monitor** desde Play Store
2. Abre Intent Monitor
3. Presiona el botón lateral del TC26
4. Deberías ver el Intent:
   ```
   Action: com.paqueteria.SCAN
   Extra: com.symbol.datawedge.data_string = "tu_qr_data"
   ```

## Paso 4: Verificar que la app está recibiendo

En la app Flutter, abre cualquier pantalla y presiona el botón lateral.

Deberías ver en los logs:

```bash
adb logcat | grep -E "DataWedge|flutter"
```

Output esperado:
```
I/flutter: 📦 Código escaneado globalmente: 013501610002408...
I/flutter: 🎯 DataWedgeListener recibió: 013501610002408...
```

## ❌ Solución de Problemas

### No aparece nada en los logs

1. **Verificar que DataWedge esté habilitado:**
   ```bash
   adb shell am broadcast -a com.symbol.datawedge.api.ACTION \
     --es com.symbol.datawedge.api.GET_VERSION_INFO ""
   ```

2. **Verificar que el perfil está activo:**
   - Abre DataWedge
   - Ve a Profiles
   - "PaqueteriaApp" debe tener un check verde ✓

### El scan suena pero no registra

1. **Cambiar Intent delivery a "0 - Start Activity":**
   - DataWedge > PaqueteriaApp > Intent Output
   - Intent delivery: 0 (Start Activity)
   - Reinstala la app

2. **Verificar permisos:**
   ```bash
   adb shell pm grant com.paqueteria.paqueteria_app \
     android.permission.CAMERA
   ```

### Funciona en otras apps pero no en la nuestra

1. **Desinstalar completamente la app:**
   ```bash
   adb uninstall com.paqueteria.paqueteria_app
   ```

2. **Eliminar el perfil de DataWedge:**
   - DataWedge > Menú > Delete Profile > PaqueteriaApp

3. **Reinstalar y reconfigurar:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

4. **Volver a configurar DataWedge** según DATAWEDGE_SETUP.md

## ✅ Checklist Final

- [ ] DataWedge versión 8.0+
- [ ] Perfil "PaqueteriaApp" existe
- [ ] Perfil está enabled (✓)
- [ ] App está asociada
- [ ] Barcode Input enabled
- [ ] QR Code decoder enabled
- [ ] Intent Output enabled
- [ ] Intent action correcto: `com.paqueteria.SCAN`
- [ ] Intent delivery: Broadcast (2) o Start Activity (0)
- [ ] String data: `com.symbol.datawedge.data_string`
- [ ] App instalada desde APK release
- [ ] Logs muestran datos recibidos
