package com.beautyshelf.beauty_shelf_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Gallery picking.
 *
 * [MediaStore.ACTION_PICK_IMAGES] (the system Photo Picker) is a Google
 * component that OEM galleries do not take part in, so on MIUI it replaces the
 * Gallery app the user expects. [Intent.ACTION_PICK] is the classic "pick from
 * the gallery" intent, but Google Photos registers it too — and its external
 * picker only shows that app's own library, which can come up empty.
 *
 * So: query ACTION_PICK handlers, prefer the first one that is not Google
 * Photos, and target it explicitly. With no gallery app at all, fall back to
 * the system Photo Picker.
 */
class MainActivity : FlutterActivity() {

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickImage" -> startPickImage(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun startPickImage(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("already_active", "A pick is already in progress", null)
            return
        }
        val intent = buildPickIntent()
        if (intent.resolveActivity(packageManager) == null) {
            result.error("no_gallery", "No activity can handle image picking", null)
            return
        }
        pendingResult = result
        Log.d(TAG, "Picking with action=${intent.action} package=${intent.`package`}")
        startActivityForResult(intent, REQUEST_PICK)
    }

    private fun buildPickIntent(): Intent {
        val candidates = queryCandidates()
        Log.d(TAG, "Image-pick handlers: $candidates")

        for (pkg in candidates) {
            if (!isGallery(pkg)) continue
            val intent = intentFor(pkg) ?: continue
            Log.d(TAG, "Targeting gallery $pkg via ${intent.action}")
            return intent
        }

        Log.d(TAG, "No gallery app found; falling back to the system picker")
        // No gallery app (e.g. Pixel), or only file managers: use the system
        // photo picker, which always shows every image the user has.
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Intent(MediaStore.ACTION_PICK_IMAGES).setType("image/*")
        } else {
            openDocumentIntent()
        }
    }

    /** Packages that can pick an image but are not the gallery the user means. */
    private fun isGallery(pkg: String): Boolean =
        pkg !in NON_GALLERY && pkg.contains("gallery", ignoreCase = true)

    /**
     * Galleries differ in which intent they accept: some take ACTION_PICK,
     * others only ACTION_GET_CONTENT. Try both, scoped to [pkg].
     */
    private fun intentFor(pkg: String): Intent? {
        val pick = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            .setType("image/*")
            .setPackage(pkg)
        if (pick.resolveActivity(packageManager) != null) return pick

        val openDocument = openDocumentIntent().setPackage(pkg)
        if (openDocument.resolveActivity(packageManager) != null) return openDocument

        return null
    }

    private fun openDocumentIntent(): Intent =
        Intent(Intent.ACTION_GET_CONTENT)
            .setType("image/*")
            .addCategory(Intent.CATEGORY_OPENABLE)

    private fun queryCandidates(): List<String> {
        val pick = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            .setType("image/*")

        val packages = mutableListOf<String>()
        for (intent in listOf(pick, openDocumentIntent())) {
            packageManager.queryIntentActivities(intent, 0)
                .mapTo(packages) { it.activityInfo.packageName }
        }
        return packages.distinct()
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_PICK) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingResult
        pendingResult = null
        if (result == null) return

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            result.success(copyToCache(uri))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to copy picked image", e)
            result.error("copy_failed", e.message, null)
        }
    }

    /** uCrop needs a real file path, and our access to a content URI is
     *  one-shot, so the pick is copied into the app cache. */
    private fun copyToCache(uri: Uri): String {
        val dir = File(cacheDir, "gallery_pick").apply { mkdirs() }
        val name = queryDisplayName(uri) ?: "picked.jpg"
        val out = File(dir, "${System.currentTimeMillis()}_$name")

        val input = contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("Cannot open $uri")
        input.use { source ->
            out.outputStream().use { sink -> source.copyTo(sink) }
        }
        return out.absolutePath
    }

    private fun queryDisplayName(uri: Uri): String? {
        val projection = arrayOf(MediaStore.MediaColumns.DISPLAY_NAME)
        contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) return cursor.getString(0)
        }
        return null
    }

    companion object {
        private const val TAG = "BeautyShelfGallery"
        private const val CHANNEL = "com.beautyshelf.beauty_shelf/gallery"
        private const val REQUEST_PICK = 4711

        /** Can handle image picking, but is not the gallery the user means. */
        private val NON_GALLERY = setOf(
            "com.google.android.apps.photos",
            "com.google.android.apps.docs",
            "com.google.android.documentsui",
            "com.android.documentsui",
        )
    }
}
