package com.vidarka.swaeq_senior

import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * Lazy TTS Plugin that does NOT initialize TextToSpeech at attach time.
 * TTS is only created when explicitly requested via "initTts" method call,
 * with a configurable timeout to prevent hanging on problematic devices.
 */
class LazyTtsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var handler: Handler? = null
    
    private var tts: TextToSpeech? = null
    private var ttsReady = AtomicBoolean(false)
    private var ttsInitFailed = AtomicBoolean(false)
    private var bundle: Bundle? = null
    
    companion object {
        private const val TAG = "LazyTtsPlugin"
        private const val CHANNEL_NAME = "com.vidarka.swaeq_senior/lazy_tts"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
        handler = Handler(Looper.getMainLooper())
        bundle = Bundle()
        Log.d(TAG, "Plugin attached - TTS NOT initialized (lazy)")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        tts?.stop()
        tts?.shutdown()
        tts = null
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
        handler = null
        ttsReady.set(false)
        ttsInitFailed.set(false)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initTts" -> {
                val timeoutMs = call.argument<Int>("timeoutMs") ?: 5000
                initTtsWithTimeout(timeoutMs, result)
            }
            "speak" -> {
                val text = call.argument<String>("text") ?: ""
                speak(text, result)
            }
            "stop" -> {
                stop(result)
            }
            "isAvailable" -> {
                result.success(ttsReady.get() && !ttsInitFailed.get())
            }
            "setLanguage" -> {
                val language = call.argument<String>("language") ?: "en-US"
                setLanguage(language, result)
            }
            "setSpeechRate" -> {
                val rate = call.argument<Double>("rate") ?: 0.5
                setSpeechRate(rate.toFloat(), result)
            }
            "setVolume" -> {
                val volume = call.argument<Double>("volume") ?: 1.0
                setVolume(volume.toFloat(), result)
            }
            "setPitch" -> {
                val pitch = call.argument<Double>("pitch") ?: 1.0
                setPitch(pitch.toFloat(), result)
            }
            "shutdown" -> {
                shutdownTts(result)
            }
            else -> result.notImplemented()
        }
    }

    private fun initTtsWithTimeout(timeoutMs: Int, result: MethodChannel.Result) {
        if (ttsReady.get()) {
            result.success(mapOf("success" to true, "message" to "TTS already initialized"))
            return
        }
        
        if (ttsInitFailed.get()) {
            result.success(mapOf("success" to false, "message" to "TTS init previously failed"))
            return
        }

        val ctx = context
        if (ctx == null) {
            ttsInitFailed.set(true)
            result.success(mapOf("success" to false, "message" to "Context not available"))
            return
        }

        Thread {
            val initLatch = CountDownLatch(1)
            val initStatus = AtomicInteger(TextToSpeech.ERROR)
            var localTts: TextToSpeech? = null

            try {
                handler?.post {
                    try {
                        localTts = TextToSpeech(ctx) { status ->
                            initStatus.set(status)
                            initLatch.countDown()
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "TTS constructor threw: ${e.message}")
                        initLatch.countDown()
                    }
                }

                val completed = initLatch.await(timeoutMs.toLong(), TimeUnit.MILLISECONDS)

                handler?.post {
                    if (!completed) {
                        Log.w(TAG, "TTS init timed out after ${timeoutMs}ms")
                        localTts?.shutdown()
                        ttsInitFailed.set(true)
                        result.success(mapOf("success" to false, "message" to "TTS init timed out"))
                        return@post
                    }

                    if (initStatus.get() != TextToSpeech.SUCCESS) {
                        Log.w(TAG, "TTS init failed with status: ${initStatus.get()}")
                        localTts?.shutdown()
                        ttsInitFailed.set(true)
                        result.success(mapOf("success" to false, "message" to "TTS init failed with status ${initStatus.get()}"))
                        return@post
                    }

                    tts = localTts
                    tts?.setOnUtteranceProgressListener(utteranceListener)
                    
                    try {
                        val locale = Locale.forLanguageTag("en-US")
                        if (tts?.isLanguageAvailable(locale) ?: TextToSpeech.LANG_NOT_SUPPORTED >= TextToSpeech.LANG_AVAILABLE) {
                            tts?.language = locale
                        }
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to set default language: ${e.message}")
                    }

                    ttsReady.set(true)
                    Log.d(TAG, "TTS initialized successfully")
                    result.success(mapOf("success" to true, "message" to "TTS initialized"))
                }
            } catch (e: Exception) {
                Log.e(TAG, "TTS init exception: ${e.message}")
                handler?.post {
                    ttsInitFailed.set(true)
                    result.success(mapOf("success" to false, "message" to "TTS init exception: ${e.message}"))
                }
            }
        }.start()
    }

    private val utteranceListener = object : UtteranceProgressListener() {
        override fun onStart(utteranceId: String?) {
            handler?.post { channel?.invokeMethod("onStart", null) }
        }

        override fun onDone(utteranceId: String?) {
            handler?.post { channel?.invokeMethod("onDone", null) }
        }

        override fun onError(utteranceId: String?) {
            handler?.post { channel?.invokeMethod("onError", "Unknown error") }
        }

        override fun onError(utteranceId: String?, errorCode: Int) {
            handler?.post { channel?.invokeMethod("onError", "Error code: $errorCode") }
        }
    }

    private fun speak(text: String, result: MethodChannel.Result) {
        val localTts = tts
        if (localTts == null || !ttsReady.get()) {
            result.success(false)
            return
        }

        val utteranceId = UUID.randomUUID().toString()
        val speakResult = localTts.speak(text, TextToSpeech.QUEUE_FLUSH, bundle, utteranceId)
        result.success(speakResult == TextToSpeech.SUCCESS)
    }

    private fun stop(result: MethodChannel.Result) {
        tts?.stop()
        result.success(true)
    }

    private fun setLanguage(language: String, result: MethodChannel.Result) {
        val localTts = tts
        if (localTts == null) {
            result.success(false)
            return
        }
        try {
            val locale = Locale.forLanguageTag(language)
            val available = localTts.isLanguageAvailable(locale)
            if (available >= TextToSpeech.LANG_AVAILABLE) {
                localTts.language = locale
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun setSpeechRate(rate: Float, result: MethodChannel.Result) {
        tts?.setSpeechRate(rate * 2.0f)
        result.success(true)
    }

    private fun setVolume(volume: Float, result: MethodChannel.Result) {
        bundle?.putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume)
        result.success(true)
    }

    private fun setPitch(pitch: Float, result: MethodChannel.Result) {
        tts?.setPitch(pitch)
        result.success(true)
    }

    private fun shutdownTts(result: MethodChannel.Result) {
        tts?.stop()
        tts?.shutdown()
        tts = null
        ttsReady.set(false)
        result.success(true)
    }
}
