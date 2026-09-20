import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Turns speech into words for the games, and fails quietly when it cannot.
///
/// Speech recognition needs a platform plugin, a microphone permission and,
/// on many phones, a network connection. None of that is guaranteed on an
/// elder's device, so every call here is guarded: when recognition is
/// unavailable the game simply keeps its typed input and nothing is thrown at
/// the screen.
class SpeechInput {
  SpeechInput({SpeechToText? engine}) : _engine = engine ?? SpeechToText();

  final SpeechToText _engine;

  bool _ready = false;
  bool _unavailable = false;

  /// True once the engine has started up and the microphone was allowed.
  bool get isReady => _ready;

  /// True when this device cannot do speech at all, so the screen can offer
  /// typing instead without pretending the microphone exists.
  bool get isUnavailable => _unavailable;

  bool get isListening => _engine.isListening;

  /// Starts the engine once. Returns false when speech is not available.
  Future<bool> prepare() async {
    if (_ready) return true;
    if (_unavailable) return false;
    try {
      _ready = await _engine.initialize(
        onError: (e) => debugPrint('Speech error: ${e.errorMsg}'),
        debugLogging: false,
      );
    } catch (e) {
      debugPrint('Speech unavailable: $e');
      _ready = false;
    }
    _unavailable = !_ready;
    return _ready;
  }

  /// Listens until [stop], reporting each phrase heard so far.
  ///
  /// [onWords] is called repeatedly with the running transcript, and once more
  /// with the final transcript when the elder stops or the pause runs out.
  Future<bool> listen({
    required void Function(String words, bool isFinal) onWords,
    String localeId = 'en_IN',
    Duration pauseFor = const Duration(seconds: 4),
    Duration listenFor = const Duration(seconds: 30),
  }) async {
    if (!await prepare()) return false;
    try {
      await _engine.listen(
        onResult: (r) => onWords(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: listenFor,
          pauseFor: pauseFor,
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Speech listen failed: $e');
      _unavailable = true;
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _engine.stop();
    } catch (_) {
      // Stopping a engine that never started is not worth reporting.
    }
  }

  Future<void> cancel() async {
    try {
      await _engine.cancel();
    } catch (_) {}
  }
}
