import 'dart:io';

import 'package:just_audio/just_audio.dart';

/// Plays a caregiver's pre-recorded voice file from disk.
///
/// Abstracted so screens can be widget-tested without an audio backend. The
/// full voice layer (phrase keys, language packs, constrained voice input) is
/// task A16; this is only what the reminder screen needs.
abstract class VoicePlayer {
  /// Plays [path]. Does nothing if the file is missing — per APP-BUILD-SPEC.md
  /// §6, a missing media file is skipped silently rather than surfaced.
  Future<void> play(String path);

  Future<void> stop();

  Future<void> dispose();
}

class JustAudioVoicePlayer implements VoicePlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(String path) async {
    if (path.isEmpty || !File(path).existsSync()) return;
    await _player.setFilePath(path);
    await _player.play();
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

/// Used where playback is not wanted (tests, and any surface that has no audio
/// yet).
class SilentVoicePlayer implements VoicePlayer {
  const SilentVoicePlayer();

  final List<String> played = const [];

  @override
  Future<void> play(String path) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
