package com.mostafasamy.mutemusic.mute_music_app

import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import java.io.File

class BadRangeException : Exception("The range is outside the video")

/** The file the cutter wrote, and the range of the source it really covers. */
data class CutResult(val path: String, val startMs: Long, val endMs: Long)

/**
 * Copies one time range of a video, video and audio, into a new MP4. Nothing
 * is re-encoded, so a cut takes about a second whatever the source length.
 *
 * A copied video has to start on a keyframe, so the cut starts at the last
 * keyframe at or before the asked start. The real start is returned.
 */
object VideoCutter {

    fun cut(sourcePath: String, startMs: Long, endMs: Long, outputDir: File): CutResult {
        if (startMs < 0 || startMs >= endMs) throw BadRangeException()
        val output = File(outputDir, "part_${System.currentTimeMillis()}.mp4")
        val video = MediaExtractor()
        val audio = MediaExtractor()
        var muxer: MediaMuxer? = null
        // Same rule as the other writers: release everything, and never leave
        // a half-written video behind.
        try {
            video.setDataSource(sourcePath)
            val videoTrack = SampleCopier.findTrack(video, "video/")
                ?: throw NoVideoTrackException()
            val videoFormat = video.getTrackFormat(videoTrack)
            video.selectTrack(videoTrack)

            val durationUs = durationUsOf(videoFormat, sourcePath)
            val askedStartUs = startMs * 1000
            if (durationUs != null && askedStartUs >= durationUs) throw BadRangeException()
            val endUs = durationUs?.let { minOf(endMs * 1000, it) } ?: (endMs * 1000)

            video.seekTo(askedStartUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            val realStartUs = video.sampleTime
            if (realStartUs < 0 || realStartUs >= endUs) throw BadRangeException()

            audio.setDataSource(sourcePath)
            val audioTrack = SampleCopier.findTrack(audio, "audio/")
            val audioFormat = audioTrack?.let { audio.getTrackFormat(it) }

            val writer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
                .also { muxer = it }
            // Must be set before start(), or portrait videos come out sideways.
            writer.setOrientationHint(VideoMuter.rotationOf(sourcePath))
            val outVideo = writer.addTrack(videoFormat)
            val outAudio = audioFormat?.let { writer.addTrack(it) }
            writer.start()

            SampleCopier.copy(video, writer, outVideo, videoFormat, realStartUs, endUs)
            if (audioTrack != null && audioFormat != null && outAudio != null) {
                audio.selectTrack(audioTrack)
                // The audio starts at the video's real start, so both stay in sync.
                audio.seekTo(realStartUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
                SampleCopier.copy(audio, writer, outAudio, audioFormat, realStartUs, endUs)
            }

            writer.stop()
            return CutResult(output.absolutePath, realStartUs / 1000, endUs / 1000)
        } catch (error: Exception) {
            output.delete()
            throw error
        } finally {
            releaseQuietly { muxer?.release() }
            releaseQuietly { audio.release() }
            releaseQuietly { video.release() }
        }
    }

    /** The length of a video in milliseconds, or null when it can't be read. */
    fun durationMs(path: String): Long? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(path)
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
        } catch (error: Exception) {
            null
        } finally {
            releaseQuietly { retriever.release() }
        }
    }

    private fun durationUsOf(format: MediaFormat, path: String): Long? =
        if (format.containsKey(MediaFormat.KEY_DURATION)) {
            format.getLong(MediaFormat.KEY_DURATION)
        } else {
            durationMs(path)?.let { it * 1000 }
        }

    /** Cleanup must never replace the error that got us here. */
    private inline fun releaseQuietly(release: () -> Unit) {
        try {
            release()
        } catch (ignored: Exception) {
        }
    }
}
