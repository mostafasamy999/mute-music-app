package com.mostafasamy.mutemusic.mute_music_app

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

class NoAudioTrackException : Exception("The file has no audio track")

data class PcmInfo(val path: String, val sampleRate: Int, val channels: Int)

/**
 * Pulls audio out of a video as raw float samples, and puts new audio back in
 * while copying the video track untouched.
 */
object AudioPipeline {

    private const val TIMEOUT_US = 10_000L

    fun extractToPcm(sourcePath: String, output: File): PcmInfo {
        val extractor = MediaExtractor()
        extractor.setDataSource(sourcePath)
        val track = findTrack(extractor, "audio/") ?: throw NoAudioTrackException()
        val format = extractor.getTrackFormat(track)
        extractor.selectTrack(track)

        val sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        val channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        // Deliberately not asking for float output. Decoders vary in whether
        // they honour it and whether they report it back, and guessing wrong
        // means reading the bytes as the wrong type, which sounds like noise.

        val codec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
        codec.configure(format, null, null, 0)
        codec.start()
        FileOutputStream(output).use { stream ->
            decodeInto(extractor, codec, stream)
        }
        codec.stop(); codec.release(); extractor.release()
        return PcmInfo(output.absolutePath, sampleRate, channels)
    }

    private fun decodeInto(
        extractor: MediaExtractor,
        codec: MediaCodec,
        stream: FileOutputStream,
    ) {
        val info = MediaCodec.BufferInfo()
        var inputDone = false
        var outputDone = false
        var floatOutput = false

        while (!outputDone) {
            if (!inputDone) inputDone = feed(extractor, codec)
            when (val index = codec.dequeueOutputBuffer(info, TIMEOUT_US)) {
                MediaCodec.INFO_OUTPUT_FORMAT_CHANGED ->
                    floatOutput = codec.outputFormat
                        .getIntegerOrDefault(MediaFormat.KEY_PCM_ENCODING, AudioFormatShort) ==
                        AudioFormatFloat
                MediaCodec.INFO_TRY_AGAIN_LATER -> Unit
                else -> if (index >= 0) {
                    val buffer = codec.getOutputBuffer(index)!!
                    writeSamples(buffer, info, stream, floatOutput)
                    codec.releaseOutputBuffer(index, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
                }
            }
        }
    }

    private fun feed(extractor: MediaExtractor, codec: MediaCodec): Boolean {
        val index = codec.dequeueInputBuffer(TIMEOUT_US)
        if (index < 0) return false
        val buffer = codec.getInputBuffer(index)!!
        val size = extractor.readSampleData(buffer, 0)
        return if (size < 0) {
            codec.queueInputBuffer(index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            true
        } else {
            codec.queueInputBuffer(index, 0, size, extractor.sampleTime, 0)
            extractor.advance()
            false
        }
    }

    /** Always writes little-endian float32, whatever the decoder handed us. */
    private fun writeSamples(
        buffer: ByteBuffer,
        info: MediaCodec.BufferInfo,
        stream: FileOutputStream,
        floatOutput: Boolean,
    ) {
        if (info.size <= 0) return
        buffer.position(info.offset)
        buffer.limit(info.offset + info.size)
        val src = buffer.slice().order(ByteOrder.nativeOrder())
        val count = if (floatOutput) info.size / 4 else info.size / 2
        val out = ByteBuffer.allocate(count * 4).order(ByteOrder.LITTLE_ENDIAN)
        if (floatOutput) {
            val f = src.asFloatBuffer()
            while (f.hasRemaining()) out.putFloat(f.get())
        } else {
            val s = src.asShortBuffer()
            while (s.hasRemaining()) out.putFloat(s.get() / 32768f)
        }
        stream.write(out.array(), 0, out.position())
    }

    private fun findTrack(extractor: MediaExtractor, prefix: String): Int? {
        for (i in 0 until extractor.trackCount) {
            val mime = extractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith(prefix) == true) return i
        }
        return null
    }

    private fun MediaFormat.getIntegerOrDefault(key: String, fallback: Int): Int =
        if (containsKey(key)) getInteger(key) else fallback

    private const val AudioFormatFloat = 4      // AudioFormat.ENCODING_PCM_FLOAT
    private const val AudioFormatShort = 2      // AudioFormat.ENCODING_PCM_16BIT

    fun muxWithNewAudio(
        videoPath: String,
        pcmPath: String,
        sampleRate: Int,
        channels: Int,
        outputDir: File,
    ): String {
        val output = File(outputDir, "nomusic_${System.currentTimeMillis()}.mp4")
        val muxer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val extractor = MediaExtractor().apply { setDataSource(videoPath) }
        val videoTrack = findTrack(extractor, "video/") ?: throw NoVideoTrackException()
        val videoFormat = extractor.getTrackFormat(videoTrack)
        extractor.selectTrack(videoTrack)

        val encoder = createAacEncoder(sampleRate, channels)
        val outVideo = muxer.addTrack(videoFormat)
        var outAudio = -1

        muxer.setOrientationHint(VideoMuter.rotationOf(videoPath))
        encoder.start()
        outAudio = encodeAndMux(encoder, File(pcmPath), muxer, outVideo, extractor, videoFormat)
        encoder.stop(); encoder.release()
        muxer.stop(); muxer.release(); extractor.release()
        return output.absolutePath
    }

    private fun createAacEncoder(sampleRate: Int, channels: Int): MediaCodec {
        val format = MediaFormat.createAudioFormat(
            MediaFormat.MIMETYPE_AUDIO_AAC, sampleRate, channels
        ).apply {
            setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
            setInteger(MediaFormat.KEY_BIT_RATE, 192_000)
            setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 64 * 1024)
        }
        val encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
        encoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
        return encoder
    }

