package pw.dotto.netmanager.Core.Notifications;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.service.notification.StatusBarNotification;
import android.telephony.CellInfo;

import androidx.core.app.NotificationCompat;

import java.util.Objects;
import java.util.Random;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.GsmCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Utils.Permissions;
import pw.dotto.netmanager.MainActivity;

public class Manager {
    private final Service context;

    private NotificationManager notificationManager;
    private NotificationChannel notificationChannel;
    private NotificationCompat.Builder activeNotification;
    private int selectedId = -1;

    private PendingIntent closingPendingIntent;
    private PendingIntent openPendingIntent;

    public static final String NOTIFICATION_CHANNEL = "netmanager-chn";

    public Manager(Service context) {
        this.context = context;
    }

    public void setupChannel() {
        if (context == null)
            return;

        notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        if (notificationManager == null)
            return;

        notificationChannel = notificationManager.getNotificationChannel(NOTIFICATION_CHANNEL);
        if (notificationChannel == null) {
            notificationChannel = new NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    "NetManager Cell Updates",
                    NotificationManager.IMPORTANCE_LOW);

            notificationChannel.enableVibration(false);
            notificationManager.createNotificationChannel(notificationChannel);
        }

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
        if (!Permissions.check(context) || (notificationManager == null || notificationChannel == null))
            return;

        build();
        if (activeNotification == null)
            return;
        notificationManager.notify(selectedId, activeNotification.build());
    }

    public void cancel() {
        notificationManager.cancel(selectedId);
    }

    public void build() { // to be optimised and refactored
        StringBuilder contentText = new StringBuilder();

        int size = 0;
        for (int i = 0; i < 2; i++) {
            SIMData simData = context.getManager().getSimNetworkData(i);
            if (simData == null || simData.getPrimaryCell() == null)
                continue;

            String nodeStr;

            try {
                long firstPart, secondPart;

                CellData primaryCell = simData.getPrimaryCell();
                if (primaryCell instanceof GsmCellData) {
                    firstPart = Long.parseLong(primaryCell.getCellIdentifier()) / 64;
                    secondPart = Long.parseLong(primaryCell.getCellIdentifier()) % 64;
                } else if (primaryCell instanceof CdmaCellData) {
                    firstPart = Long.parseLong(primaryCell.getCellIdentifier());
                    secondPart = Long.parseLong(primaryCell.getCellIdentifier());
                } else {
                    firstPart = Long.parseLong(primaryCell.getCellIdentifier()) / 256;
                    secondPart = Long.parseLong(primaryCell.getCellIdentifier()) % 256;
                }

                nodeStr = firstPart + "/" + secondPart;
            } catch (Exception ignored) {
                nodeStr = "Unavailable";
            }

            CellData selectedCell = simData.getPrimaryCell();
            if (!(selectedCell instanceof NrCellData)) {
                for (CellData cell : simData.getActiveCells()) {
                    if (cell instanceof NrCellData) {
                        NrCellData nrCell = (NrCellData) cell;
                        if (nrCell.getProcessedSignal() == CellInfo.UNAVAILABLE)
                            continue;

                        selectedCell = nrCell;
                        break;
                    }
                }
            }

            contentText.append("SIM ").append(i + 1).append(" (").append(simData.getMccMnc());

            if (selectedCell.getBasicCellData().getBand() > 0 && selectedCell.getBasicCellData().getFrequency() > 0)
                contentText.append(",");

            if (selectedCell.getBasicCellData().getBand() > 0)
                contentText.append((selectedCell instanceof NrCellData ? " N" : " B"))
                        .append(selectedCell.getBasicCellData().getBand());

            if (selectedCell.getBasicCellData().getFrequency() > 0)
                contentText.append(" ")
                        .append(selectedCell.getBasicCellData().getFrequency())
                        .append("MHz");

            contentText.append(")\n")
                    .append(nodeStr)
                    .append(" (");

            if (selectedCell.getProcessedSignal() == CellInfo.UNAVAILABLE)
                contentText.append("N/A");
            else
                contentText.append(selectedCell.getProcessedSignal())
                        .append("dBm");

            contentText.append(")\n");

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
