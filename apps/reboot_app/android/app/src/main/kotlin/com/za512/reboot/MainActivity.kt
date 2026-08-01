package com.za512.reboot

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Intent
import android.os.Build
import android.os.PersistableBundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private var backupResult: MethodChannel.Result? = null
    private var backupSourcePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.za512.reboot/device_context",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocalTimeZoneIdentifier" -> result.success(TimeZone.getDefault().id)
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.za512.reboot/weekly_widget",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWeeklyWidget" -> {
                    val displayAmount = call.argument<String>("displayAmount")
                    val validBeforeDate = call.argument<String>("validBeforeDate")
                    if (
                        displayAmount.isNullOrBlank() ||
                            displayAmount.length > 32 ||
                            !WeeklyWidgetStateStore.isValidIsoDate(validBeforeDate)
                    ) {
                        result.error("invalid_widget_state", "Invalid widget display state.", null)
                    } else {
                        try {
                            WeeklyWidgetStateStore.write(
                                applicationContext,
                                WeeklyWidgetState(displayAmount, validBeforeDate!!),
                            )
                            RebootWidgetProvider.updateAll(applicationContext)
                            result.success(null)
                        } catch (_: Exception) {
                            result.error("widget_update_failed", "The widget could not be updated.", null)
                        }
                    }
                }

                "requestPinWeeklyWidget" ->
                    result.success(RebootWidgetProvider.requestPin(applicationContext))

                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.za512.reboot/local_backup",
        ).setMethodCallHandler { call, result ->
            if (backupResult != null) {
                result.error("backup_busy", "Another document operation is active.", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "copyRecoveryCode" -> {
                    val code = call.argument<String>("code")
                    if (code == null || code.length !in 40..96 || !code.startsWith("RB1.")) {
                        result.error("invalid_recovery_code", "Invalid recovery code.", null)
                    } else {
                        val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
                        val clip = ClipData.newPlainText("REBOOT recovery code", code)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            clip.description.extras =
                                PersistableBundle().apply {
                                    putBoolean("android.content.extra.IS_SENSITIVE", true)
                                }
                        }
                        clipboard.setPrimaryClip(clip)
                        result.success(null)
                    }
                }

                "saveBackup" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val suggestedName = call.argument<String>("suggestedName")
                    val source = sourcePath?.let(::File)
                    if (
                        source == null ||
                            !isPrivateCacheFile(source) ||
                            !source.isFile ||
                            source.length() <= 0 ||
                            source.length() > MAX_BACKUP_BYTES ||
                            suggestedName.isNullOrBlank() ||
                            !SAFE_FILENAME.matches(suggestedName)
                    ) {
                        result.error("invalid_backup", "Invalid backup document.", null)
                    } else {
                        backupResult = result
                        backupSourcePath = source.canonicalPath
                        val intent =
                            Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "application/octet-stream"
                                putExtra(Intent.EXTRA_TITLE, suggestedName)
                            }
                        startActivityForResult(intent, REQUEST_SAVE_BACKUP)
                    }
                }

                "pickBackup" -> {
                    backupResult = result
                    val intent =
                        Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/octet-stream"
                        }
                    startActivityForResult(intent, REQUEST_OPEN_BACKUP)
                }

                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Android document picker still reports through the activity result API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_SAVE_BACKUP && requestCode != REQUEST_OPEN_BACKUP) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val pending = backupResult ?: return
        backupResult = null
        try {
            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                pending.success(null)
                return
            }
            val uri = data.data!!
            if (requestCode == REQUEST_SAVE_BACKUP) {
                val sourcePath = backupSourcePath
                backupSourcePath = null
                if (sourcePath == null) {
                    pending.error("backup_save_failed", "The backup could not be saved.", null)
                    return
                }
                contentResolver.openOutputStream(uri, "w").use { output ->
                    if (output == null) throw IllegalStateException("output unavailable")
                    File(sourcePath).inputStream().use { input -> input.copyTo(output) }
                    output.flush()
                }
                pending.success(true)
            } else {
                val destination = File.createTempFile("reboot-import-", ".reboot-backup", cacheDir)
                try {
                    contentResolver.openInputStream(uri).use { input ->
                        if (input == null) throw IllegalStateException("input unavailable")
                        destination.outputStream().use { output ->
                            val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                            var total = 0L
                            while (true) {
                                val read = input.read(buffer)
                                if (read < 0) break
                                total += read
                                if (total > MAX_BACKUP_BYTES) {
                                    throw BackupTooLargeException()
                                }
                                output.write(buffer, 0, read)
                            }
                            output.flush()
                        }
                    }
                    if (destination.length() <= 0) throw IllegalStateException("empty backup")
                    pending.success(destination.canonicalPath)
                } catch (error: Exception) {
                    destination.delete()
                    throw error
                }
            }
        } catch (_: BackupTooLargeException) {
            pending.error("backup_too_large", "The backup document is too large.", null)
        } catch (_: Exception) {
            pending.error("backup_document_failed", "The document operation failed.", null)
        } finally {
            backupSourcePath = null
        }
    }

    private fun isPrivateCacheFile(file: File): Boolean {
        val cacheRoot = cacheDir.canonicalPath + File.separator
        return file.canonicalPath.startsWith(cacheRoot)
    }

    private class BackupTooLargeException : Exception()

    companion object {
        private const val REQUEST_SAVE_BACKUP = 7011
        private const val REQUEST_OPEN_BACKUP = 7012
        private const val MAX_BACKUP_BYTES = 64L * 1024L * 1024L
        private val SAFE_FILENAME = Regex("^[A-Za-z0-9._-]{1,96}\\.reboot-backup$")
    }
}
