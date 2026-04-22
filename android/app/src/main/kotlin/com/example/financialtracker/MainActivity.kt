package com.example.financialtracker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import androidx.activity.result.contract.ActivityResultContracts
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val channelName = "clockwise/saf"
    private var pendingPickerResult: MethodChannel.Result? = null

    private val openTreeLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val pending = pendingPickerResult
        pendingPickerResult = null

        if (pending == null) return@registerForActivityResult

        if (result.resultCode != Activity.RESULT_OK || result.data == null) {
            pending.success(null)
            return@registerForActivityResult
        }

        val treeUri = result.data?.data
        if (treeUri == null) {
            pending.success(null)
            return@registerForActivityResult
        }

        val flags = result.data?.flags ?: 0
        val takeFlags = flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)

        contentResolver.takePersistableUriPermission(treeUri, takeFlags)

        val root = DocumentFile.fromTreeUri(this, treeUri)
        val name = root?.name ?: "Workspace"

        pending.success(
            mapOf(
                "id" to UUID.randomUUID().toString(),
                "name" to name,
                "treeUri" to treeUri.toString(),
            )
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    handleMethodCall(call, result)
                } catch (error: Throwable) {
                    result.error("SAF_ERROR", error.message, null)
                }
            }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickWorkspaceDirectory" -> pickWorkspaceDirectory(result)
            "listChildren" -> listChildren(call, result)
            "readText" -> readText(call, result)
            "writeText" -> writeText(call, result)
            "createFile" -> createFile(call, result)
            "createDirectory" -> createDirectory(call, result)
            "ensureDirectory" -> ensureDirectory(call, result)
            "findChild" -> findChild(call, result)
            "deleteDocument" -> deleteDocument(call, result)
            "renameDocument" -> renameDocument(call, result)
            "getDocumentInfo" -> getDocumentInfo(call, result)
            else -> result.notImplemented()
        }
    }

    private fun pickWorkspaceDirectory(result: MethodChannel.Result) {
        if (pendingPickerResult != null) {
            result.error("PICKER_BUSY", "Workspace picker already open", null)
            return
        }

        pendingPickerResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, Uri.EMPTY)
            }
        }

        openTreeLauncher.launch(intent)
    }

    private fun listChildren(call: MethodCall, result: MethodChannel.Result) {
        val treeUri = Uri.parse(call.argument<String>("treeUri") ?: throw IllegalArgumentException("treeUri missing"))
        val directoryUriArg = call.argument<String>("directoryUri")

        val directory = if (directoryUriArg.isNullOrBlank()) {
            DocumentFile.fromTreeUri(this, treeUri)
        } else {
            DocumentFile.fromTreeUri(this, Uri.parse(directoryUriArg))
                ?: DocumentFile.fromSingleUri(this, Uri.parse(directoryUriArg))
        }

        if (directory == null || !directory.exists()) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        val children = directory.listFiles().map { child ->
            mapOf(
                "uri" to child.uri.toString(),
                "name" to (child.name ?: "unknown"),
                "isDirectory" to child.isDirectory,
                "relativePath" to relativePathFor(treeUri, child.uri),
                "lastModified" to child.lastModified(),
                "size" to if (child.isDirectory) null else child.length(),
            )
        }

        result.success(children)
    }

    private fun readText(call: MethodCall, result: MethodChannel.Result) {
        val uri = Uri.parse(call.argument<String>("uri") ?: throw IllegalArgumentException("uri missing"))

        contentResolver.openInputStream(uri).use { stream ->
            if (stream == null) {
                result.success("")
                return
            }

            val text = BufferedReader(InputStreamReader(stream)).readText()
            result.success(text)
        }
    }

    private fun writeText(call: MethodCall, result: MethodChannel.Result) {
        val uri = Uri.parse(call.argument<String>("uri") ?: throw IllegalArgumentException("uri missing"))
        val content = call.argument<String>("content") ?: ""

        contentResolver.openOutputStream(uri, "wt").use { stream ->
            if (stream == null) {
                throw IllegalStateException("Unable to open output stream")
            }

            OutputStreamWriter(stream).use { writer ->
                writer.write(content)
            }
        }

        result.success(null)
    }

    private fun createFile(call: MethodCall, result: MethodChannel.Result) {
        val treeUri = Uri.parse(call.argument<String>("treeUri") ?: throw IllegalArgumentException("treeUri missing"))
        val parentUri = Uri.parse(call.argument<String>("parentUri") ?: throw IllegalArgumentException("parentUri missing"))
        val name = call.argument<String>("name") ?: throw IllegalArgumentException("name missing")
        val mimeType = call.argument<String>("mimeType") ?: "text/plain"

        val parent = openDirectory(treeUri, parentUri)
        val file = parent?.createFile(mimeType, name)
        result.success(file?.uri?.toString())
    }

    private fun createDirectory(call: MethodCall, result: MethodChannel.Result) {
        val treeUri = Uri.parse(call.argument<String>("treeUri") ?: throw IllegalArgumentException("treeUri missing"))
        val parentUri = Uri.parse(call.argument<String>("parentUri") ?: throw IllegalArgumentException("parentUri missing"))
        val name = call.argument<String>("name") ?: throw IllegalArgumentException("name missing")

        val parent = openDirectory(treeUri, parentUri)
        val dir = parent?.createDirectory(name)
        result.success(dir?.uri?.toString())
    }

    private fun ensureDirectory(call: MethodCall, result: MethodChannel.Result) {
        val treeUri = Uri.parse(call.argument<String>("treeUri") ?: throw IllegalArgumentException("treeUri missing"))
        val parentUri = Uri.parse(call.argument<String>("parentUri") ?: throw IllegalArgumentException("parentUri missing"))
        val name = call.argument<String>("name") ?: throw IllegalArgumentException("name missing")

        val parent = openDirectory(treeUri, parentUri)
        if (parent == null) {
            result.success(null)
            return
        }

        val existing = parent.listFiles().firstOrNull { it.isDirectory && it.name == name }
        if (existing != null) {
            result.success(existing.uri.toString())
            return
        }

        val created = parent.createDirectory(name)
        result.success(created?.uri?.toString())
    }

    private fun findChild(call: MethodCall, result: MethodChannel.Result) {
        val treeUri = Uri.parse(call.argument<String>("treeUri") ?: throw IllegalArgumentException("treeUri missing"))
        val parentUri = Uri.parse(call.argument<String>("parentUri") ?: throw IllegalArgumentException("parentUri missing"))
        val name = call.argument<String>("name") ?: throw IllegalArgumentException("name missing")

        val parent = openDirectory(treeUri, parentUri)
        val existing = parent?.listFiles()?.firstOrNull { it.name == name }
        result.success(existing?.uri?.toString())
    }

    private fun deleteDocument(call: MethodCall, result: MethodChannel.Result) {
        val uri = Uri.parse(call.argument<String>("uri") ?: throw IllegalArgumentException("uri missing"))
        DocumentsContract.deleteDocument(contentResolver, uri)
        result.success(null)
    }

    private fun renameDocument(call: MethodCall, result: MethodChannel.Result) {
        val uri = Uri.parse(call.argument<String>("uri") ?: throw IllegalArgumentException("uri missing"))
        val newName = call.argument<String>("newName") ?: throw IllegalArgumentException("newName missing")

        val renamed = DocumentsContract.renameDocument(contentResolver, uri, newName)
        result.success(renamed?.toString())
    }

    private fun getDocumentInfo(call: MethodCall, result: MethodChannel.Result) {
        val treeUri = Uri.parse(call.argument<String>("treeUri") ?: throw IllegalArgumentException("treeUri missing"))
        val rawUri = call.argument<String>("uri") ?: throw IllegalArgumentException("uri missing")

        val uri = Uri.parse(rawUri)
        val file = openDirectory(treeUri, uri)
            ?: DocumentFile.fromSingleUri(this, uri)
            ?: DocumentFile.fromTreeUri(this, uri)

        if (file == null) {
            result.success(null)
            return
        }

        result.success(
            mapOf(
                "uri" to file.uri.toString(),
                "name" to file.name,
                "isDirectory" to file.isDirectory,
                "relativePath" to relativePathFor(treeUri, file.uri),
                "lastModified" to file.lastModified(),
                "size" to if (file.isDirectory) null else file.length(),
            )
        )
    }

    private fun openDirectory(treeUri: Uri, uri: Uri): DocumentFile? {
        if (uri == treeUri) {
            return DocumentFile.fromTreeUri(this, treeUri)
        }

        return DocumentFile.fromTreeUri(this, uri)
            ?: DocumentFile.fromSingleUri(this, uri)
            ?: DocumentFile.fromTreeUri(this, treeUri)
    }

    private fun relativePathFor(treeUri: Uri, nodeUri: Uri): String {
        return try {
            val rootId = DocumentsContract.getTreeDocumentId(treeUri)
            val docId = DocumentsContract.getDocumentId(nodeUri)
            when {
                docId == rootId -> ""
                docId.startsWith("$rootId/") -> docId.removePrefix("$rootId/")
                else -> docId
            }
        } catch (_: Throwable) {
            ""
        }
    }
}
