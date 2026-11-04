package com.luxelane.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createTripsChannel()
    }

    /**
     * Canal por defecto de los avisos (Android 8+), el que declara el
     * manifiesto para FCM. Nombre y descripción en el idioma del teléfono
     * (res/values, values-en, values-pt). Crearlo dos veces no cambia nada.
     */
    private fun createTripsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            getString(R.string.default_notification_channel_id),
            getString(R.string.notification_channel_trips_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.notification_channel_trips_description)
        }
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }
}
