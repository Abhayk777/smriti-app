package com.example.smriti

import io.flutter.plugin.common.MethodChannel

/**
 * Lets [ReminderActivity] ask the main app's Flutter engine to sync.
 *
 * Only one engine may own the Supabase session: two engines refreshing the
 * same rotating refresh token can trip Supabase's reuse detection and sign
 * the device out. So while MainActivity's engine is alive, the reminder
 * screen hands syncing to it instead of starting Supabase itself.
 */
object MainEngineBridge {
    @Volatile
    var channel: MethodChannel? = null

    /** Returns false if the main engine isn't running. */
    fun requestSync(): Boolean {
        val target = channel ?: return false
        target.invokeMethod("syncNow", null)
        return true
    }
}
