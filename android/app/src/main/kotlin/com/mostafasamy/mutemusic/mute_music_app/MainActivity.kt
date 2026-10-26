package com.mostafasamy.mutemusic.mute_music_app

import android.Manifest
import android.app.ActivityManager
import android.content.Context
import android.content.pm.PackageManager
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
        const val STORAGE_REQUEST = 4101
    }

    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    /** A Save to Music waiting for the storage permission (Android 9 and older). */
    private var pendingSave: (() -> Unit)? = null
    private var pendingSaveResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "removeSound" -> removeSound(call, result)
                    "memoryReport" -> result.success(memoryReport())
                    "extractAudio" -> extractAudio(call, result)
                    "muxAudio" -> muxAudio(call, result)
                    "cutVideo" -> cutVideo(call, result)
                    "cutAudio" -> cutAudio(call, result)
                    "exportAudio" -> exportAudio(call, result)
                    "saveAudio" -> saveAudio(call, result)
                    "recognizeText" -> recognizeText(call, result)
                    "encodeVoices" -> encodeVoices(call, result)
                    "videoDuration" -> videoDuration(call, result)
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
            } catch (error: NoVideoTrackException) {
                mainHandler.post { result.error("no_video_track", error.message, null) }
            } catch (error: Exception) {
                mainHandler.post { result.error("mux_failed", error.message, null) }
            }
        }
    }

    private fun cutVideo(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        val startMs = call.argument<Number>("startMs")?.toLong()
        val endMs = call.argument<Number>("endMs")?.toLong()
        if (sourcePath.isNullOrEmpty() || startMs == null || endMs == null) {
            result.error("bad_argument", "sourcePath, startMs or endMs is missing", null)
            return
        }
        worker.execute {
            try {
                val cut = VideoCutter.cut(sourcePath, startMs, endMs, cacheDir)
                val payload = mapOf(
                    "path" to cut.path,
                    "startMs" to cut.startMs,
                    "endMs" to cut.endMs,
                )
                mainHandler.post { result.success(payload) }
            } catch (error: NoVideoTrackException) {
                mainHandler.post { result.error("no_video_track", error.message, null) }
            } catch (error: BadRangeException) {
                mainHandler.post { result.error("bad_range", error.message, null) }
            } catch (error: Exception) {
                mainHandler.post { result.error("cut_failed", error.message, null) }
            }
        }
    }

    /** Spec 006 F3: cuts a sound file into a new .m4a (AudioExporter). */
    private fun cutAudio(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        val startMs = call.argument<Number>("startMs")?.toLong()
        val endMs = call.argument<Number>("endMs")?.toLong()
        if (sourcePath.isNullOrEmpty() || startMs == null || endMs == null) {
            result.error("bad_argument", "sourcePath, startMs or endMs is missing", null)
            return
        }
        worker.execute {
            try {
                val cut = AudioExporter.export(sourcePath, cacheDir, "part", startMs, endMs)
                val payload = mapOf(
                    "path" to cut.path,
                    "startMs" to cut.startMs,
                    "endMs" to cut.endMs,
                )
                mainHandler.post { result.success(payload) }
            } catch (error: NoAudioTrackException) {
                mainHandler.post { result.error("no_audio_track", error.message, null) }
            } catch (error: BadRangeException) {
                mainHandler.post { result.error("bad_range", error.message, null) }
            } catch (error: Exception) {
                mainHandler.post { result.error("cut_failed", error.message, null) }
            }
        }
    }

    /** Spec 006 F7: Convert to audio. The whole audio track into an .m4a. */
    private fun exportAudio(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        if (sourcePath.isNullOrEmpty()) {
            result.error("bad_argument", "sourcePath is missing", null)
            return
        }
        worker.execute {
            try {
                val export = AudioExporter.export(sourcePath, cacheDir, "export")
                mainHandler.post { result.success(export.path) }
            } catch (error: NoAudioTrackException) {
                mainHandler.post { result.error("no_audio_track", error.message, null) }
            } catch (error: Exception) {
                mainHandler.post { result.error("convert_failed", error.message, null) }
            }
        }
    }

    /** Spec 006 F10: Save to Music, into the shared Music/Mute Video folder. */
    private fun saveAudio(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        val name = call.argument<String>("name")
        if (sourcePath.isNullOrEmpty() || name.isNullOrEmpty()) {
            result.error("bad_argument", "sourcePath or name is missing", null)
            return
        }
        val save = {
            worker.execute {
                try {
                    AudioSaver.save(applicationContext, sourcePath, name)
                    mainHandler.post { result.success(null) }
                } catch (error: Exception) {
                    mainHandler.post { result.error("save_failed", error.message, null) }
                }
            }
        }
        val permission = Manifest.permission.WRITE_EXTERNAL_STORAGE
        if (!AudioSaver.needsPermission() ||
            checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
        ) {
            save()
            return
        }
        // Only one request at a time; a second tap while asking is refused.
        if (pendingSave != null) {
            result.error("save_failed", "already asking for the permission", null)
            return
        }
        pendingSave = save
        pendingSaveResult = result
        requestPermissions(arrayOf(permission), STORAGE_REQUEST)
    }

    /** Spec 006 F8: offline text from an image (Tesseract, English + Arabic). */
    private fun recognizeText(call: MethodCall, result: MethodChannel.Result) {
        val imagePath = call.argument<String>("imagePath")
        if (imagePath.isNullOrEmpty()) {
            result.error("bad_argument", "imagePath is missing", null)
            return
        }
        worker.execute {
            try {
                val text = TextRecognizer.recognize(applicationContext, imagePath)
                mainHandler.post { result.success(text) }
            } catch (error: UnreadableImageException) {
                mainHandler.post { result.error("unreadable_image", error.message, null) }
            } catch (error: Exception) {
                mainHandler.post { result.error("ocr_failed", error.message, null) }
            }
        }
    }

    /** Spec 006 F6: the separated voices of a sound file into an .m4a. */
    private fun encodeVoices(call: MethodCall, result: MethodChannel.Result) {
        val pcmPath = call.argument<String>("pcmPath")
        val sampleRate = call.argument<Number>("sampleRate")?.toInt()
        val channels = call.argument<Number>("channels")?.toInt()
        if (pcmPath.isNullOrEmpty() || sampleRate == null || channels == null) {
            result.error("bad_argument", "pcmPath, sampleRate or channels is missing", null)
            return
        }
        worker.execute {
            try {
                val output = PcmEncoder.encode(pcmPath, sampleRate, channels, cacheDir)
                mainHandler.post { result.success(output) }
            } catch (error: Exception) {
                mainHandler.post { result.error("encode_failed", error.message, null) }
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != STORAGE_REQUEST) return
        val save = pendingSave
        val result = pendingSaveResult
        pendingSave = null
        pendingSaveResult = null
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            save?.invoke()
        } else {
            result?.error("permission_denied", "storage permission denied", null)
        }
    }

    private fun videoDuration(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        if (sourcePath.isNullOrEmpty()) {
            result.error("bad_argument", "sourcePath is missing", null)
            return
        }
        worker.execute {
            val durationMs = VideoCutter.durationMs(sourcePath)
            mainHandler.post { result.success(durationMs) }
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
            // Below this free amount Android starts killing background apps.
            "lowMemoryThresholdMb" to device.threshold / 1048576.0,
            "heapLimitMb" to manager.largeMemoryClass.toDouble(),
            "lowMemory" to device.lowMemory,
        )
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }
}
