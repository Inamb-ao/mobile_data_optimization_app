package com.example.mobile_data_optimization_app

import android.net.TrafficStats
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "traffic_manager_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up MethodChannel for communication with Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getNetworkStats" -> {
                    val networkUsage = getTrafficStats()
                    if (networkUsage != null) {
                        result.success(networkUsage)
                    } else {
                        result.error("UNAVAILABLE", "Unable to fetch network stats.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // Method to get network statistics using TrafficStats
    private fun getTrafficStats(): Map<String, Long>? {
        return try {
            val mobileRxBytes = TrafficStats.getMobileRxBytes()  // Mobile data received
            val mobileTxBytes = TrafficStats.getMobileTxBytes()  // Mobile data transmitted
            val totalRxBytes = TrafficStats.getTotalRxBytes()    // Total data received
            val totalTxBytes = TrafficStats.getTotalTxBytes()    // Total data transmitted

            mapOf(
                "mobileRxBytes" to mobileRxBytes,
                "mobileTxBytes" to mobileTxBytes,
                "totalRxBytes" to totalRxBytes,
                "totalTxBytes" to totalTxBytes
            )
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
