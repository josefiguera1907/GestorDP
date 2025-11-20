package com.paqueteria.paqueteria_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "datawedge_channel"
    private val EVENT_CHANNEL = "datawedge_scan_events"
    private val PROFILE_NAME = "PaqueteriaApp"
    private val INTENT_ACTION = "com.paqueteria.SCAN"
    private val INTENT_CATEGORY = "android.intent.category.DEFAULT"

    private var eventSink: EventChannel.EventSink? = null
    private var scanReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel para comandos
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createProfile" -> {
                    createDataWedgeProfile()
                    result.success(true)
                }
                "configureIntents" -> {
                    configureDataWedgeIntents()
                    result.success(true)
                }
                "enableScanner" -> {
                    enableScanner()
                    result.success(true)
                }
                "disableScanner" -> {
                    disableScanner()
                    result.success(true)
                }
                "softwareTrigger" -> {
                    softwareTrigger()
                    result.success(true)
                }
                "checkDataWedge" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Event Channel para stream de datos escaneados
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    // Compartir el eventSink con el BroadcastReceiver estático
                    DataWedgeBroadcastReceiver.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    DataWedgeBroadcastReceiver.eventSink = null
                }
            }
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registerScanReceiver()
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == INTENT_ACTION) {
            val scanData = intent.getStringExtra("com.symbol.datawedge.data_string")
            if (scanData != null) {
                android.util.Log.d("DataWedge", "Intent directo recibido: $scanData")
                eventSink?.success(scanData)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterScanReceiver()
    }

    override fun onResume() {
        super.onResume()
        android.util.Log.d("DataWedge", "🔄 onResume - Activando perfil y escáner...")
        // Solo intentar activar DataWedge si estamos en un dispositivo Zebra
        try {
            switchToProfile()
            enableScanner()
        } catch (e: Exception) {
            android.util.Log.w("DataWedge", "⚠️ DataWedge no disponible (probablemente no es un dispositivo Zebra): ${e.message}")
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            disableScanner()
        } catch (e: Exception) {
            android.util.Log.w("DataWedge", "⚠️ Error deshabilitando escáner: ${e.message}")
        }
    }

    private fun registerScanReceiver() {
        if (scanReceiver == null) {
            scanReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    android.util.Log.d("DataWedge", "📡 BroadcastReceiver activado")
                    val action = intent?.action
                    android.util.Log.d("DataWedge", "Action recibido: $action")

                    if (action == INTENT_ACTION) {
                        // Obtener datos del escaneo
                        val scanData = intent.getStringExtra("com.symbol.datawedge.data_string")
                        val labelType = intent.getStringExtra("com.symbol.datawedge.label_type")

                        android.util.Log.d("DataWedge", "✅ Datos escaneados: $scanData")
                        android.util.Log.d("DataWedge", "Tipo: $labelType")

                        if (scanData != null) {
                            android.util.Log.d("DataWedge", "📤 Enviando a Flutter...")
                            // Enviar datos a Flutter
                            eventSink?.success(scanData)
                            android.util.Log.d("DataWedge", "✅ Datos enviados a Flutter")
                        } else {
                            android.util.Log.e("DataWedge", "❌ scanData es null")
                        }
                    } else {
                        android.util.Log.w("DataWedge", "⚠️ Action no coincide. Esperado: $INTENT_ACTION")
                    }
                }
            }

            val filter = IntentFilter()
            filter.addAction(INTENT_ACTION)
            filter.addCategory(INTENT_CATEGORY)

            // Android 14+ requiere especificar el flag de export
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(scanReceiver, filter, android.content.Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(scanReceiver, filter)
            }
            android.util.Log.d("DataWedge", "✅ BroadcastReceiver registrado para: $INTENT_ACTION")
        }
    }

    private fun unregisterScanReceiver() {
        scanReceiver?.let {
            unregisterReceiver(it)
            scanReceiver = null
        }
    }

    private fun createDataWedgeProfile() {
        try {
            sendDataWedgeIntent("com.symbol.datawedge.api.CREATE_PROFILE", PROFILE_NAME)

            // Asociar la app con el perfil
            val profileConfig = Bundle()
            profileConfig.putString("PROFILE_NAME", PROFILE_NAME)
            profileConfig.putString("PROFILE_ENABLED", "true")

            val appConfig = Bundle()
            appConfig.putString("PACKAGE_NAME", packageName)
            appConfig.putStringArray("ACTIVITY_LIST", arrayOf("*"))

            profileConfig.putParcelableArray("APP_LIST", arrayOf(appConfig))

            val intent = Intent()
            intent.action = "com.symbol.datawedge.api.ACTION"
            intent.putExtra("com.symbol.datawedge.api.SET_CONFIG", profileConfig)
            sendBroadcast(intent)
        } catch (e: Exception) {
            android.util.Log.w("DataWedge", "⚠️ Error creando perfil DataWedge: ${e.message}")
        }
    }

    private fun configureDataWedgeIntents() {
        try {
            val profileConfig = Bundle()
            profileConfig.putString("PROFILE_NAME", PROFILE_NAME)
            profileConfig.putString("PROFILE_ENABLED", "true")

            // Configurar Intent Output
            val intentConfig = Bundle()
            intentConfig.putString("PLUGIN_NAME", "INTENT")

            val intentProps = Bundle()
            intentProps.putString("intent_output_enabled", "true")
            intentProps.putString("intent_action", INTENT_ACTION)
            intentProps.putString("intent_category", INTENT_CATEGORY)
            intentProps.putString("intent_delivery", "2") // Broadcast

            intentConfig.putBundle("PARAM_LIST", intentProps)
            profileConfig.putBundle("PLUGIN_CONFIG", intentConfig)

            val intent = Intent()
            intent.action = "com.symbol.datawedge.api.ACTION"
            intent.putExtra("com.symbol.datawedge.api.SET_CONFIG", profileConfig)
            sendBroadcast(intent)
        } catch (e: Exception) {
            android.util.Log.w("DataWedge", "⚠️ Error configurando intents: ${e.message}")
        }
    }

    private fun switchToProfile() {
        try {
            android.util.Log.d("DataWedge", "🔄 Cambiando a perfil: $PROFILE_NAME")
            sendDataWedgeIntent("com.symbol.datawedge.api.SWITCH_TO_PROFILE", PROFILE_NAME)
        } catch (e: Exception) {
            android.util.Log.w("DataWedge", "⚠️ Error cambiando perfil: ${e.message}")
        }
    }

    private fun enableScanner() {
        try {
            android.util.Log.d("DataWedge", "🔄 Habilitando escáner...")
            sendDataWedgeIntent("com.symbol.datawedge.api.SCANNER_INPUT_PLUGIN", "ENABLE_PLUGIN")
        } catch (e: Exception) {
            android.util.Log.w("DataWedge", "⚠️ Error habilitando escáner: ${e.message}")
        }
    }

    private fun disableScanner() {
        try {
            android.util.Log.d("DataWedge", "🔄 Deshabilitando escáner...")
            sendDataWedgeIntent("com.symbol.datawedge.api.SCANNER_INPUT_PLUGIN", "DISABLE_PLUGIN")
        } catch (e: Exception) {
            android.util.Log.w("DataWedge", "⚠️ Error deshabilitando escáner: ${e.message}")
        }
    }

    private fun softwareTrigger() {
        try {
            val intent = Intent()
            intent.action = "com.symbol.datawedge.api.ACTION"
            intent.putExtra("com.symbol.datawedge.api.SOFT_SCAN_TRIGGER", "START_SCANNING")
            sendBroadcast(intent)
        } catch (e: Exception) {
            android.util.Log.w("DataWedge", "⚠️ Error con software trigger: ${e.message}")
        }
    }

    private fun sendDataWedgeIntent(action: String, extraKey: String, extraValue: String = "") {
        val intent = Intent()
        intent.action = "com.symbol.datawedge.api.ACTION"
        intent.putExtra(extraKey, extraValue)
        sendBroadcast(intent)
    }

    private fun sendDataWedgeIntent(extraKey: String, extraValue: String) {
        val intent = Intent()
        intent.action = "com.symbol.datawedge.api.ACTION"
        intent.putExtra(extraKey, extraValue)
        sendBroadcast(intent)
    }
}
