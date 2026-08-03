package com.example.scanner

import android.content.ContentValues
import android.net.Uri
import android.content.Intent
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.res.Configuration
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "com.example.scanner/files"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"saveToDownloads" -> {
					val filename = call.argument<String>("filename") ?: "scanned.pdf"
					val bytes = call.argument<ByteArray>("bytes")
					if (bytes == null) {
						result.error("invalid_args", "Missing bytes", null)
						return@setMethodCallHandler
					}
					try {
						val uri = saveToDownloads(filename, bytes)
						result.success(uri?.toString())
					} catch (e: Exception) {
						result.error("save_failed", e.message, null)
					}
				}
				"openUri" -> {
					val uriStr = call.argument<String>("uri")
					if (uriStr == null) {
						result.error("invalid_args", "Missing uri", null)
						return@setMethodCallHandler
					}
					try {
						val uri = Uri.parse(uriStr)
						val intent = Intent(Intent.ACTION_VIEW).apply {
							setDataAndType(uri, "application/pdf")
							addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
						}
						startActivity(Intent.createChooser(intent, "Open PDF"))
						result.success(true)
					} catch (e: Exception) {
						result.error("open_failed", e.message, null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun saveToDownloads(filename: String, bytes: ByteArray): Uri? {
		val resolver = applicationContext.contentResolver
		val contentValues = ContentValues().apply {
			put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
			put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
			put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
		}

		val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
		val uri = resolver.insert(collection, contentValues)
			?: throw Exception("Failed to create media store entry")

		resolver.openOutputStream(uri).use { out ->
			out?.write(bytes)
			out?.flush()
		}

		return uri
	}
}
