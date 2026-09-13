package com.example.smriti

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.util.Log
import java.io.File

/**
 * Plays the caregiver's voice note on the alarm stream.
 *
 * USAGE_ALARM means it follows alarm volume (audible when media volume is 0),
 * passes Do Not Disturb when alarms are allowed, and satisfies Android 17's
 * background-audio rules for apps holding the exact-alarm permission.
 */
class ReminderVoicePlayer(
    context: Context,
    private val onPlayingChanged: (Boolean) -> Unit,
) {
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private val attributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()
    private var player: MediaPlayer? = null
    private var focusRequest: AudioFocusRequest? = null

    /** Returns false if the file is missing or can't be played. */
    fun play(path: String): Boolean {
        stop()
        if (path.isEmpty() || !File(path).exists()) return false
        return try {
            requestFocus()
            player = MediaPlayer().apply {
                setAudioAttributes(attributes)
                setDataSource(path)
                setOnCompletionListener { finished() }
                setOnErrorListener { _, _, _ ->
                    finished()
                    true
                }
                prepare()
                start()
            }
            onPlayingChanged(true)
            true
        } catch (e: Exception) {
            Log.w("ReminderVoicePlayer", "Could not play $path", e)
            stop()
            false
        }
    }

    fun stop() {
        player?.let {
            try {
                if (it.isPlaying) it.stop()
            } catch (_: IllegalStateException) {
            }
            it.release()
        }
        player = null
        abandonFocus()
        onPlayingChanged(false)
    }

    fun release() = stop()

    private fun finished() {
        player?.release()
        player = null
        abandonFocus()
        onPlayingChanged(false)
    }

    private fun requestFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(attributes)
                .build()
            focusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
        }
    }

    private fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
    }
}