    private fun encodeAndMux(
        encoder: MediaCodec,
        pcm: File,
        muxer: MediaMuxer,
        videoTrackOut: Int,
        extractor: MediaExtractor,
        videoFormat: MediaFormat,
    ): Int {
        // The encoder wants 16-bit samples. The pipeline carries 32-bit floats,
        // so convert here — handing floats straight over produces pure noise.
        val channels = 2
        val bytesPerFrame = channels * 2
        val pcmBytes = floatFileToPcm16(pcm)
        val info = MediaCodec.BufferInfo()
        var offset = 0
        var audioTrackOut = -1
        var started = false
        var presentationUs = 0L
        var inputDone = false

        while (true) {
            if (!inputDone) {
                val index = encoder.dequeueInputBuffer(TIMEOUT_US)
                if (index >= 0) {
                    val buffer = encoder.getInputBuffer(index)!!
                    buffer.clear()
                    val chunk = minOf(buffer.capacity(), pcmBytes.size - offset)
                    if (chunk <= 0) {
                        encoder.queueInputBuffer(index, 0, 0, presentationUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        inputDone = true
                    } else {
                        buffer.put(pcmBytes, offset, chunk)
                        encoder.queueInputBuffer(index, 0, chunk, presentationUs, 0)
                        offset += chunk
                        presentationUs += chunk.toLong() * 1_000_000L / (bytesPerFrame * 44100L)
                    }
                }
            }
            val index = encoder.dequeueOutputBuffer(info, TIMEOUT_US)
            if (index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                audioTrackOut = muxer.addTrack(encoder.outputFormat)
                muxer.start()
                started = true
                copyVideo(extractor, muxer, videoTrackOut, videoFormat)
            } else if (index >= 0) {
                if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0 && info.size > 0 && started) {
                    muxer.writeSampleData(audioTrackOut, encoder.getOutputBuffer(index)!!, info)
                }
                encoder.releaseOutputBuffer(index, false)
                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
            }
        }
        return audioTrackOut
    }

    /** Little-endian float32 on disk to little-endian int16 the encoder accepts. */
    private fun floatFileToPcm16(pcm: File): ByteArray {
        val source = ByteBuffer.wrap(pcm.readBytes())
            .order(ByteOrder.LITTLE_ENDIAN)
            .asFloatBuffer()
        val out = ByteBuffer.allocate(source.remaining() * 2)
            .order(ByteOrder.LITTLE_ENDIAN)
        while (source.hasRemaining()) {
            val clamped = source.get().coerceIn(-1f, 1f)
            out.putShort((clamped * 32767f).toInt().toShort())
        }
        return out.array()
    }

    /** Copies the original video samples with no re-encoding. */
    private fun copyVideo(
        extractor: MediaExtractor,
        muxer: MediaMuxer,
        track: Int,
        format: MediaFormat,
    ) {
        val size = if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
            format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE).coerceAtLeast(1 shl 20)
        } else {
            1 shl 21
        }
        val buffer = ByteBuffer.allocate(size)
        val info = MediaCodec.BufferInfo()
        while (true) {
            val read = extractor.readSampleData(buffer, 0)
            if (read < 0) break
            info.offset = 0
            info.size = read
            info.presentationTimeUs = extractor.sampleTime
            info.flags = if (extractor.sampleFlags and MediaExtractor.SAMPLE_FLAG_SYNC != 0) {
                MediaCodec.BUFFER_FLAG_KEY_FRAME
            } else {
                0
            }
            muxer.writeSampleData(track, buffer, info)
            extractor.advance()
        }
    }
}
