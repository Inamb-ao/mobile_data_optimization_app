package com.example.mobile_data_optimization_app

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.net.NetworkTemplate
import android.os.Build
import android.os.Bundle
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {

    private val CHANNEL = "traffic_manager_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize the MethodChannel
        flutterEngine?.dartExecutor?.binaryMessenger?.let { binaryMessenger ->
            MethodChannel(binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "getNetworkStats") {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        val networkUsage = getNetworkStats()
                        if (networkUsage != -1L) {
                            result.success(networkUsage)
                        } else {
                            result.error("UNAVAILABLE", "Network stats not available.", null)
                        }
                    } else {
                        result.error("UNSUPPORTED_API", "This feature requires API level 24 or higher.", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.N) // Ensure compatibility with API level 24+
    private fun getNetworkStats(): Long {
        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        // Get the subscriber ID safely
        val subscriberId = getSubscriberId(telephonyManager) ?: return -1L

        // Define start and end time (last 24 hours)
        val bucketStart = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_MONTH, -1)
        }.timeInMillis
        val bucketEnd = Calendar.getInstance().timeInMillis

        return try {
            // Create a NetworkTemplate for mobile data
            val networkTemplate = NetworkTemplate.buildTemplateMobileAll(subscriberId)

            // Query network stats
            val bucket = networkStatsManager.querySummaryForDevice(
                networkTemplate,
                subscriberId,
                bucketStart,
                bucketEnd
            )

            // Return total bytes received and sent
            bucket.rxBytes + bucket.txBytes
        } catch (e: Exception) {
            e.printStackTrace()
            -1L
        }
    }

    private fun getSubscriberId(telephonyManager: TelephonyManager): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            subscriptionManager.activeSubscriptionInfoList?.firstOrNull()?.iccId
        } else {
            @Suppress("DEPRECATION")
            telephonyManager.subscriberId
        }
    }
}
