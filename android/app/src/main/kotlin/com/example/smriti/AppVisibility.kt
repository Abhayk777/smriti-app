package com.example.smriti

/**
 * Tracks whether any Smriti activity is currently resumed.
 *
 * While Smriti is on screen Android lets it start activities without the
 * "Display over other apps" permission, so [ReminderNotifier] can open the
 * reminder screen directly instead of relying on the full-screen intent.
 */
object AppVisibility {
    private var resumedActivities = 0

    val isVisible: Boolean
        @Synchronized get() = resumedActivities > 0

    @Synchronized
    fun onActivityResumed() {
        resumedActivities++
    }

    @Synchronized
    fun onActivityPaused() {
        if (resumedActivities > 0) resumedActivities--
    }
}
