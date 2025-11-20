# 🔧 Configuración de DataWedge para Botones Laterales TC26

## 📱 Configuración Manual (Recomendada)

Sigue estos pasos en tu Zebra TC26 para hacer que los botones laterales funcionen con la app:

### **Paso 1: Abrir DataWedge**
1. Desliza desde arriba de la pantalla
2. Toca el ícono de ajustes ⚙️
3. Busca y abre **DataWedge**

### **Paso 2: Crear Perfil Nuevo**
1. Toca el menú (⋮) en la esquina superior derecha
2. Selecciona **"New Profile"**
3. Nombre: `PaqueteriaApp`
4. Presiona **OK**

### **Paso 3: Asociar con la App**
1. Selecciona el perfil `PaqueteriaApp`
2. Desliza hacia abajo hasta **"Associated apps"**
3. Toca el **+** (más)
4. Selecciona:
   - **Package:** `com.paqueteria.paqueteria_app`
   - **Activity:** `*` (asterisco)
5. Presiona **OK**

### **Paso 4: Configurar Barcode Input**
1. En el perfil, toca **"Barcode Input"**
2. Asegúrate que esté **Enabled** ✅
3. Configurar decoders (opcionales):
   - **QR Code:** ✅ Enabled
   - **Code 128:** ✅ Enabled
   - **Code 39:** ✅ Enabled
   - **EAN-13:** ✅ Enabled

### **Paso 5: Configurar Intent Output**
1. Vuelve al perfil principal
2. Toca **"Intent Output"**
3. Habilita **"Intent output enabled"** ✅
4. Configurar:
   ```
   Intent action: com.paqueteria.SCAN
   Intent category: android.intent.category.DEFAULT
   Intent delivery: Start Activity (0)  ⚠️ IMPORTANTE: Probar con 0 primero
   ```

   **NOTA:** Si no funciona con "Start Activity (0)", cambiar a "Broadcast Intent (2)"

### **Paso 6: Configurar Data Strings**
1. En Intent Output, toca **"Data Strings"**
2. Asegúrate que esté configurado:
   ```
   Source: Scanners
   String Enabled: ✅
   String data: com.symbol.datawedge.data_string
   ```

### **Paso 7: Probar**
1. Abre la app Paquetería
2. Ve a cualquier pantalla
3. **Presiona el botón lateral del TC26** 📷
4. Apunta a un código QR
5. ¡El código debería escanearse automáticamente! ✅

---

## ⚡ Configuración Rápida (Importar Perfil)

### **Archivo de Perfil DataWedge:**

Crea un archivo llamado `dwprofile_paqueteriaapp.db` con esta configuración y colócalo en:
```
/sdcard/
```

Luego en DataWedge:
1. Menú (⋮) > **Import Profile**
2. Selecciona el archivo
3. ¡Listo!

---

## 🔍 Troubleshooting

### **Los botones no funcionan:**
1. Verifica que el perfil esté **Enabled**
2. Verifica que la app esté asociada correctamente
3. Reinicia la app

### **Escanea pero no procesa:**
1. Verifica el Intent Action: `com.paqueteria.SCAN`
2. Asegúrate que Intent delivery sea **Broadcast (2)**
3. Verifica que los permisos de la app estén habilitados

### **Conflicto con otras apps:**
1. En DataWedge, desactiva otros perfiles
2. O configura "Profile switching" correctamente

### **Ver logs:**
```bash
adb logcat | grep -i datawedge
```

---

## 📋 Resumen de Configuración

| Parámetro | Valor |
|-----------|-------|
| **Profile Name** | PaqueteriaApp |
| **Package** | com.paqueteria.paqueteria_app |
| **Activity** | * |
| **Barcode Input** | Enabled |
| **Intent Action** | com.paqueteria.SCAN |
| **Intent Category** | android.intent.category.DEFAULT |
| **Intent Delivery** | Broadcast Intent (2) |
| **Data String** | com.symbol.datawedge.data_string |

---

## 🎯 Botones del TC26

El TC26 tiene **2 botones laterales**:
- **Botón izquierdo:** Trigger principal (escaneo)
- **Botón derecho:** Trigger secundario (configurable)

Por defecto, ambos activan el escáner cuando DataWedge está configurado.

---

## 🚀 Ventajas de usar DataWedge

✅ **No requiere cámara** - Usa el escáner láser integrado
✅ **Más rápido** - Escaneo instantáneo
✅ **Mayor alcance** - Hasta 50cm de distancia
✅ **Mejor en luz baja** - Funciona en cualquier iluminación
✅ **Ergonómico** - Botones físicos fáciles de presionar
✅ **Menos batería** - No usa la cámara constantemente

---

## 📞 Soporte

Si tienes problemas:
1. Verifica la versión de DataWedge: **Settings > About TC26 > Software**
2. DataWedge debe ser versión **8.0+**
3. Consulta: https://techdocs.zebra.com/datawedge/

---

**Última actualización:** 2025-10-08
**Versión:** 1.0.0
**Compatible con:** TC26, TC21, TC52, TC57, TC72, TC77
