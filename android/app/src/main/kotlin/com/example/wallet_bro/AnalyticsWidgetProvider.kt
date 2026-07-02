package com.example.wallet_bro

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class AnalyticsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.analytics_widget).apply {
                // Get data from SharedPreferences (set by Flutter HomeWidget plugin)
                val income = widgetData.getString("monthly_income", "৳0")
                val expense = widgetData.getString("monthly_expense", "৳0")

                setTextViewText(R.id.widget_income, income)
                setTextViewText(R.id.widget_expense, expense)

                // PendingIntent to launch the main app
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_analytics_action_button, pendingIntent)
                setOnClickPendingIntent(R.id.analytics_widget_container, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
