package pw.dotto.netmanager.Core.Notifications;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.service.notification.StatusBarNotification;
import android.telephony.CellInfo;

import androidx.core.app.NotificationCompat;

import java.util.Random;

import pw.dotto.netmanager.Core.MobileInfo.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.MobileInfo.SIMData;
import pw.dotto.netmanager.Core.Utils;
import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.R;

public class MonitorNotification {
    private final NotificationService context;

    private NotificationManager notificationManager;
    private NotificationChannel notificationChannel;
    private NotificationCompat.Builder activeNotification;
    private int selectedId = -1;

    private PendingIntent closingPendingIntent;
    private PendingIntent openPendingIntent;

    public static final String NOTIFICATION_CHANNEL = "netmanager-chn";

    public MonitorNotification(NotificationService context) {
        this.context = context;
    }

    public void setupNotifications() {
        if (context == null)
            return;

        notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        if (notificationManager == null)
            return;

        notificationChannel = notificationManager.getNotificationChannel(NOTIFICATION_CHANNEL);
        if (notificationChannel == null) {
            notificationChannel = new NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    "NetManager",
                    NotificationManager.IMPORTANCE_LOW);

            notificationChannel.enableVibration(false);
            notificationManager.createNotificationChannel(notificationChannel);
        }

        // replace notification id persistence with shared_preferences
        for (StatusBarNotification notification : notificationManager.getActiveNotifications()) {
            if (notification.getNotification().getChannelId().equals(NOTIFICATION_CHANNEL)) {
                selectedId = notification.getId();
                break;
            }
        }

        if (selectedId < 0)
            selectedId = new Random().nextInt(10);

        Intent closingIntent = new Intent(context, Receiver.class);
        closingIntent.setAction("CLOSE_NOTIFICATION");
        closingIntent.putExtra("id", selectedId);
        closingPendingIntent = PendingIntent.getBroadcast(context, 0, closingIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Intent openIntent = new Intent(context, MainActivity.class);
        openIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK |
                Intent.FLAG_ACTIVITY_CLEAR_TASK);
        openPendingIntent = PendingIntent.getActivity(context, 0, openIntent,
                PendingIntent.FLAG_IMMUTABLE);
    }

    public void send() {
        if (!Utils.checkPermissions(context) || (notificationManager == null || notificationChannel == null))
            return;

        buildNotification();
        notificationManager.notify(selectedId, activeNotification.build());
    }

    public void cancel() {
        notificationManager.cancel(selectedId);
    }

    public void buildNotification() {
        StringBuilder contentText = new StringBuilder();
        for (int i = 0; i < 2; i++) {
            SIMData simData = context.getManager().getSimNetworkData(i);
            if (simData == null || simData.getPrimaryCell() == null)
                break;

            String nodeStr;

            try {
                nodeStr = Integer.parseInt(simData.getPrimaryCell().getCellIdentifier()) / 256 + "/"
                        + Integer.parseInt(simData.getPrimaryCell().getCellIdentifier()) % 256;
            } catch (Exception ignored) {
                nodeStr = "Unavailable";
            }

            contentText.append("SIM ").append(i + 1).append(" (").append(simData.getMccMnc()).append(", ")
                    .append((simData.getPrimaryCell() instanceof NrCellData ? "N" : "B"))
                    .append(simData.getPrimaryCell().getBasicCellData().getBand()).append(" ")
                    .append(simData.getPrimaryCell().getBasicCellData().getFrequency()).append("MHz)\n").append(nodeStr)
                    .append(" (")
                    .append(simData.getPrimaryCell().getProcessedSignal()).append("dBm)\n");

            if (simData.getPrimaryCell().getSignalQuality() != CellInfo.UNAVAILABLE)
                contentText.append(simData.getPrimaryCell().getSignalQualityString()).append(": ")
                        .append(simData.getPrimaryCell().getSignalQuality()).append("dBm ");
            if (simData.getPrimaryCell().getSignalNoise() != CellInfo.UNAVAILABLE)
                contentText.append(simData.getPrimaryCell().getSignalNoiseString()).append(": ")
                        .append(simData.getPrimaryCell().getSignalNoise()).append("dBm ");

            if (i == 0)
                contentText.append("\n\n");
        }

        activeNotification = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                .setSmallIcon(android.R.drawable.stat_notify_sync) // got to make an icon as soon as i make an app logo
                .setContentTitle(context.getManager().getFullHeaderString())
                .setContentText(contentText.toString())
                .setContentIntent(openPendingIntent)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setStyle(new NotificationCompat.BigTextStyle())
                .setOngoing(true)
                .setSilent(true)
                .addAction(android.R.drawable.stat_notify_sync, "Close", closingPendingIntent) // same here for the logo
                .setAllowSystemGeneratedContextualActions(false);
    }

    public Notification getActiveNotification() {
        return activeNotification.build();
    }

    public int getSelectedId() {
        return selectedId;
    }
}
