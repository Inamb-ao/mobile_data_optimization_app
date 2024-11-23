package com.example.mobile_data_optimization_app

import android.net.TrafficStats
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Define the channel name for communication between Flutter and native Android
    private val CHANNEL = "traffic_manager_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up MethodChannel to handle calls from Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getNetworkStats" -> {
                    // Fetch network statistics using TrafficStats
                    val networkUsage = getTrafficStats()
                    if (networkUsage != null) {
                        result.success(networkUsage)  // Return the result to Flutter
                    } else {
                        result.error("UNAVAILABLE", "Unable to fetch network stats.", null)
                    }
                }
                else -> result.notImplemented()  // Handle unsupported methods
            }
        }
    }

    /**
     * Fetch network statistics using Android's TrafficStats class.
     *
     * @return A map containing mobile and total data received and transmitted in bytes.
     */
    private fun getTrafficStats(): Map<String, Long>? {
        return try {
            // Get data usage statistics
            val mobileRxBytes = TrafficStats.getMobileRxBytes()  // Mobile data received in bytes
            val mobileTxBytes = TrafficStats.getMobileTxBytes()  // Mobile data transmitted in bytes
            val totalRxBytes = TrafficStats.getTotalRxBytes()    // Total data received in bytes (mobile + Wi-Fi)
            val totalTxBytes = TrafficStats.getTotalTxBytes()    // Total data transmitted in bytes (mobile + Wi-Fi)

            // Return data usage stats as a map
            mapOf(
                "mobileRxBytes" to mobileRxBytes,
                "mobileTxBytes" to mobileTxBytes,
                "totalRxBytes" to totalRxBytes,
                "totalTxBytes" to totalTxBytes
            )
        } catch (e: Exception) {
            // Print the stack trace in case of an error
            e.printStackTrace()
            null  // Return null if an error occurs
        }
    }
}
