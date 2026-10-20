package com.mostafasamy.mutemusic.mute_music_app

import android.media.MediaExtractor
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import java.io.File

class NoVideoTrackException : Exception("The file has no video track")

/**
 * Copies the video track into a new MP4 and leaves the audio track behind.
 * Nothing is decoded or re-encoded, so the result keeps the original quality
 * and the work finishes in about a second even for long clips.
 */
object VideoMuter {

    fun removeSound(sourcePath: String, outputDir: File): String {
        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        try {
            extractor.setDataSource(sourcePath)
            val trackIndex = SampleCopier.findTrack(extractor, "video/")
                ?: throw NoVideoTrackException()
            val format = extractor.getTrackFormat(trackIndex)
            extractor.selectTrack(trackIndex)

            val output = File(outputDir, "muted_${System.currentTimeMillis()}.mp4")
            muxer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            // Must be set before start(), or portrait videos come out sideways.
            muxer.setOrientationHint(rotationOf(sourcePath))
            val outputTrack = muxer.addTrack(format)
            muxer.start()

            SampleCopier.copy(extractor, muxer, outputTrack, format)

            muxer.stop()
            return output.absolutePath
        } finally {
            extractor.release()
            muxer?.release()
        }
    }

    /** Shared with AudioPipeline and VideoCutter so every writer keeps portrait clips upright. */
    fun rotationOf(path: String): Int = readRotation(path)

    private fun readRotation(path: String): Int {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(path)
            retriever
                .extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                ?.toIntOrNull() ?: 0
        } catch (error: Exception) {
            0
        } finally {
            retriever.release()
        }
    }
}
