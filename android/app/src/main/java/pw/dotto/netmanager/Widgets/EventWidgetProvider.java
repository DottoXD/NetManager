package pw.dotto.netmanager.Widgets;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.widget.RemoteViews;

import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.R;
import pw.dotto.netmanager.Widgets.Theme.ThemeEngine;

/**
 * NetManager's EventWidgetProvider class is the Android provider for the events
 * widget.
 * This class handles the widget's behaviour.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class EventWidgetProvider extends AppWidgetProvider {
    public static final String ACTION_REFRESH_TICKER = "pw.dotto.netmanager.ACTION_REFRESH_TICKER";

    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_events);

            Intent serviceIntent = new Intent(context, EventWidgetService.class);
            serviceIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id);
            serviceIntent.setData(Uri.parse(serviceIntent.toUri(Intent.URI_INTENT_SCHEME)));
            views.setRemoteAdapter(R.id.list_events, serviceIntent);
            views.setEmptyView(R.id.list_events, android.R.id.empty);

            Intent refreshIntent = new Intent(context, EventWidgetProvider.class).setAction(ACTION_REFRESH_TICKER);
            views.setOnClickPendingIntent(R.id.btn_refresh_events, PendingIntent.getBroadcast(context, 2, refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE));

            Intent openIntent = new Intent(context, MainActivity.class);
            PendingIntent openPendingIntent = PendingIntent.getActivity(context, 0, openIntent,
                    PendingIntent.FLAG_IMMUTABLE);
            if (openIntent != null && openPendingIntent != null) {
                views.setOnClickPendingIntent(R.id.widget_bg, PendingIntent.getActivity(context, 3, openIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE));

                views.setPendingIntentTemplate(R.id.list_events, openPendingIntent);
            }

            ThemeEngine.applyTheme(context, views);
            manager.updateAppWidget(id, views);
            manager.notifyAppWidgetViewDataChanged(id, R.id.list_events);
        }
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);

        if (ACTION_REFRESH_TICKER.equals(intent.getAction())) {
            AppWidgetManager wm = AppWidgetManager.getInstance(context);
            int[] ids = wm.getAppWidgetIds(new ComponentName(context, EventWidgetProvider.class));

            wm.notifyAppWidgetViewDataChanged(ids, R.id.list_events);
            onUpdate(context, wm, ids);
        }
    }
}