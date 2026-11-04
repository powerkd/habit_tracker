package com.example.habit_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class HabitWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val title = widgetData.getString("t_title", "今天") ?: "今天"
        val emptyText = widgetData.getString("t_empty", "今天沒有排程") ?: "今天沒有排程"
        val staleText = widgetData.getString("t_stale", "點開更新今日進度") ?: "點開更新今日進度"

        // 跨日判斷：Dart 存的日期（yyyy-MM-dd）和手機今天不同，就算過期
        val savedDate = widgetData.getString("date", "") ?: ""
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val stale = savedDate != today

        appWidgetIds.forEach { id ->
            val v = RemoteViews(context.packageName, R.layout.widget_habit)

            v.setTextViewText(R.id.title, title)

            if (stale) {
                v.setTextViewText(R.id.progress, "")
                v.setTextViewText(R.id.row0, staleText)
                for (r in intArrayOf(R.id.row1, R.id.row2, R.id.row3)) {
                    v.setTextViewText(r, "")
                }
                v.setTextViewText(R.id.more, "")
            } else {
                val done = widgetData.getInt("done", 0)
                val total = widgetData.getInt("total", 0)
                v.setTextViewText(R.id.progress, "$done/$total")
                val rows = intArrayOf(R.id.row0, R.id.row1, R.id.row2, R.id.row3)
                rows.forEachIndexed { i, rid ->
                    v.setTextViewText(rid, widgetData.getString("row$i", "") ?: "")
                }
                if (total == 0) v.setTextViewText(R.id.row0, emptyText)
                v.setTextViewText(R.id.more, widgetData.getString("more", "") ?: "")
            }

            val launch = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            if (launch != null) {
                val pi = PendingIntent.getActivity(
                    context, 0, launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                v.setOnClickPendingIntent(R.id.widget_root, pi)
            }
            appWidgetManager.updateAppWidget(id, v)
        }
    }
}
