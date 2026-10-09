package com.njerahouse.tafsiri

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Handler
import android.os.Looper
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Text recognition through Tesseract compiled into the app (ADR-075).
 *
 * Replaces ML Kit, which F-Droid cannot ship. One method, `recognise`: the Dart
 * side has already made sure the trained data is on disk, so this only loads
 * it, reads one image and reports the text with Tesseract's mean confidence —
 * the number the confidence gate needs and ML Kit never provided.
 *
 * Recognition is slow and Tesseract marks it @WorkerThread, so it runs on a
 * single background thread. One thread rather than a pool is deliberate: the
 * engine holds hundreds of megabytes while it works, and two at once on a
 * phone is how an app gets killed.
 */
object TesseractChannel {
    private const val NAME = "tafsiri/tesseract"

    /**
     * Long edge an image is reduced to before recognition. A 12-megapixel
     * photo makes Tesseract slow without making it more accurate; text in a
     * photo is legible well below this.
     */
    private const val MAX_EDGE = 3000

    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, NAME)
            .setMethodCallHandler { call, result ->
                if (call.method != "recognise") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val image = call.argument<String>("imagePath")
                val dataPath = call.argument<String>("dataPath")
                val languages = call.argument<String>("languages")
                if (image == null || dataPath == null || languages == null) {
                    result.error("bad_args", "imagePath, dataPath and languages are required", null)
                    return@setMethodCallHandler
                }
                worker.execute { recognise(image, dataPath, languages, result) }
            }
    }

    private fun recognise(
        imagePath: String,
        dataPath: String,
        languages: String,
        result: MethodChannel.Result,
    ) {
        val bitmap = try {
            loadUpright(imagePath)
        } catch (e: Exception) {
            main.post { result.error("unreadable_image", e.message, null) }
            return
        }

        val api = TessBaseAPI()
        try {
            if (!api.init(dataPath, languages)) {
                main.post {
                    result.error("init_failed", "could not load '$languages' from $dataPath", null)
                }
                return
            }
            api.setImage(bitmap)
            val text = api.getUTF8Text() ?: ""
            val confidence = api.meanConfidence()
            main.post { result.success(mapOf("text" to text, "confidence" to confidence)) }
        } catch (e: Throwable) {
            main.post { result.error("recognition_failed", e.message, null) }
        } finally {
            api.recycle()
            bitmap.recycle()
        }
    }

    /**
     * Decodes [path] reduced to [MAX_EDGE] and turned the way the camera held
     * it. A phone stores a portrait photo as landscape pixels plus an EXIF
     * note saying "rotate me"; BitmapFactory ignores the note, and Tesseract
     * reading text that lies on its side finds almost nothing.
     */
    private fun loadUpright(path: String): Bitmap {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        require(bounds.outWidth > 0 && bounds.outHeight > 0) { "not an image this device can read" }

        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / sample > MAX_EDGE) sample *= 2

        val decoded = BitmapFactory.decodeFile(path, BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.ARGB_8888
        }) ?: throw IllegalArgumentException("not an image this device can read")

        val degrees = when (
            ExifInterface(path).getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL,
            )
        ) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> return decoded
        }
        val turned = Bitmap.createBitmap(
            decoded, 0, 0, decoded.width, decoded.height,
            Matrix().apply { postRotate(degrees) }, true,
        )
        if (turned !== decoded) decoded.recycle()
        return turned
    }
}
