package pw.dotto.netmanager.Widgets;

import static pw.dotto.netmanager.Utils.Mobile.getGenerationLabel;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.view.View;
import android.widget.RemoteViews;
import pw.dotto.netmanager.Core.Manager;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.R;
import pw.dotto.netmanager.Widgets.Theme.ThemeEngine;

/**
 * NetManager's SIMWidgetProvider class is the Android provider for the dual SIM
 * cell data widget.
 * This class handles the widget's behaviour along with how the widget itself
 * gets built.
 *
 * @author DottoXD
 * @version 0.1.1
 */
public class SIMWidgetProvider extends AppWidgetProvider {
    public static final String ACTION_REFRESH_DUALSIM = "pw.dotto.netmanager.ACTION_REFRESH_DUALSIM";

    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_dualsim);
            Manager core = new Manager(context, "widget_dualsim", 180);

            java.util.List<Integer> slotIds = core.getSimSlotIds();

            if (!slotIds.isEmpty()) {
                int slot1 = slotIds.get(0);

                String carrier1 = core.getSimCarrier(slot1);
                views.setTextViewText(R.id.txt_sim1_title,
                        "NetManager".equals(carrier1) ? "Airplane/Emergency" : carrier1);
                SIMData data1 = core.getSimNetworkData(slot1);

                if (data1 != null && data1.getPrimaryCell() != null) {
                    views.setTextViewText(R.id.txt_sim1_signal, data1.getPrimaryCell().getProcessedSignal() + "dBm");
                    views.setTextViewText(R.id.txt_sim1_band, "B" + data1.getPrimaryCell().getBand());
                }

                populateChip(views, R.id.chip_sim1_tech, R.id.txt_sim1_tech, core, slot1);
            } else {
                views.setTextViewText(R.id.txt_sim1_title, "Airplane/Emergency");
                views.setTextViewText(R.id.txt_sim1_signal, "");
                views.setTextViewText(R.id.txt_sim1_band, "");
                views.setViewVisibility(R.id.chip_sim1_tech, View.GONE);
            }

            if (slotIds.size() > 1) {
                int slot2 = slotIds.get(1);

                views.setViewVisibility(R.id.layout_sim2, View.VISIBLE);
                String carrier2 = core.getSimCarrier(slot2);
                views.setTextViewText(R.id.txt_sim2_title,
                        "NetManager".equals(carrier2) ? "Airplane/Emergency" : carrier2);
                SIMData data2 = core.getSimNetworkData(slot2);

                if (data2 != null && data2.getPrimaryCell() != null) {
                    views.setTextViewText(R.id.txt_sim2_signal, data2.getPrimaryCell().getProcessedSignal() + "dBm");
                    views.setTextViewText(R.id.txt_sim2_band, "B" + data2.getPrimaryCell().getBand());
                }

                populateChip(views, R.id.chip_sim2_tech, R.id.txt_sim2_tech, core, slot2);
            } else {
                views.setViewVisibility(R.id.layout_sim2, View.GONE);
            }

            core.dispose();

            Intent refreshIntent = new Intent(context, SIMWidgetProvider.class).setAction(ACTION_REFRESH_DUALSIM);
            views.setOnClickPendingIntent(R.id.btn_refresh_dualsim, PendingIntent.getBroadcast(context, 1,
                    refreshIntent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE));

            Intent openIntent = new Intent(context, MainActivity.class);
            if (openIntent != null) {
                views.setOnClickPendingIntent(R.id.widget_bg, PendingIntent.getActivity(context, 3, openIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE));
            }

            ThemeEngine.applyTheme(context, views);
            manager.updateAppWidget(id, views);
        }
    }

    private void populateChip(RemoteViews views, int chipId, int textId, Manager core, int simSlot) {
        int gen = -1;

        try {
            gen = core.getSimNetworkGen(simSlot);
        } catch (Exception ignored) {
        }

        String label = getGenerationLabel(gen);
        if (label.equalsIgnoreCase("N/A")) {
            views.setViewVisibility(chipId, View.GONE);
        } else {
            views.setTextViewText(textId, label);
            views.setViewVisibility(chipId, View.VISIBLE);
        }
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);

        if (ACTION_REFRESH_DUALSIM.equals(intent.getAction())) {
            AppWidgetManager wm = AppWidgetManager.getInstance(context);
            onUpdate(context, wm, wm.getAppWidgetIds(new ComponentName(context, SIMWidgetProvider.class)));
        }
    }
}