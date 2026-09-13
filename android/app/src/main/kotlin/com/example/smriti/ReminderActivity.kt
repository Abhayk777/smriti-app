package com.example.smriti

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Full-screen medication reminder, shown over the lock screen.
 *
 * `showWhenLocked` + `turnScreenOn` draw this activity on top of the keyguard
 * while the keyguard stays active. We never call `requestDismissKeyguard`, so
 * no PIN is asked for, and when the activity finishes the phone is still
 * locked. It runs its own FlutterEngine with the `reminderMain` entrypoint, so
 * nothing else in the app is reachable from here.
 */
class ReminderActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var voicePlayer: ReminderVoicePlayer? = null

    // Reminders that arrived before Dart asked for them via "ready".
    private val pending = mutableListOf<Map<String, String>>()
    private var dartReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOverLockScreen()
        Reminder.fromIntent(intent)?.let { pending.add(it.toDartMap()) }
    }

    override fun getDartEntrypointFunctionName(): String = "reminderMain"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel = methodChannel
        voicePlayer = ReminderVoicePlayer(applicationContext) { playing ->
            runOnUiThread { channel?.invokeMethod("voiceState", playing) }
        }
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "ready" -> {
                    dartReady = true
                    result.success(ArrayList(pending))
                    pending.clear()
                }
                "playVoice" -> {
                    val path = call.argument<String>("path") ?: ""
                    result.success(voicePlayer?.play(path) ?: false)
                }
                "stopVoice" -> {
                    voicePlayer?.stop()
                    result.success(null)
                }
                "dismissNotification" -> {
                    call.argument<String>("reminderEventId")?.let { ReminderNotifier.cancel(this, it) }
                    result.success(null)
                }
                "close" -> {
                    voicePlayer?.stop()
                    result.success(null)
                    finishAndRemoveTask()
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        showOverLockScreen()
        val reminder = Reminder.fromIntent(intent)?.toDartMap() ?: return
        if (dartReady) {
            channel?.invokeMethod("newReminder", reminder)
        } else {
            pending.add(reminder)
        }
    }

    override fun onResume() {
        super.onResume()
        AppVisibility.onActivityResumed()
    }

    override fun onPause() {
        AppVisibility.onActivityPaused()
        super.onPause()
    }

    override fun onDestroy() {
        voicePlayer?.release()
        channel?.setMethodCallHandler(null)
        super.onDestroy()
    }

    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    companion object {
        private const val CHANNEL = "com.example.smriti/reminder_screen"

        fun intent(context: Context, reminder: Reminder): Intent =
            Intent(context, ReminderActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                reminder.writeTo(this)
            }
    }
}
