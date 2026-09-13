package com.example.smriti

import android.content.Intent

/**
 * One fired medication reminder, as handed from the Dart alarm isolate to
 * [ReminderReceiver] and on to [ReminderActivity].
 *
 * Extra keys must match `lib/core/reminders/reminder_launcher.dart`.
 */
data class Reminder(
    val medicationId: String,
    val reminderEventId: String,
    val title: String,
    val body: String,
    val photoPath: String?,
) {
    fun writeTo(intent: Intent) {
        intent.putExtra(EXTRA_MEDICATION_ID, medicationId)
        intent.putExtra(EXTRA_REMINDER_EVENT_ID, reminderEventId)
        intent.putExtra(EXTRA_TITLE, title)
        intent.putExtra(EXTRA_BODY, body)
        intent.putExtra(EXTRA_PHOTO_PATH, photoPath)
    }

    /** What the Dart reminder screen needs; it reads everything else from Drift. */
    fun toDartMap(): Map<String, String> = mapOf(
        EXTRA_MEDICATION_ID to medicationId,
        EXTRA_REMINDER_EVENT_ID to reminderEventId,
    )

    companion object {
        const val EXTRA_MEDICATION_ID = "medicationId"
        const val EXTRA_REMINDER_EVENT_ID = "reminderEventId"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_PHOTO_PATH = "photoPath"

        fun fromIntent(intent: Intent?): Reminder? {
            if (intent == null) return null
            val medicationId = intent.getStringExtra(EXTRA_MEDICATION_ID) ?: return null
            val reminderEventId = intent.getStringExtra(EXTRA_REMINDER_EVENT_ID) ?: return null
            return Reminder(
                medicationId = medicationId,
                reminderEventId = reminderEventId,
                title = intent.getStringExtra(EXTRA_TITLE) ?: "",
                body = intent.getStringExtra(EXTRA_BODY) ?: "",
                photoPath = intent.getStringExtra(EXTRA_PHOTO_PATH),
            )
        }
    }
}
