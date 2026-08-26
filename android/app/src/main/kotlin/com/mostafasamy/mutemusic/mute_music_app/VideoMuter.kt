package com.mostafasamy.mutemusic.mute_music_app

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import java.io.File
import java.nio.ByteBuffer

class NoVideoTrackException : Exception("The file has no video track")

/**
 * Copies the video track into a new MP4 and leaves the audio track behind.
 * Nothing is decoded or re-encoded, so the result keeps the original quality
 * and the work finishes in about a second even for long clips.
 */
object VideoMuter {

    private const val DEFAULT_BUFFER_SIZE = 2 * 1024 * 1024

    fun removeSound(sourcePath: String, outputDir: File): String {
        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        try {
            extractor.setDataSource(sourcePath)
            val trackIndex = findVideoTrack(extractor) ?: throw NoVideoTrackException()
            val format = extractor.getTrackFormat(trackIndex)
            extractor.selectTrack(trackIndex)

            val output = File(outputDir, "muted_${System.currentTimeMillis()}.mp4")
            muxer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            // Must be set before start(), or portrait videos come out sideways.
            muxer.setOrientationHint(readRotation(sourcePath))
            val outputTrack = muxer.addTrack(format)
            muxer.start()

            copySamples(extractor, muxer, outputTrack, bufferSizeOf(format))

            muxer.stop()
            return output.absolutePath
        } finally {
            extractor.release()
            muxer?.release()
        }
    }

    private fun findVideoTrack(extractor: MediaExtractor): Int? {
        for (index in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("video/") == true) return index
        }
        return null
    }

    private fun copySamples(
        extractor: MediaExtractor,
        muxer: MediaMuxer,
        track: Int,
        bufferSize: Int,
    ) {
        val buffer = ByteBuffer.allocate(bufferSize)
        val info = MediaCodec.BufferInfo()
        while (true) {
            val size = extractor.readSampleData(buffer, 0)
            if (size < 0) break
            info.offset = 0
            info.size = size
            info.presentationTimeUs = extractor.sampleTime
            info.flags = sampleFlags(extractor.sampleFlags)
            muxer.writeSampleData(track, buffer, info)
            extractor.advance()
        }
    }

    private fun sampleFlags(extractorFlags: Int): Int =
        if (extractorFlags and MediaExtractor.SAMPLE_FLAG_SYNC != 0) {
            MediaCodec.BUFFER_FLAG_KEY_FRAME
        } else {
            0
        }

    private fun bufferSizeOf(format: MediaFormat): Int =
        if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
            format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE)
                .coerceAtLeast(DEFAULT_BUFFER_SIZE)
        } else {
            DEFAULT_BUFFER_SIZE
        }

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
