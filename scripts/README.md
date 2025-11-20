# 🚀 Scripts de Configuración Automática

## 📋 Descripción

Estos scripts configuran **automáticamente** el perfil de DataWedge en el Zebra TC26, sin necesidad de configuración manual.

---

## 🐧 Linux / macOS

### **Uso:**

```bash
cd /home/xeonix/Documentos/gdp/paqueteria_app/scripts
./configure_datawedge.sh
```

### **Requisitos:**
- ADB instalado
- TC26 conectado via USB
- Depuración USB activada en el TC26

---

## 🪟 Windows

### **Uso:**

1. Abre **Command Prompt** (CMD)
2. Navega a la carpeta:
   ```cmd
   cd C:\ruta\a\paqueteria_app\scripts
   ```
3. Ejecuta:
   ```cmd
   configure_datawedge.bat
   ```

### **Requisitos:**
- ADB instalado (Platform Tools de Android)
- TC26 conectado via USB
- Depuración USB activada

---

## ✅ ¿Qué Hace el Script?

1. ✅ Crea perfil **"PaqueteriaApp"**
2. ✅ Asocia con package `com.paqueteria.paqueteria_app`
3. ✅ Habilita **Barcode Input** con decoders:
   - QR Code
   - Code 128
   - Code 39
   - EAN-13
4. ✅ Configura **Intent Output**:
   - Action: `com.paqueteria.SCAN`
   - Delivery: Start Activity (0)
5. ✅ Deshabilita **Keystroke Output**
6. ✅ Habilita DataWedge

---

## 🔍 Verificar que Funcionó

Después de ejecutar el script:

```bash
# Ver logs en tiempo real
adb logcat | grep -E "DataWedge|flutter"
```

Luego:
1. Abre la app en el TC26
2. Presiona el botón lateral
3. Escanea un código QR

**Deberías ver:**
```
D/DataWedge: ✅ BroadcastReceiver registrado
D/DataWedge: 📡 BroadcastReceiver activado
D/DataWedge: ✅ Datos escaneados: 013501610002408...
I/flutter: 📦 Código escaneado globalmente: 013501610002408...
```

---

## 🛠️ Troubleshooting

### **"No se detectó ningún dispositivo"**

1. Verifica conexión USB
2. Activa **Depuración USB**:
   - Settings > About phone
   - Toca "Build number" 7 veces
   - Settings > Developer options > USB debugging ✓

3. Verifica ADB:
   ```bash
   adb devices
   ```
   Debe mostrar:
   ```
   List of devices attached
   XXXXXXXXXX      device
   ```

### **El script se ejecuta pero no funciona el escaneo**

1. **Reinicia la app:**
   ```bash
   adb shell am force-stop com.paqueteria.paqueteria_app
   ```

2. **Verifica el perfil en DataWedge:**
   - Abre DataWedge en el TC26
   - Busca perfil "PaqueteriaApp"
   - Debe tener ✓ verde

3. **Cambia Intent Delivery a Broadcast:**
   - Edita el script
   - Cambia `"intent_delivery\":\"0\"` por `"intent_delivery\":\"2\"`
   - Vuelve a ejecutar

### **Error de permisos**

Linux/macOS:
```bash
chmod +x configure_datawedge.sh
```

Windows:
- Ejecuta CMD como **Administrador**

---

## 📱 Instalar ADB

### **Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install adb
```

### **macOS (Homebrew):**
```bash
brew install android-platform-tools
```

### **Windows:**
1. Descarga [Platform Tools](https://developer.android.com/studio/releases/platform-tools)
2. Extrae en `C:\platform-tools\`
3. Agrega a PATH del sistema

---

## 🎯 Ventajas del Script vs Manual

| Aspecto | Manual | **Script** |
|---------|--------|------------|
| Tiempo | 10-15 min | **30 segundos** ⚡ |
| Errores | Posibles | **Cero** ✅ |
| Consistencia | Variable | **100%** ✅ |
| Múltiples TC26 | Repetitivo | **Automático** ✅ |

---

## 🔄 Resetear Configuración

Si necesitas empezar de cero:

```bash
# Eliminar perfil
adb shell am broadcast -a com.symbol.datawedge.api.ACTION \
  --es com.symbol.datawedge.api.DELETE_PROFILE "PaqueteriaApp"

# Volver a ejecutar script
./configure_datawedge.sh
```

---

## 📞 Soporte

Si el script no funciona:
1. Ejecuta con logs:
   ```bash
   ./configure_datawedge.sh 2>&1 | tee setup.log
   ```
2. Revisa `setup.log`
3. Verifica `VERIFICAR_DATAWEDGE.md`

---

**Última actualización:** 2025-10-08
**Compatible con:** TC26, TC21, TC52, TC57, TC72, TC77
**DataWedge:** 8.0+
