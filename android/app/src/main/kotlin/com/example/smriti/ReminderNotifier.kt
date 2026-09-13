package com.example.smriti

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import java.io.File

/**
 * Posts the medication reminder notification and opens [ReminderActivity].
 *
 * How the full-screen reminder reaches the user in each device state:
 * - Locked or screen off: the notification's full-screen intent opens
 *   ReminderActivity over the lock screen (no PIN needed).
 * - Unlocked, on the home screen or in another app: Android only shows a
 *   heads-up banner for a full-screen intent, so we start the activity
 *   ourselves. Android allows that only while the user has granted
 *   "Display over other apps" (SYSTEM_ALERT_WINDOW) or Smriti is on screen.
 */
object ReminderNotifier {
    private const val TAG = "ReminderNotifier"
    private const val CHANNEL_ID = "medication_reminder_v2"
    // Channel created by flutter_local_notifications before reminders moved to
    // native code. Channel settings are immutable, hence the new ID.
    private const val LEGACY_CHANNEL_ID = "medication_reminder"
    private const val MAX_PHOTO_PX = 1024

    fun notificationId(reminderEventId: String): Int = reminderEventId.hashCode()

    fun show(context: Context, reminder: Reminder) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureChannel(manager)
        wakeScreen(context)

        val launchIntent = ReminderActivity.intent(context, reminder)
        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId(reminder.reminderEventId),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        manager.notify(
            notificationId(reminder.reminderEventId),
            buildNotification(context, reminder, pendingIntent),
        )

        if (Settings.canDrawOverlays(context) || AppVisibility.isVisible) {
            try {
                context.startActivity(launchIntent)
            } catch (e: Exception) {
                Log.w(TAG, "Direct launch of reminder screen failed", e)
            }
        }
    }

    fun cancel(context: Context, reminderEventId: String) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(notificationId(reminderEventId))
    }

    private fun buildNotification(
        context: Context,
        reminder: Reminder,
        pendingIntent: PendingIntent,
    ): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
                .setPriority(Notification.PRIORITY_MAX)
                .setDefaults(Notification.DEFAULT_ALL)
        }

        builder
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(reminder.title)
            .setContentText(reminder.body)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(true)
            .setContentIntent(pendingIntent)
            .setFullScreenIntent(pendingIntent, true)

        decodePhoto(reminder.photoPath)?.let { photo ->
            builder
                .setLargeIcon(photo)
                .setStyle(
                    Notification.BigPictureStyle()
                        .bigPicture(photo)
                        .setSummaryText(reminder.body),
                )
        }
        return builder.build()
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (manager.getNotificationChannel(LEGACY_CHANNEL_ID) != null) {
            manager.deleteNotificationChannel(LEGACY_CHANNEL_ID)
        }
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Medicine reminders",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Full-screen reminders to take medicine"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 600, 300, 600)
            // Short chime at alarm volume; the caregiver's voice note follows
            // from ReminderActivity.
            setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
        }
        manager.createNotificationChannel(channel)
    }

    @Suppress("DEPRECATION")
    private fun wakeScreen(context: Context) {
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            if (powerManager.isInteractive) return
            powerManager.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "smriti:reminder_wake",
            ).acquire(10_000)
        } catch (e: Exception) {
            Log.w(TAG, "Could not wake screen", e)
        }
    }

    private fun decodePhoto(path: String?): Bitmap? {
        if (path.isNullOrEmpty() || !File(path).exists()) return null
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sampleSize = 1
            while (bounds.outWidth / (sampleSize * 2) >= MAX_PHOTO_PX ||
                bounds.outHeight / (sampleSize * 2) >= MAX_PHOTO_PX
            ) {
                sampleSize *= 2
            }
            BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sampleSize })
        } catch (e: Exception) {
            Log.w(TAG, "Could not decode pill photo $path", e)
            null
        }
    }
}
