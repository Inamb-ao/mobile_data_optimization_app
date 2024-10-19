package com.example.mobile_data_optimization_app

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.os.Bundle
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {

    private val CHANNEL = "traffic_manager_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getNetworkStats") {
                val networkUsage = getNetworkStats()
                if (networkUsage != -1L) {
                    result.success(networkUsage)
                } else {
                    result.error("UNAVAILABLE", "Network stats not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    // Method to get network statistics using NetworkStatsManager
    private fun getNetworkStats(): Long {
        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        val bucketStart = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_MONTH, -1)  // 24 hours ago
        }.timeInMillis
        val bucketEnd = Calendar.getInstance().timeInMillis

        return try {
            val bucket = networkStatsManager.querySummaryForDevice(
                NetworkStats.Bucket.DEFAULT_NETWORK,
                telephonyManager.subscriberId,
                bucketStart,
                bucketEnd
            )
            bucket.rxBytes + bucket.txBytes  // Total bytes received and sent
        } catch (e: Exception) {
            e.printStackTrace()
            -1L  // Error case
        }
    }
}
