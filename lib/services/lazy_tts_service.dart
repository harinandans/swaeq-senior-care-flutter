import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Status of the lazy TTS service.
enum TtsStatus {
  /// TTS has not been initialized yet.
  notInitialized,

  /// TTS initialization is in progress.
  initializing,

  /// TTS is ready to use.
  ready,

  /// TTS initialization failed or timed out; disabled for this session.
  disabled,
}

/// Singleton service for lazy TTS initialization.
/// 
/// Key design: Does NOT initialize Android TextToSpeech until [initialize] is
/// explicitly called. This avoids the hang on Samsung Galaxy M17e where the
/// stock flutter_tts plugin creates TextToSpeech at plugin registration time.
class LazyTtsService {
  LazyTtsService._();
  static final instance = LazyTtsService._();

  static const _channel = MethodChannel('com.vidarka.swaeq_senior/lazy_tts');

  TtsStatus _status = TtsStatus.notInitialized;
  String? _failureReason;
  
  VoidCallback? _onStart;
  VoidCallback? _onDone;
  ValueChanged<String>? _onError;

  TtsStatus get status => _status;
  bool get isAvailable => _status == TtsStatus.ready;
  bool get isDisabled => _status == TtsStatus.disabled;
  String? get failureReason => _failureReason;

  /// Initialize TTS with a timeout. Call this AFTER the home screen is visible.
  /// 
  /// Returns true if TTS is ready, false if it failed/timed out.
  /// Once disabled, TTS stays disabled until app restart.
  Future<bool> initialize({int timeoutMs = 5000}) async {
    if (_status == TtsStatus.ready) return true;
    if (_status == TtsStatus.disabled) return false;
    if (_status == TtsStatus.initializing) {
      // Wait for in-progress init
      while (_status == TtsStatus.initializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _status == TtsStatus.ready;
    }

    _status = TtsStatus.initializing;
    _failureReason = null;

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'initTts',
        {'timeoutMs': timeoutMs},
      );

      final success = result?['success'] as bool? ?? false;
      final message = result?['message'] as String? ?? 'Unknown';

      if (success) {
        await _channel.invokeMethod('setSpeechRate', {'rate': 0.45});
        await _channel.invokeMethod('setVolume', {'volume': 1.0});
        await _channel.invokeMethod('setPitch', {'pitch': 1.0});
        
        _status = TtsStatus.ready;
        debugPrint('LazyTtsService: TTS initialized successfully');
        return true;
      } else {
        _status = TtsStatus.disabled;
        _failureReason = message;
        debugPrint('LazyTtsService: TTS init failed: $message');
        return false;
      }
    } catch (e) {
      _status = TtsStatus.disabled;
      _failureReason = e.toString();
      debugPrint('LazyTtsService: TTS init exception: $e');
      return false;
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onStart':
        _onStart?.call();
        break;
      case 'onDone':
        _onDone?.call();
        break;
      case 'onError':
        _onError?.call(call.arguments?.toString() ?? 'Unknown error');
        break;
    }
  }

  /// Speak text. Returns false if TTS is not available.
  Future<bool> speak(String text) async {
    if (_status != TtsStatus.ready) return false;
    try {
      final result = await _channel.invokeMethod<bool>('speak', {'text': text});
      return result ?? false;
    } catch (e) {
      debugPrint('LazyTtsService: speak error: $e');
      return false;
    }
  }

  /// Stop speaking.
  Future<void> stop() async {
    if (_status != TtsStatus.ready) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      debugPrint('LazyTtsService: stop error: $e');
    }
  }

  /// Set callbacks for TTS events.
  void setCallbacks({
    VoidCallback? onStart,
    VoidCallback? onDone,
    ValueChanged<String>? onError,
  }) {
    _onStart = onStart;
    _onDone = onDone;
    _onError = onError;
  }

  /// Clear callbacks.
  void clearCallbacks() {
    _onStart = null;
    _onDone = null;
    _onError = null;
  }
}
