package com.luxelane.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity

// flutter_stripe needs a FragmentActivity (its card sheets are fragments).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createTripsChannel()
    }

    // Ride alerts (new requests, chauffeur arriving) ring and pop up: pushes
    // name this channel (functions/src/push.ts) and the manifest makes it the
    // default. Creating it again is a no-op.
    private fun createTripsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            getString(R.string.trips_channel_id),
            getString(R.string.trips_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        )
        channel.description = getString(R.string.trips_channel_description)
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
