package com.za512.reboot

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.widget.RemoteViews

class RebootWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views(context, false)) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != revealAction) return
        renderAll(context, revealed = true)
        val pendingResult = goAsync()
        Handler(Looper.getMainLooper()).postDelayed(
            {
                try {
                    renderAll(context, revealed = false)
                } finally {
                    pendingResult.finish()
                }
            },
            revealDurationMillis,
        )
    }

    companion object {
        private const val revealAction = "com.za512.reboot.action.REVEAL_WEEKLY_WIDGET"
        private const val revealDurationMillis = 2_000L

        fun updateAll(context: Context) = renderAll(context, revealed = false)

        fun requestPin(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
            val manager = AppWidgetManager.getInstance(context)
            if (!manager.isRequestPinAppWidgetSupported) return false
            return manager.requestPinAppWidget(
                ComponentName(context, RebootWidgetProvider::class.java),
                null,
                null,
            )
        }

        private fun renderAll(context: Context, revealed: Boolean) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, RebootWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            ids.forEach { manager.updateAppWidget(it, views(context, revealed)) }
        }

        private fun views(context: Context, revealed: Boolean): RemoteViews {
            val state = WeeklyWidgetStateStore.read(context)
            val stale = state != null && WeeklyWidgetStateStore.isStale(state)
            val canReveal = revealed && state != null && !stale
            val amount =
                when {
                    canReveal -> state.displayAmount
                    state == null -> context.getString(R.string.widget_empty_amount)
                    else -> context.getString(R.string.widget_masked_amount)
                }
            val hint =
                when {
                    state == null || stale -> context.getString(R.string.widget_open_reboot)
                    canReveal -> context.getString(R.string.widget_hides_automatically)
                    else -> context.getString(R.string.widget_tap_to_reveal)
                }
            return RemoteViews(context.packageName, R.layout.reboot_weekly_widget).apply {
                setTextViewText(R.id.widget_amount, amount)
                setTextViewText(R.id.widget_hint, hint)
                setTextColor(
                    R.id.widget_amount,
                    context.getColor(
                        if (canReveal) R.color.widget_amount_revealed else R.color.widget_amount_masked,
                    ),
                )
                setContentDescription(
                    R.id.widget_amount,
                    if (canReveal) amount else hint,
                )
                setOnClickPendingIntent(
                    R.id.widget_amount,
                    if (state == null || stale) {
                        openAppPendingIntent(context)
                    } else {
                        revealPendingIntent(context)
                    },
                )
                setOnClickPendingIntent(R.id.widget_hint, openAppPendingIntent(context))
                setOnClickPendingIntent(R.id.widget_brand, openAppPendingIntent(context))
            }
        }

        private fun revealPendingIntent(context: Context): PendingIntent {
            val intent =
                Intent(context, RebootWidgetProvider::class.java).apply {
                    action = revealAction
                    flags = Intent.FLAG_RECEIVER_FOREGROUND
                }
            return PendingIntent.getBroadcast(
                context,
                5102,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun openAppPendingIntent(context: Context): PendingIntent {
            val intent =
                Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
            return PendingIntent.getActivity(
                context,
                5101,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
