package com.example.nirbhoy_app

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.telephony.SmsManager
import android.view.KeyEvent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SMS_CHANNEL = "com.example.nirbhoy_app/sms"
    private val TRIGGER_CHANNEL = "com.example.nirbhoy_app/hardware_trigger"
    private var triggerChannel: MethodChannel? = null

    private val mainHandler = Handler(Looper.getMainLooper())
    private var isHoldingVolumeDown = false
    private var holdSecondsCount = 0
    private val HOLD_TARGET_SECONDS = 3

    private val holdProgressRunnable = object : Runnable {
        override fun run() {
            if (isHoldingVolumeDown) {
                holdSecondsCount++
                triggerChannel?.invokeMethod("holdProgress", holdSecondsCount)

                if (holdSecondsCount >= HOLD_TARGET_SECONDS) {
                    triggerVibration()
                    triggerChannel?.invokeMethod("triggerEmergencyAlarm", null)
                    isHoldingVolumeDown = false
                } else {
                    mainHandler.postDelayed(this, 1000L)
                }
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        triggerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TRIGGER_CHANNEL)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendDirectSMS") {
                val message = call.argument<String>("message")
                val recipients = call.argument<List<String>>("recipients")

                if (message != null && recipients != null) {
                    try {
                        val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            applicationContext.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }

                        for (recipient in recipients) {
                            val cleanNumber = recipient.trim()
                            if (cleanNumber.isNotEmpty()) {
                                val parts = smsManager.divideMessage(message)
                                if (parts.size > 1) {
                                    smsManager.sendMultipartTextMessage(cleanNumber, null, parts, null, null)
                                } else {
                                    smsManager.sendTextMessage(cleanNumber, null, message, null, null)
                                }
                            }
                        }
                        result.success("SMS Sent Successfully")
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", e.localizedMessage, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "Message or recipients missing", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            if (event.action == KeyEvent.ACTION_DOWN) {
                if (!isHoldingVolumeDown) {
                    isHoldingVolumeDown = true
                    holdSecondsCount = 0
                    triggerChannel?.invokeMethod("holdProgress", 0)
                    mainHandler.postDelayed(holdProgressRunnable, 1000L)
                }
                return true // Consume volume down event during emergency hold
            } else if (event.action == KeyEvent.ACTION_UP) {
                if (isHoldingVolumeDown) {
                    isHoldingVolumeDown = false
                    mainHandler.removeCallbacks(holdProgressRunnable)
                    triggerChannel?.invokeMethod("holdCancelled", null)
                }
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    private fun triggerVibration() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator?.vibrate(
                    VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else {
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(
                        VibrationEffect.createOneShot(500, VibrationEffect.DEFAULT_AMPLITUDE)
                    )
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(500)
                }
            }
        } catch (e: Exception) {
            // ignore
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mainHandler.removeCallbacks(holdProgressRunnable)
    }
}


