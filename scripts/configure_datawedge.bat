@echo off
REM Script para configurar DataWedge en TC26 desde Windows
REM Uso: configure_datawedge.bat

echo.
echo ================================================================
echo    Configurador Automatico de DataWedge para Paqueteria App
echo ================================================================
echo.

set PROFILE_NAME=PaqueteriaApp
set PACKAGE_NAME=com.paqueteria.paqueteria_app
set INTENT_ACTION=com.paqueteria.SCAN
set INTENT_CATEGORY=android.intent.category.DEFAULT

echo Verificando conexion con TC26...
adb devices | findstr "device" >nul
if errorlevel 1 (
    echo [ERROR] No se detecto ningun dispositivo.
    echo         Conecta el TC26 via USB y activa depuracion USB.
    pause
    exit /b 1
)
echo [OK] TC26 conectado
echo.

echo [1/6] Creando perfil '%PROFILE_NAME%'...
adb shell am broadcast -a com.symbol.datawedge.api.ACTION --es com.symbol.datawedge.api.CREATE_PROFILE "%PROFILE_NAME%"
timeout /t 1 >nul
echo [OK] Perfil creado
echo.

echo [2/6] Asociando app con el perfil...
adb shell am broadcast -a com.symbol.datawedge.api.ACTION --es com.symbol.datawedge.api.SET_CONFIG --es PROFILE_NAME "%PROFILE_NAME%" --es PROFILE_ENABLED "true" --es APP_LIST "[{\"PACKAGE_NAME\":\"%PACKAGE_NAME%\",\"ACTIVITY_LIST\":[\"*\"]}]"
timeout /t 1 >nul
echo [OK] App asociada
echo.

echo [3/6] Configurando Barcode Input...
adb shell am broadcast -a com.symbol.datawedge.api.ACTION --es com.symbol.datawedge.api.SET_CONFIG --es PROFILE_NAME "%PROFILE_NAME%" --es PLUGIN_CONFIG "[{\"PLUGIN_NAME\":\"BARCODE\",\"RESET_CONFIG\":\"false\",\"PARAM_LIST\":{\"scanner_input_enabled\":\"true\",\"decoder_qrcode\":\"true\",\"decoder_code128\":\"true\",\"decoder_code39\":\"true\",\"decoder_ean13\":\"true\"}}]"
timeout /t 1 >nul
echo [OK] Barcode Input configurado
echo.

echo [4/6] Configurando Intent Output...
adb shell am broadcast -a com.symbol.datawedge.api.ACTION --es com.symbol.datawedge.api.SET_CONFIG --es PROFILE_NAME "%PROFILE_NAME%" --es PLUGIN_CONFIG "[{\"PLUGIN_NAME\":\"INTENT\",\"RESET_CONFIG\":\"false\",\"PARAM_LIST\":{\"intent_output_enabled\":\"true\",\"intent_action\":\"%INTENT_ACTION%\",\"intent_category\":\"%INTENT_CATEGORY%\",\"intent_delivery\":\"0\"}}]"
timeout /t 1 >nul
echo [OK] Intent Output configurado
echo.

echo [5/6] Deshabilitando Keystroke Output...
adb shell am broadcast -a com.symbol.datawedge.api.ACTION --es com.symbol.datawedge.api.SET_CONFIG --es PROFILE_NAME "%PROFILE_NAME%" --es PLUGIN_CONFIG "[{\"PLUGIN_NAME\":\"KEYSTROKE\",\"RESET_CONFIG\":\"false\",\"PARAM_LIST\":{\"keystroke_output_enabled\":\"false\"}}]"
timeout /t 1 >nul
echo [OK] Keystroke deshabilitado
echo.

echo [6/6] Habilitando DataWedge...
adb shell am broadcast -a com.symbol.datawedge.api.ACTION --es com.symbol.datawedge.api.ENABLE_DATAWEDGE "true"
timeout /t 1 >nul
echo [OK] DataWedge habilitado
echo.

echo ================================================================
echo    CONFIGURACION COMPLETADA EXITOSAMENTE
echo ================================================================
echo.
echo Configuracion aplicada:
echo   - Perfil: %PROFILE_NAME%
echo   - Package: %PACKAGE_NAME%
echo   - Intent Action: %INTENT_ACTION%
echo   - Intent Delivery: Start Activity (0)
echo.
echo Proximos pasos:
echo   1. Abre la app Paqueteria en el TC26
echo   2. Presiona el boton lateral
echo   3. Escanea un codigo QR
echo.
echo Ver logs en tiempo real:
echo   adb logcat | findstr "DataWedge flutter"
echo.
pause
