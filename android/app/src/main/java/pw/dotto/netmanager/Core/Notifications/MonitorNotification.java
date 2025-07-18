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

import java.util.Objects;
import java.util.Random;

import pw.dotto.netmanager.Core.MobileInfo.CellDatas.CellData;
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
                    "NetManager Cell Updates", // to be updated
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
        if (activeNotification == null)
            return;
        notificationManager.notify(selectedId, activeNotification.build());
    }

    public void cancel() {
        notificationManager.cancel(selectedId);
    }

    public void buildNotification() {
        StringBuilder contentText = new StringBuilder();

        int size = 0;
        for (int i = 0; i < 2; i++) {
            SIMData simData = context.getManager().getSimNetworkData(i);
            if (simData == null || simData.getPrimaryCell() == null)
                continue;

            String nodeStr;

            try {
                nodeStr = Integer.parseInt(simData.getPrimaryCell().getCellIdentifier()) / 256 + "/"
                        + Integer.parseInt(simData.getPrimaryCell().getCellIdentifier()) % 256;
            } catch (Exception ignored) {
                nodeStr = "Unavailable";
            }

            CellData selectedCell = simData.getPrimaryCell();
            if (!(selectedCell instanceof NrCellData)) {
                for (CellData cell : simData.getActiveCells()) {
                    if (cell instanceof NrCellData) {
                        NrCellData nrCell = (NrCellData) cell;
                        if (nrCell.getProcessedSignal() <= 0 || nrCell.getProcessedSignal() == CellInfo.UNAVAILABLE)
                            continue;

                        selectedCell = nrCell;
                        break;
                    }
                }
            }

            contentText.append("SIM ").append(i + 1).append(" (").append(simData.getMccMnc()).append(", ")
                    .append((selectedCell instanceof NrCellData ? "N" : "B"))
                    .append(selectedCell.getBasicCellData().getBand()).append(" ")
                    .append(selectedCell.getBasicCellData().getFrequency()).append("MHz)\n").append(nodeStr)
                    .append(" (")
                    .append(selectedCell.getProcessedSignal()).append("dBm)\n");

            if (selectedCell.getSignalQuality() != CellInfo.UNAVAILABLE
                    && !Objects.equals(selectedCell.getSignalQualityString().trim(), "-"))
                contentText.append(selectedCell.getSignalQualityString()).append(": ")
                        .append(selectedCell.getSignalQuality()).append("dB ");
            if (selectedCell.getSignalNoise() != CellInfo.UNAVAILABLE
                    && !Objects.equals(selectedCell.getSignalNoiseString().trim(), "-"))
                contentText.append(selectedCell.getSignalNoiseString()).append(": ")
                        .append(selectedCell.getSignalNoise()).append("dB ");

            if (contentText.charAt(contentText.length() - 1) == '\n')
                contentText.deleteCharAt(contentText.length() - 1);

            if (i == 0)
                contentText.append("\n\n");

            size++;
        }

        String text = contentText.toString();

        if (text.trim().isBlank())
            text = "No service";

        if (size == 1)
            text = text.replace("\n\n", "");

        activeNotification = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                .setSmallIcon(android.R.drawable.stat_notify_sync) // got to make an icon as soon as i make an app logo
                .setContentTitle(context.getManager().getFullHeaderString())
                .setContentText(text)
                .setContentIntent(openPendingIntent)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setStyle(new NotificationCompat.BigTextStyle())
                .setOngoing(true)
                .setSilent(true)
                .addAction(android.R.drawable.stat_notify_sync, "Close", closingPendingIntent) // same here for the logo
                .setAllowSystemGeneratedContextualActions(false);
    }

    public Notification getActiveNotification() {
        if (activeNotification == null)
            return null;
        return activeNotification.build();
    }

    public int getSelectedId() {
        return selectedId;
    }
}
