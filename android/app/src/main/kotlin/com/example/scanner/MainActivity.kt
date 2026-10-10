package com.example.scanner

import android.content.ContentValues
import android.net.Uri
import android.content.Intent
import android.os.Environment
import android.provider.MediaStore
import android.database.Cursor
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import android.content.res.Configuration
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
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
				"getSavedDocuments" -> {
					try {
						result.success(getSavedDocuments())
					} catch (e: Exception) {
						result.error("list_failed", e.message, null)
					}
				}
				"renameDocument" -> {
					val uriString = call.argument<String>("uri")
					val name = call.argument<String>("name")
					if (uriString == null || name == null) {
						result.error("invalid_args", "Missing uri or name", null)
						return@setMethodCallHandler
					}
					try {
						val uri = Uri.parse(uriString)
						val currentId = uri.lastPathSegment
							?: throw IllegalArgumentException("Invalid document uri")
						val collection = MediaStore.Downloads.getContentUri(
							MediaStore.VOLUME_EXTERNAL_PRIMARY,
						)
						val duplicate = contentResolver.query(
							collection,
							arrayOf(MediaStore.MediaColumns._ID),
							"${MediaStore.MediaColumns.DISPLAY_NAME} = ? AND ${MediaStore.MediaColumns._ID} != ?",
							arrayOf(name, currentId),
							null,
						)?.use { cursor -> cursor.moveToFirst() } ?: false
						if (duplicate) {
							throw IllegalStateException("A document with that name already exists")
						}
						val values = ContentValues().apply {
							put(MediaStore.MediaColumns.DISPLAY_NAME, name)
						}
						val updated = contentResolver.update(
							uri,
							values,
							null,
							null,
						)
						if (updated == 0) {
							throw IllegalStateException("Document was not renamed")
						}
						result.success(true)
					} catch (e: Exception) {
						result.error("rename_failed", e.message, null)
					}
				}
				"deleteDocument" -> {
					val uriString = call.argument<String>("uri")
					if (uriString == null) {
						result.error("invalid_args", "Missing uri", null)
						return@setMethodCallHandler
					}
					try {
						val deleted = contentResolver.delete(
							Uri.parse(uriString),
							null,
							null,
						)
						if (deleted == 0) {
							throw IllegalStateException("Document was not deleted")
						}
						result.success(true)
					} catch (e: Exception) {
						result.error("delete_failed", e.message, null)
					}
				}
				"shareDocument" -> {
					val uriString = call.argument<String>("uri")
					val name = call.argument<String>("name")
					if (uriString == null || name == null) {
						result.error("invalid_args", "Missing uri or name", null)
						return@setMethodCallHandler
					}
					try {
						val uri = Uri.parse(uriString)
						val mimeType = when (name.substringAfterLast('.', "").lowercase()) {
							"pdf" -> "application/pdf"
							"png" -> "image/png"
							"jpg", "jpeg" -> "image/jpeg"
							else -> "*/*"
						}
						val sendIntent = Intent(Intent.ACTION_SEND).apply {
							type = mimeType
							putExtra(Intent.EXTRA_STREAM, uri)
							putExtra(Intent.EXTRA_SUBJECT, name)
							addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
							clipData = android.content.ClipData.newUri(
								contentResolver,
								name,
								uri,
							)
						}
						startActivity(Intent.createChooser(sendIntent, null))
						result.success(true)
					} catch (e: Exception) {
						result.error("share_failed", e.message, null)
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
				"readDocumentBytes" -> {
					val uriStr = call.argument<String>("uri")
					if (uriStr == null) {
						result.error("invalid_args", "Missing uri", null)
						return@setMethodCallHandler
					}
					try {
						val bytes = contentResolver.openInputStream(Uri.parse(uriStr))
							?.use { input -> input.readBytes() }
							?: throw IllegalStateException("Could not read document")
						result.success(bytes)
					} catch (e: Exception) {
						result.error("read_failed", e.message, null)
					}
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun getSavedDocuments(): List<Map<String, Any>> {
		val projection = arrayOf(
			MediaStore.MediaColumns.DISPLAY_NAME,
			MediaStore.MediaColumns.SIZE,
			MediaStore.MediaColumns.DATE_MODIFIED,
			MediaStore.MediaColumns._ID,
		)
		val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?"
		val selectionArgs = arrayOf("scanned_document_%.pdf")
		val documents = mutableListOf<Map<String, Any>>()
		val collection = MediaStore.Downloads.getContentUri(
			MediaStore.VOLUME_EXTERNAL_PRIMARY,
		)

		val cursor = contentResolver.query(
			collection,
			projection,
			selection,
			selectionArgs,
			"${MediaStore.MediaColumns.DATE_MODIFIED} DESC",
		) ?: throw IllegalStateException("Could not query downloaded documents")

		cursor.use { cursor: Cursor ->
			val nameIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
			val sizeIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
			val modifiedIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)
			val idIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
			while (cursor.moveToNext()) {
				val id = cursor.getLong(idIndex)
				val uri = Uri.withAppendedPath(collection, id.toString())
				documents.add(
					mapOf(
						"name" to cursor.getString(nameIndex),
						"path" to uri.toString(),
						"size" to cursor.getLong(sizeIndex).toInt(),
						"modified" to cursor.getLong(modifiedIndex) * 1000,
					),
				)
			}
		}
		return documents
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
