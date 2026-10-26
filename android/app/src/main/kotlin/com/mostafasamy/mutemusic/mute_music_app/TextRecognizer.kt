package com.mostafasamy.mutemusic.mute_music_app

import android.content.Context
import android.graphics.BitmapFactory
import com.googlecode.tesseract.android.TessBaseAPI
import java.io.File

class UnreadableImageException : Exception("The image can't be read")

/**
 * Spec 006 F8: text from an image, offline, English and Arabic, with
 * Tesseract (tessdata_fast). Android only; iOS uses Apple Vision.
 *
 * The language data ships in the APK's assets and is copied once into the
 * app's private files folder, because Tesseract reads plain files.
 */
object TextRecognizer {

    private const val ASSET_FOLDER = "tessdata"
    private val LANGUAGES = listOf("ara", "eng")

    fun recognize(context: Context, imagePath: String): String {
        val bitmap = BitmapFactory.decodeFile(imagePath) ?: throw UnreadableImageException()
        val dataPath = prepareData(context)
        val api = TessBaseAPI()
        try {
            if (!api.init(dataPath, LANGUAGES.joinToString("+"))) {
                throw IllegalStateException("Tesseract could not start")
            }
            api.setImage(bitmap)
            return api.utF8Text?.trim().orEmpty()
        } finally {
            api.recycle()
            bitmap.recycle()
        }
    }

    /** Returns the folder that holds `tessdata/`, copying the data once. */
    private fun prepareData(context: Context): String {
        val root = File(context.filesDir, "ocr")
        val folder = File(root, ASSET_FOLDER).apply { mkdirs() }
        for (language in LANGUAGES) {
            val target = File(folder, "$language.traineddata")
            if (target.exists() && target.length() > 0) continue
            // Write to a temp name first, so a killed copy is never mistaken
            // for a complete file.
            val partial = File(folder, "$language.traineddata.part")
            context.assets.open("$ASSET_FOLDER/$language.traineddata").use { input ->
                partial.outputStream().use { input.copyTo(it) }
            }
            if (!partial.renameTo(target)) throw IllegalStateException("Could not store $language")
        }
        return root.absolutePath
    }
}
