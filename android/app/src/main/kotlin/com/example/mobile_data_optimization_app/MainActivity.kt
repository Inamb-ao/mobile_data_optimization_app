package com.example.mobile_data_optimization_app

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.TrafficStats
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "traffic_manager_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                "checkUsageStatsPermission" -> {
                    val hasPermission = hasUsageStatsPermission()
                    result.success(hasPermission)
                }
                "requestUsageStatsPermission" -> {
                    openUsageStatsSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
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
            val mobileRxBytes = TrafficStats.getMobileRxBytes()
            val mobileTxBytes = TrafficStats.getMobileTxBytes()
            val totalRxBytes = TrafficStats.getTotalRxBytes()
            val totalTxBytes = TrafficStats.getTotalTxBytes()

            // Fallback if TrafficStats returns invalid data
            if (mobileRxBytes < 0 || mobileTxBytes < 0 || totalRxBytes < 0 || totalTxBytes < 0) {
                Log.w("TrafficStats", "Invalid TrafficStats data. Returning default values.")
                mapOf(
                    "mobileRxBytes" to 0L,
                    "mobileTxBytes" to 0L,
                    "totalRxBytes" to 0L,
                    "totalTxBytes" to 0L
                )
            } else {
                mapOf(
                    "mobileRxBytes" to mobileRxBytes,
                    "mobileTxBytes" to mobileTxBytes,
                    "totalRxBytes" to totalRxBytes,
                    "totalTxBytes" to totalTxBytes
                )
            }
        } catch (e: Exception) {
            Log.e("TrafficStats", "Error fetching network stats", e)
            null
        }
    }

    /**
     * Check if the app has usage stats permission.
     *
     * @return Boolean indicating whether the app has the permission.
     */
    private fun hasUsageStatsPermission(): Boolean {
        val appOpsManager = ContextCompat.getSystemService(this, AppOpsManager::class.java) ?: return false
        val mode = appOpsManager.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Open the settings page to grant usage stats permission.
     */
    private fun openUsageStatsSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        } catch (e: Exception) {
            Log.e("UsageStats", "Failed to open usage stats settings", e)
        }
    }
}
