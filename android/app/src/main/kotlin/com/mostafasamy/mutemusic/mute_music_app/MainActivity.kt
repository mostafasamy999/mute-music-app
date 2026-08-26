package com.mostafasamy.mutemusic.mute_music_app

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "com.mostafasamy.mutemusic/video"
    }

    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "removeSound" -> removeSound(call, result)
                    "memoryReport" -> result.success(memoryReport())
                    "extractAudio" -> extractAudio(call, result)
                    "muxAudio" -> muxAudio(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun removeSound(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        if (sourcePath.isNullOrEmpty()) {
            result.error("bad_argument", "sourcePath is missing", null)
            return
        }
        // Muxing blocks, so keep it off the UI thread.
        worker.execute {
            try {
                val output = VideoMuter.removeSound(sourcePath, cacheDir)
                mainHandler.post { result.success(output) }
            } catch (error: NoVideoTrackException) {
                mainHandler.post { result.error("no_video_track", error.message, null) }
            } catch (error: Exception) {
                mainHandler.post { result.error("mute_failed", error.message, null) }
            }
        }
    }

    private fun extractAudio(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        if (sourcePath.isNullOrEmpty()) {
            result.error("bad_argument", "sourcePath is missing", null)
            return
        }
        worker.execute {
            try {
                val target = File(cacheDir, "audio_${System.currentTimeMillis()}.pcm")
                val info = AudioPipeline.extractToPcm(sourcePath, target)
                val payload = mapOf(
                    "path" to info.path,
                    "sampleRate" to info.sampleRate,
                    "channels" to info.channels,
                )
                mainHandler.post { result.success(payload) }
            } catch (error: NoAudioTrackException) {
                mainHandler.post { result.error("no_audio_track", error.message, null) }
            } catch (error: Exception) {
                mainHandler.post { result.error("extract_failed", error.message, null) }
            }
        }
    }

    private fun muxAudio(call: MethodCall, result: MethodChannel.Result) {
        val videoPath = call.argument<String>("videoPath")
        val pcmPath = call.argument<String>("pcmPath")
        val sampleRate = call.argument<Int>("sampleRate") ?: 44100
        val channels = call.argument<Int>("channels") ?: 2
        if (videoPath.isNullOrEmpty() || pcmPath.isNullOrEmpty()) {
            result.error("bad_argument", "videoPath or pcmPath is missing", null)
            return
        }
        worker.execute {
            try {
                val path = AudioPipeline.muxWithNewAudio(
                    videoPath, pcmPath, sampleRate, channels, cacheDir
                )
                mainHandler.post { result.success(path) }
            } catch (error: Exception) {
                mainHandler.post { result.error("mux_failed", error.message, null) }
            }
        }
    }

    /**
     * totalPss is the number the system uses when it decides which app to kill,
     * so it is the one that matters for "will this survive on a real phone".
     */
    private fun memoryReport(): Map<String, Any> {
        val info = Debug.MemoryInfo()
        Debug.getMemoryInfo(info)
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val device = ActivityManager.MemoryInfo()
        manager.getMemoryInfo(device)
        return mapOf(
            "footprintMb" to info.totalPss / 1024.0,
            "nativeHeapMb" to Debug.getNativeHeapAllocatedSize() / 1048576.0,
            "deviceTotalMb" to device.totalMem / 1048576.0,
            "deviceAvailableMb" to device.availMem / 1048576.0,
            "heapLimitMb" to manager.largeMemoryClass.toDouble(),
            "lowMemory" to device.lowMemory,
        )
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }
}
