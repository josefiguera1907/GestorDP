package com.paqueteria.paqueteria_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class DataWedgeBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "DataWedge"
        private const val INTENT_ACTION = "com.paqueteria.SCAN"
        var eventSink: io.flutter.plugin.common.EventChannel.EventSink? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d(TAG, "📡 BroadcastReceiver estático activado")
        val action = intent?.action
        Log.d(TAG, "Action recibido: $action")

        if (action == INTENT_ACTION) {
            // Obtener datos del escaneo
            val scanData = intent.getStringExtra("com.symbol.datawedge.data_string")
            val labelType = intent.getStringExtra("com.symbol.datawedge.label_type")

            Log.d(TAG, "✅ Datos escaneados: $scanData")
            Log.d(TAG, "Tipo: $labelType")

            if (scanData != null) {
                Log.d(TAG, "📤 Enviando a Flutter...")
                // Enviar datos a Flutter
                eventSink?.success(scanData)
                Log.d(TAG, "✅ Datos enviados a Flutter")

                // Si la app no está en foreground, iniciarla
                if (eventSink == null) {
                    Log.d(TAG, "⚠️ EventSink es null, iniciando MainActivity...")
                    val launchIntent = Intent(context, MainActivity::class.java)
                    launchIntent.action = INTENT_ACTION
                    launchIntent.putExtra("com.symbol.datawedge.data_string", scanData)
                    launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    context?.startActivity(launchIntent)
                }
            } else {
                Log.e(TAG, "❌ scanData es null")
            }
        } else {
            Log.w(TAG, "⚠️ Action no coincide. Esperado: $INTENT_ACTION")
        }
    }
}
