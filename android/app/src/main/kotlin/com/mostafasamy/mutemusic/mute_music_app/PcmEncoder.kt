package com.mostafasamy.mutemusic.mute_music_app

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Spec 006 F6: Remove music only on a sound file. Encodes the separated
 * voices (interleaved float32 PCM, as the separation worker writes it) into
 * a new .m4a, where AudioPipeline would mux them into a video instead.
 *
 * New code next to AudioPipeline; it does not change it. The PCM is read in
 * chunks, so a long file is never held in memory twice.
 */
object PcmEncoder {

    private const val AAC = MediaFormat.MIMETYPE_AUDIO_AAC
    private const val BIT_RATE = 192_000
    private const val TIMEOUT_US = 10_000L
    private const val CHUNK_FLOATS = 16 * 1024

    fun encode(pcmPath: String, sampleRate: Int, channels: Int, outputDir: File): String {
        val pcm = File(pcmPath)
        if (!pcm.exists()) throw IllegalArgumentException("No such file: $pcmPath")
        val output = File(outputDir, "nomusic_${System.currentTimeMillis()}.m4a")
        val format = MediaFormat.createAudioFormat(AAC, sampleRate, channels).apply {
            setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
            setInteger(MediaFormat.KEY_BIT_RATE, BIT_RATE)
        }
        val encoder = MediaCodec.createEncoderByType(AAC)
        val muxer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        try {
            encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            encoder.start()
            FileInputStream(pcm).use { input ->
                run(input, encoder, muxer, sampleRate.toLong() * channels * 2)
            }
            muxer.stop()
            return output.absolutePath
        } catch (error: Exception) {
            output.delete()
            throw error
        } finally {
            releaseQuietly { encoder.stop() }
            releaseQuietly { encoder.release() }
            releaseQuietly { muxer.release() }
        }
    }

    private fun run(input: FileInputStream, encoder: MediaCodec, muxer: MediaMuxer, bytesPerSecond: Long) {
        val floats = ByteArray(CHUNK_FLOATS * 4)
        // 16-bit samples waiting for an encoder input buffer.
        var pcm16: ByteBuffer = ByteBuffer.allocate(0)
        var inputDone = false
        var sourceDone = false
        var pcmBytes = 0L
        var track = -1
        val info = MediaCodec.BufferInfo()

        while (true) {
            if (!inputDone) {
                if (!pcm16.hasRemaining() && !sourceDone) {
                    val read = readFully(input, floats)
                    if (read <= 0) {
                        sourceDone = true
                    } else {
                        pcm16 = toPcm16(floats, read)
                    }
                }
                val index = encoder.dequeueInputBuffer(TIMEOUT_US)
                if (index >= 0) {
                    val buffer = encoder.getInputBuffer(index)!!
                    buffer.clear()
                    if (!pcm16.hasRemaining() && sourceDone) {
                        encoder.queueInputBuffer(index, 0, 0, timeUs(pcmBytes, bytesPerSecond),
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        inputDone = true
                    } else {
                        val count = minOf(buffer.remaining(), pcm16.remaining())
                        val slice = pcm16.duplicate().apply { limit(position() + count) }
                        buffer.put(slice)
                        pcm16.position(pcm16.position() + count)
                        encoder.queueInputBuffer(index, 0, count, timeUs(pcmBytes, bytesPerSecond), 0)
                        pcmBytes += count
                    }
                }
            }

            val index = encoder.dequeueOutputBuffer(info, TIMEOUT_US)
            if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                track = muxer.addTrack(encoder.outputFormat)
                muxer.start()
            } else if (index >= 0) {
                val buffer = encoder.getOutputBuffer(index)!!
                val isConfig = info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0
                if (!isConfig && info.size > 0 && track >= 0) {
                    muxer.writeSampleData(track, buffer, info)
                }
                encoder.releaseOutputBuffer(index, false)
                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
            }
        }
        if (track < 0) throw IllegalStateException("The encoder produced no audio")
    }

    private fun readFully(input: FileInputStream, into: ByteArray): Int {
        var total = 0
        while (total < into.size) {
            val read = input.read(into, total, into.size - total)
            if (read < 0) break
            total += read
        }
        // Whole floats only.
        return total - total % 4
    }

    /** Little-endian float32 in [-1, 1] → little-endian 16-bit PCM. */
    private fun toPcm16(floats: ByteArray, length: Int): ByteBuffer {
        val source = ByteBuffer.wrap(floats, 0, length).order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
        val out = ByteBuffer.allocate(source.remaining() * 2).order(ByteOrder.LITTLE_ENDIAN)
        while (source.hasRemaining()) {
            val sample = source.get().coerceIn(-1f, 1f)
            out.putShort((sample * Short.MAX_VALUE).toInt().toShort())
        }
        out.flip()
        return out
    }

    private fun timeUs(bytes: Long, bytesPerSecond: Long): Long = bytes * 1_000_000 / bytesPerSecond

    /** Cleanup must never replace the error that got us here. */
    private inline fun releaseQuietly(release: () -> Unit) {
        try {
            release()
        } catch (ignored: Exception) {
        }
    }
}
