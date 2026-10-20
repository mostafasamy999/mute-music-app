package com.mostafasamy.mutemusic.mute_music_app

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.nio.ByteBuffer

/**
 * Copies encoded samples from an extractor into a muxer as they are, so
 * nothing is decoded or re-encoded. Shared by the muter and the cutter.
 */
object SampleCopier {

    private const val DEFAULT_BUFFER_SIZE = 2 * 1024 * 1024

    /**
     * Copies the selected track from the extractor's current position.
     * Samples before [fromUs] are skipped, copying stops at the first sample
     * after [toUs], and every written timestamp is moved back by [fromUs] so
     * the copy starts at zero.
     */
    fun copy(
        extractor: MediaExtractor,
        muxer: MediaMuxer,
        track: Int,
        format: MediaFormat,
        fromUs: Long = 0L,
        toUs: Long = Long.MAX_VALUE,
    ) {
        val buffer = ByteBuffer.allocate(bufferSizeOf(format))
        val info = MediaCodec.BufferInfo()
        while (true) {
            val size = extractor.readSampleData(buffer, 0)
            if (size < 0) break
            val timeUs = extractor.sampleTime
            if (timeUs > toUs) break
            if (timeUs >= fromUs) {
                info.offset = 0
                info.size = size
                info.presentationTimeUs = timeUs - fromUs
                info.flags = sampleFlags(extractor.sampleFlags)
                muxer.writeSampleData(track, buffer, info)
            }
            extractor.advance()
        }
    }

    fun findTrack(extractor: MediaExtractor, prefix: String): Int? {
        for (index in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith(prefix) == true) return index
        }
        return null
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
}
