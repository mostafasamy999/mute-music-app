package com.mostafasamy.mutemusic.mute_music_app

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
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

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }
}
