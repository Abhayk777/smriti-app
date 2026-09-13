package com.example.smriti

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Entry point for a fired reminder on the native side.
 *
 * The Dart alarm isolate cannot reach MainActivity's MethodChannel (it runs in
 * its own FlutterEngine), so it sends an explicit broadcast here through
 * android_intent_plus instead.
 */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_SHOW_REMINDER) return
        val reminder = Reminder.fromIntent(intent) ?: return
        ReminderNotifier.show(context, reminder)
    }

    companion object {
        const val ACTION_SHOW_REMINDER = "com.example.smriti.action.SHOW_REMINDER"
    }
}
