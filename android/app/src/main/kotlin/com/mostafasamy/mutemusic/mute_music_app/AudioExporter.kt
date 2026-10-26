package com.mostafasamy.mutemusic.mute_music_app

import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File

/**
 * Writes the audio track of a sound or video file, or one time range of it,
 * into a new .m4a (spec 006: cut a sound, Convert to audio).
 *
 * AAC, which almost every phone video and .m4a file holds, is copied as it
 * is: nothing is re-encoded, so it is fast and loses nothing. Any other codec
 * (MP3, Opus, AMR...) is decoded and re-encoded to AAC, because the MP4
 * writer only takes AAC audio.
 *
 * New code next to AudioPipeline and VideoMuter; it does not change them
 * (NoAudioTrackException comes from AudioPipeline).
 */
object AudioExporter {

    private const val AAC = MediaFormat.MIMETYPE_AUDIO_AAC
    private const val BIT_RATE = 192_000
    private const val TIMEOUT_US = 10_000L

    /**
     * Writes `<prefix>_<time>.m4a` in [outputDir]. With [startMs] and [endMs]
     * only that range is written; the real range is returned (a copy starts
     * on the frame at or before [startMs]).
     */
    fun export(
        sourcePath: String,
        outputDir: File,
        prefix: String,
        startMs: Long? = null,
        endMs: Long? = null,
    ): CutResult {
        if (startMs != null && endMs != null && (startMs < 0 || startMs >= endMs)) {
            throw BadRangeException()
        }
        val output = File(outputDir, "${prefix}_${System.currentTimeMillis()}.m4a")
        val extractor = MediaExtractor()
        // Same rule as the other writers: release everything, and never leave
        // a half-written file behind.
        try {
            extractor.setDataSource(sourcePath)
            val track = SampleCopier.findTrack(extractor, "audio/")
                ?: throw NoAudioTrackException()
            val format = extractor.getTrackFormat(track)
            extractor.selectTrack(track)

            val durationUs = if (format.containsKey(MediaFormat.KEY_DURATION)) {
                format.getLong(MediaFormat.KEY_DURATION)
            } else {
                VideoCutter.durationMs(sourcePath)?.let { it * 1000 }
            }
            val askedStartUs = (startMs ?: 0L) * 1000
            if (durationUs != null && askedStartUs >= durationUs) throw BadRangeException()
            val endUs = when {
                endMs == null -> durationUs ?: Long.MAX_VALUE
                durationUs == null -> endMs * 1000
                else -> minOf(endMs * 1000, durationUs)
            }

            extractor.seekTo(askedStartUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
            val realStartUs = extractor.sampleTime
            if (realStartUs < 0 || realStartUs >= endUs) throw BadRangeException()

            if (format.getString(MediaFormat.KEY_MIME) == AAC) {
                copy(extractor, format, output, realStartUs, endUs)
            } else {
                transcode(extractor, format, output, endUs)
            }
            val writtenEndUs = if (endUs == Long.MAX_VALUE) realStartUs else endUs
            return CutResult(output.absolutePath, realStartUs / 1000, writtenEndUs / 1000)
        } catch (error: Exception) {
            output.delete()
            throw error
        } finally {
            releaseQuietly { extractor.release() }
        }
    }

    private fun copy(
        extractor: MediaExtractor,
        format: MediaFormat,
        output: File,
        fromUs: Long,
        toUs: Long,
    ) {
        val muxer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        try {
            val track = muxer.addTrack(format)
            muxer.start()
            SampleCopier.copy(extractor, muxer, track, format, fromUs, toUs)
            muxer.stop()
        } finally {
            releaseQuietly { muxer.release() }
        }
    }

    /**
     * Decodes to 16-bit PCM and encodes AAC. Timestamps come from the PCM
     * byte count, so the output always starts at zero and has no gaps.
     */
    private fun transcode(
        extractor: MediaExtractor,
        format: MediaFormat,
        output: File,
        toUs: Long,
    ) {
        val decoder = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
        var encoder: MediaCodec? = null
        val muxer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        try {
            decoder.configure(format, null, null, 0)
            decoder.start()

            val info = MediaCodec.BufferInfo()
            var muxTrack = -1
            var inputDone = false
            var decodedDone = false
            var encodedDone = false
            var bytesPerSecond = 0L
            var pcmBytes = 0L
            // A decoded buffer still being handed to the encoder.
            var pendingIndex = -1
            var pending: java.nio.ByteBuffer? = null
            var pendingLast = false

            while (!encodedDone) {
                if (!inputDone) {
                    val index = decoder.dequeueInputBuffer(TIMEOUT_US)
                    if (index >= 0) {
                        val buffer = decoder.getInputBuffer(index)!!
                        val size = extractor.readSampleData(buffer, 0)
                        val timeUs = extractor.sampleTime
                        if (size < 0 || timeUs > toUs) {
                            decoder.queueInputBuffer(index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            decoder.queueInputBuffer(index, 0, size, timeUs, 0)
                            extractor.advance()
                        }
                    }
                }

                if (!decodedDone && pendingIndex < 0) {
                    val index = decoder.dequeueOutputBuffer(info, TIMEOUT_US)
                    if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED && encoder == null) {
                        encoder = startEncoder(decoder.outputFormat)
                        bytesPerSecond = bytesPerSecondOf(decoder.outputFormat)
                    } else if (index >= 0) {
                        if (encoder == null) {
                            encoder = startEncoder(decoder.outputFormat)
                            bytesPerSecond = bytesPerSecondOf(decoder.outputFormat)
                        }
                        pendingIndex = index
                        pending = decoder.getOutputBuffer(index)!!.apply {
                            position(info.offset)
                            limit(info.offset + info.size)
                        }
                        pendingLast = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                    }
                }

                val writer = encoder
                val data = pending
                if (pendingIndex >= 0 && writer != null && data != null) {
                    val index = writer.dequeueInputBuffer(TIMEOUT_US)
                    if (index >= 0) {
                        val buffer = writer.getInputBuffer(index)!!
                        buffer.clear()
                        val count = minOf(buffer.remaining(), data.remaining())
                        val slice = data.duplicate().apply { limit(position() + count) }
                        buffer.put(slice)
                        data.position(data.position() + count)
                        val timeUs = pcmBytes * 1_000_000 / bytesPerSecond
                        pcmBytes += count
                        val last = pendingLast && !data.hasRemaining()
                        writer.queueInputBuffer(
                            index, 0, count, timeUs,
                            if (last) MediaCodec.BUFFER_FLAG_END_OF_STREAM else 0,
                        )
                        if (!data.hasRemaining()) {
                            decoder.releaseOutputBuffer(pendingIndex, false)
                            pendingIndex = -1
                            pending = null
                            if (pendingLast) decodedDone = true
                        }
                    }
                }

                if (writer != null) {
                    val index = writer.dequeueOutputBuffer(info, TIMEOUT_US)
                    if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        muxTrack = muxer.addTrack(writer.outputFormat)
                        muxer.start()
                    } else if (index >= 0) {
                        val buffer = writer.getOutputBuffer(index)!!
                        val isConfig = info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0
                        if (!isConfig && info.size > 0 && muxTrack >= 0) {
                            muxer.writeSampleData(muxTrack, buffer, info)
                        }
                        writer.releaseOutputBuffer(index, false)
                        if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                            encodedDone = true
                        }
                    }
                } else if (decodedDone || (inputDone && pendingLast)) {
                    // The decoder ended without ever producing audio.
                    throw NoAudioTrackException()
                }
            }
            if (muxTrack < 0) throw NoAudioTrackException()
            muxer.stop()
        } finally {
            releaseQuietly { decoder.stop() }
            releaseQuietly { decoder.release() }
            releaseQuietly { encoder?.stop() }
            releaseQuietly { encoder?.release() }
            releaseQuietly { muxer.release() }
        }
    }

    private fun startEncoder(pcm: MediaFormat): MediaCodec {
        if (pcm.containsKey(MediaFormat.KEY_PCM_ENCODING) &&
            pcm.getInteger(MediaFormat.KEY_PCM_ENCODING) != AudioFormat.ENCODING_PCM_16BIT
        ) {
            throw IllegalStateException("Only 16-bit PCM can be re-encoded")
        }
        val rate = pcm.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        val channels = pcm.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        val format = MediaFormat.createAudioFormat(AAC, rate, channels).apply {
            setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
            setInteger(MediaFormat.KEY_BIT_RATE, BIT_RATE)
        }
        return MediaCodec.createEncoderByType(AAC).apply {
            configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            start()
        }
    }

    private fun bytesPerSecondOf(pcm: MediaFormat): Long =
        pcm.getInteger(MediaFormat.KEY_SAMPLE_RATE).toLong() *
            pcm.getInteger(MediaFormat.KEY_CHANNEL_COUNT) * 2

    /** Cleanup must never replace the error that got us here. */
    private inline fun releaseQuietly(release: () -> Unit) {
        try {
            release()
        } catch (ignored: Exception) {
        }
    }
}
