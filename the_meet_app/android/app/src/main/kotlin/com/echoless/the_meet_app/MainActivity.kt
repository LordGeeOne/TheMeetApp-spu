package com.echoless.the_meet_app

import android.util.Log
import android.view.KeyEvent
import android.os.PowerManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.echoless.the_meet_app/volume_buttons"
    private var isListening = false
    private val TAG = "SafeModuleButtons"
    private lateinit var methodChannel: MethodChannel
    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "Setting up method channel")
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            Log.d(TAG, "Method call received: ${call.method}")
            when (call.method) {
                "startListening" -> {
                    isListening = true
                    acquireWakeLock()
                    Log.d(TAG, "Started listening for button presses with wake lock")
                    result.success(true)
                }
                "stopListening" -> {
                    isListening = false
                    releaseWakeLock()
                    Log.d(TAG, "Stopped listening for button presses and released wake lock")
                    result.success(true)
                }
                else -> {
                    Log.d(TAG, "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "$TAG::PanicButtonWakeLock"
            )
            wakeLock?.acquire(10*60*1000L /* 10 minutes */)
            Log.d(TAG, "Wake lock acquired for panic button monitoring")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire wake lock: ${e.message}")
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    Log.d(TAG, "Wake lock released")
                }
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release wake lock: ${e.message}")
        }
    }    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        // Log key events for debugging
        Log.d(TAG, "Key event: keyCode=${event.keyCode}, action=${event.action}, isListening=$isListening")
        
        // Process ONLY key down events when actively listening
        if (isListening && event.action == KeyEvent.ACTION_DOWN) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    Log.d(TAG, "🚨 PANIC: Volume UP pressed during SafeWalk monitoring")
                    sendButtonEvent("volume_up", "volume")
                    return true // Consume the event to prevent normal volume behavior
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    Log.d(TAG, "🚨 PANIC: Volume DOWN pressed during SafeWalk monitoring")
                    sendButtonEvent("volume_down", "volume")
                    return true // Consume the event to prevent normal volume behavior
                }
                // Add other hardware buttons if needed
                KeyEvent.KEYCODE_POWER -> {
                    // Optionally handle power button (be careful with this)
                    Log.d(TAG, "Power button detected during SafeWalk monitoring")
                    // sendButtonEvent("power", "hardware")
                    // return true
                }
            }
        }
        
        // Let system handle all other key events normally
        return super.dispatchKeyEvent(event)
    }

    private fun sendButtonEvent(action: String, type: String) {
        if (!isListening) {
            Log.d(TAG, "Ignoring button event - not listening")
            return
        }

        val args = HashMap<String, String>()
        args["action"] = action
        args["type"] = type
        
        Log.d(TAG, "🚨 SENDING PANIC EVENT to Flutter: action=$action, type=$type")
        
        try {
            if (::methodChannel.isInitialized) {
                methodChannel.invokeMethod("buttonPressed", args)
                Log.d(TAG, "✅ Panic event sent to Flutter successfully")
            } else {
                Log.e(TAG, "❌ Method channel not initialized - cannot send panic event")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to send panic event to Flutter: ${e.message}")
        }
    }

    override fun onDestroy() {
        releaseWakeLock()
        super.onDestroy()
    }

    override fun onPause() {
        super.onPause()
        // Don't release wake lock on pause - we want to keep monitoring
        Log.d(TAG, "Activity paused - keeping panic button monitoring active")
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "Activity resumed - panic button monitoring status: $isListening")
    }
}
