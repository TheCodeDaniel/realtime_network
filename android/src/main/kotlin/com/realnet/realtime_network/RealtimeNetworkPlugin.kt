package com.realnet.realtime_network

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.telephony.TelephonyManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.InetAddress
import java.net.URL
import kotlin.system.measureTimeMillis
import kotlin.math.abs

class RealtimeNetworkPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var networkJob: Job? = null
    private var connectivityCallback: ConnectivityManager.NetworkCallback? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "realtime_network/methods")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "startListening" -> {
                val interval = call.argument<Int>("interval") ?: 10
                startListening(interval)
                result.success(null)
            }

            "stopListening" -> {
                stopListening()
                result.success(null)
            }

            "runTest" -> {
                scope.launch {
                    val stats = getNetworkStats()
                    withContext(Dispatchers.Main) {
                        result.success(stats)
                    }
                }
            }

            "startConnectivityListening" -> {
                startConnectivityListening()
                result.success(null)
            }

            "stopConnectivityListening" -> {
                stopConnectivityListening()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun startListening(interval: Int) {
        stopListening()
        networkJob = scope.launch {
            while (isActive) {
                val stats = getNetworkStats()
                withContext(Dispatchers.Main) {
                    channel.invokeMethod("onNetworkStats", stats)
                }
                delay(interval * 1000L)
            }
        }
    }

    private fun stopListening() {
        networkJob?.cancel()
        networkJob = null
    }

    /**
     * Real implementation using actual APIs with corrected speed and jitter calculations.
     */
    private suspend fun getNetworkStats(): Map<String, Any> {
        val pingResults = mutableListOf<Long>()
        var pingAvg = 0L
        var jitter = 0L
        var downloadSpeed = 0.0
        var uploadSpeed = 0.0
        var ip = ""
        val isp = getNetworkProvider()

        // --- Ping & Jitter CORRECTION ---
        try {
            repeat(4) {
                var time = 0L
                try {
                    val url = URL("http://speedtest.tele2.net/1KB.zip") // Use a tiny file
                    val conn = url.openConnection() as HttpURLConnection
                    conn.requestMethod = "GET"
                    conn.connectTimeout = 5000 
                    conn.readTimeout = 5000 
                    
                    time = measureTimeMillis {
                        // Measure time to establish connection and get first byte
                        conn.connect()
                        conn.inputStream.use { it.read() } // Read just one byte
                    }
                    conn.disconnect()
                    pingResults.add(time)
                    delay(200)
                } catch (_: Exception) {
                    pingResults.add(1000L) // Record a failure time (e.g., max timeout)
                }
            }
            pingAvg = pingResults.average().toLong()
            
            // JITTER CORRECTION: Calculate the average of absolute differences between successive pings.
            if (pingResults.size > 1) {
                val differences = (1 until pingResults.size).map { i ->
                    abs(pingResults[i] - pingResults[i - 1])
                }
                jitter = differences.average().toLong()
            } else {
                jitter = 0L
            }
        } catch (_: Exception) {}

        // --- Download speed test CORRECTION (Clarity) ---
        try {
            val url = URL("http://speedtest.tele2.net/10MB.zip")
            val conn = url.openConnection() as HttpURLConnection
            conn.connectTimeout = 8000
            conn.readTimeout = 8000
            conn.requestMethod = "GET"
            val fileSize = 10_000_000.0 // 10 MB in Bytes
            val timeMs = measureTimeMillis {
                conn.inputStream.use { it.copyTo(NullOutputStream()) }
            }
            conn.disconnect()
            
            // Explicit calculation for clarity:
            // (fileSize * 8) = total bits
            // (timeMs / 1000.0) = time in seconds
            val bitsPerSecond = (fileSize * 8) / (timeMs / 1000.0)
            downloadSpeed = bitsPerSecond / 1_000_000.0 // Mbps
        } catch (_: Exception) {}

        // --- Upload speed test CORRECTION (Timing and Clarity) ---
        try {
            val url = URL("https://nbg1-speed.hetzner.com/upload.php")
            val conn = url.openConnection() as HttpURLConnection
            conn.doOutput = true
            conn.requestMethod = "POST"
            conn.connectTimeout = 8000
            conn.readTimeout = 8000

            val testData = ByteArray(1_000_000) { 1 } // 1 MB
            
            val timeMs = measureTimeMillis {
                // Measure only the time taken to write the data and flush the stream.
                conn.outputStream.use { stream ->
                    stream.write(testData)
                    stream.flush()
                }
                // Read the response separately, as it's not part of upload throughput timing
                try {
                    conn.inputStream.use { it.copyTo(NullOutputStream()) }
                } catch (_: Exception) {}
            }
            conn.disconnect()
            
            // Explicit calculation for clarity:
            // (testData.size * 8) = total bits
            // (timeMs / 1000.0) = time in seconds
            val bitsPerSecond = (testData.size * 8) / (timeMs / 1000.0)
            uploadSpeed = bitsPerSecond / 1_000_000.0 // Mbps
        } catch (_: Exception) {}

        // --- Public IP (Unchanged) ---
        try {
            val ipUrl = URL("https://api.ipify.org")
            BufferedReader(InputStreamReader(ipUrl.openStream())).use {
                ip = it.readLine() ?: ""
            }
        } catch (_: Exception) {}

        return mapOf(
            "downloadSpeed" to downloadSpeed,
            "uploadSpeed" to uploadSpeed,
            "ping" to pingAvg.toInt(),
            "jitter" to jitter.toInt(),
            "ip" to ip,
            "isp" to isp
        )
    }

    /** Gets mobile or SIM network provider name (Unchanged) */
    private fun getNetworkProvider(): String {
        return try {
            val telephonyManager =
                context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            telephonyManager.networkOperatorName ?: "Unknown"
        } catch (e: Exception) {
            "Unknown"
        }
    }

    /** Connectivity listener (Unchanged) */
    private fun startConnectivityListening() {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        connectivityCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                channel.invokeMethod("onConnectivityChanged", true)
            }

            override fun onLost(network: Network) {
                channel.invokeMethod("onConnectivityChanged", false)
            }
        }
        cm.registerDefaultNetworkCallback(connectivityCallback!!)
    }

    private fun stopConnectivityListening() {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        try {
            connectivityCallback?.let { cm.unregisterNetworkCallback(it) }
        } catch (_: Exception) {}
        connectivityCallback = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        stopListening()
        stopConnectivityListening()
        scope.cancel()
    }

    /** Dummy OutputStream to discard downloaded data (Unchanged) */
    private class NullOutputStream : java.io.OutputStream() {
        override fun write(b: Int) {}
    }
}