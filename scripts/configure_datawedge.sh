#!/bin/bash

# Script para configurar DataWedge automáticamente en TC26
# Uso: ./configure_datawedge.sh

echo "🔧 Configurando DataWedge para Paquetería App..."
echo ""

PROFILE_NAME="PaqueteriaApp"
PACKAGE_NAME="com.paqueteria.paqueteria_app"
INTENT_ACTION="com.paqueteria.SCAN"
INTENT_CATEGORY="android.intent.category.DEFAULT"

# Verificar conexión ADB
echo "📱 Verificando conexión con TC26..."
adb devices | grep -q "device$"
if [ $? -ne 0 ]; then
    echo "❌ No se detectó ningún dispositivo. Conecta el TC26 via USB."
    exit 1
fi
echo "✅ TC26 conectado"
echo ""

# Paso 1: Crear perfil
echo "1️⃣  Creando perfil '$PROFILE_NAME'..."
adb shell am broadcast -a com.symbol.datawedge.api.ACTION \
  --es com.symbol.datawedge.api.CREATE_PROFILE "$PROFILE_NAME"
sleep 1
echo "✅ Perfil creado"
echo ""

# Paso 2: Asociar app con el perfil
echo "2️⃣  Asociando app con el perfil..."
adb shell am broadcast -a com.symbol.datawedge.api.ACTION \
  --es com.symbol.datawedge.api.SET_CONFIG \
  --es PROFILE_NAME "$PROFILE_NAME" \
  --es PROFILE_ENABLED "true" \
  --es APP_LIST "[\
    {\"PACKAGE_NAME\":\"$PACKAGE_NAME\",\"ACTIVITY_LIST\":[\"*\"]}\
  ]"
sleep 1
echo "✅ App asociada"
echo ""

# Paso 3: Configurar Barcode Input
echo "3️⃣  Configurando Barcode Input..."
adb shell am broadcast -a com.symbol.datawedge.api.ACTION \
  --es com.symbol.datawedge.api.SET_CONFIG \
  --es PROFILE_NAME "$PROFILE_NAME" \
  --es PLUGIN_CONFIG "[\
    {\"PLUGIN_NAME\":\"BARCODE\",\
     \"RESET_CONFIG\":\"false\",\
     \"PARAM_LIST\":{\
       \"scanner_input_enabled\":\"true\",\
       \"decoder_qrcode\":\"true\",\
       \"decoder_code128\":\"true\",\
       \"decoder_code39\":\"true\",\
       \"decoder_ean13\":\"true\"\
     }\
    }\
  ]"
sleep 1
echo "✅ Barcode Input configurado"
echo ""

# Paso 4: Configurar Intent Output
echo "4️⃣  Configurando Intent Output..."
adb shell am broadcast -a com.symbol.datawedge.api.ACTION \
  --es com.symbol.datawedge.api.SET_CONFIG \
  --es PROFILE_NAME "$PROFILE_NAME" \
  --es PLUGIN_CONFIG "[\
    {\"PLUGIN_NAME\":\"INTENT\",\
     \"RESET_CONFIG\":\"false\",\
     \"PARAM_LIST\":{\
       \"intent_output_enabled\":\"true\",\
       \"intent_action\":\"$INTENT_ACTION\",\
       \"intent_category\":\"$INTENT_CATEGORY\",\
       \"intent_delivery\":\"0\"\
     }\
    }\
  ]"
sleep 1
echo "✅ Intent Output configurado"
echo ""

# Paso 5: Deshabilitar Keystroke Output
echo "5️⃣  Deshabilitando Keystroke Output..."
adb shell am broadcast -a com.symbol.datawedge.api.ACTION \
  --es com.symbol.datawedge.api.SET_CONFIG \
  --es PROFILE_NAME "$PROFILE_NAME" \
  --es PLUGIN_CONFIG "[\
    {\"PLUGIN_NAME\":\"KEYSTROKE\",\
     \"RESET_CONFIG\":\"false\",\
     \"PARAM_LIST\":{\
       \"keystroke_output_enabled\":\"false\"\
     }\
    }\
  ]"
sleep 1
echo "✅ Keystroke Output deshabilitado"
echo ""

# Paso 6: Habilitar el perfil
echo "6️⃣  Habilitando perfil..."
adb shell am broadcast -a com.symbol.datawedge.api.ACTION \
  --es com.symbol.datawedge.api.ENABLE_DATAWEDGE "true"
sleep 1
echo "✅ DataWedge habilitado"
echo ""

# Verificación
echo "🔍 Verificando configuración..."
adb shell am broadcast -a com.symbol.datawedge.api.ACTION \
  --es com.symbol.datawedge.api.GET_ACTIVE_PROFILE ""
sleep 1
echo ""

echo "╔════════════════════════════════════════════════════╗"
echo "║  ✅ DataWedge configurado correctamente            ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "📋 Configuración aplicada:"
echo "   • Perfil: $PROFILE_NAME"
echo "   • Package: $PACKAGE_NAME"
echo "   • Intent Action: $INTENT_ACTION"
echo "   • Intent Delivery: Start Activity (0)"
echo ""
echo "🎯 Próximos pasos:"
echo "   1. Abre la app en el TC26"
echo "   2. Presiona el botón lateral"
echo "   3. Escanea un código QR"
echo ""
echo "📊 Ver logs:"
echo "   adb logcat | grep -E \"DataWedge|flutter\""
echo ""
