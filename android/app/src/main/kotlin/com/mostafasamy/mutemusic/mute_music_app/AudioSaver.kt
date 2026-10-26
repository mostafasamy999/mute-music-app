package com.mostafasamy.mutemusic.mute_music_app

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File

/**
 * Spec 006 F10: copies an audio file into the shared `Music/Mute Video`
 * folder, where music apps and file managers find it.
 *
 * Android 10+ writes through MediaStore and needs no permission. Android 9
 * and older write the file directly and need WRITE_EXTERNAL_STORAGE, which
 * the caller asks for first.
 */
object AudioSaver {

    private const val FOLDER = "Mute Video"
    private const val MIME = "audio/mp4"

    /** Returns where the file landed (a content URI or a path), for logs. */
    fun save(context: Context, sourcePath: String, displayName: String): String {
        val source = File(sourcePath)
        if (!source.exists()) throw IllegalArgumentException("No such file: $sourcePath")
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveWithMediaStore(context, source, displayName)
        } else {
            saveToFolder(context, source, displayName)
        }
    }

    /** Only Android 9 and older need the storage permission for this. */
    fun needsPermission(): Boolean = Build.VERSION.SDK_INT < Build.VERSION_CODES.Q

    private fun saveWithMediaStore(context: Context, source: File, displayName: String): String {
        val resolver = context.contentResolver
        val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Audio.Media.MIME_TYPE, MIME)
            put(MediaStore.Audio.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MUSIC}/$FOLDER")
            put(MediaStore.Audio.Media.IS_MUSIC, 1)
            // Hidden from other apps until the copy is complete.
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore refused the new file")
        try {
            val output = resolver.openOutputStream(uri)
                ?: throw IllegalStateException("Could not open the new file")
            output.use { out -> source.inputStream().use { it.copyTo(out) } }
            values.clear()
            values.put(MediaStore.Audio.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        } catch (error: Exception) {
            // Never leave a broken, half-written entry in the music library.
            resolver.delete(uri, null, null)
            throw error
        }
    }

    @Suppress("DEPRECATION")
    private fun saveToFolder(context: Context, source: File, displayName: String): String {
        val folder = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC),
            FOLDER,
        )
        if (!folder.exists() && !folder.mkdirs()) {
            throw IllegalStateException("Could not create ${folder.path}")
        }
        val target = File(folder, displayName)
        try {
            source.copyTo(target, overwrite = true)
        } catch (error: Exception) {
            target.delete()
            throw error
        }
        // So music apps see it without a restart.
        MediaScannerConnection.scanFile(context, arrayOf(target.path), arrayOf(MIME), null)
        return target.path
    }
}
