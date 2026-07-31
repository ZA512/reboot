package com.za512.reboot

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
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
    }
}
