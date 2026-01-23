package pw.dotto.netmanager.Core.Notifications;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.service.notification.StatusBarNotification;
import android.telephony.CellInfo;

import androidx.core.app.NotificationCompat;

import java.util.Objects;
import java.util.Random;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.R;
import pw.dotto.netmanager.Utils.Mobile;
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

    public boolean setupChannel() {
        if (context == null)
            return false;

        notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        if (notificationManager == null)
            return false;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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
        }

        if (selectedId < 0)
            selectedId = new Random().nextInt(10);

        Intent closingIntent = new Intent(context, Receiver.class);
        closingIntent.setAction("CLOSE_NOTIFICATION");
        closingIntent.putExtra("id", selectedId);
        closingPendingIntent = PendingIntent.getBroadcast(context, 0, closingIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Intent openIntent = new Intent(context, MainActivity.class);
        openPendingIntent = PendingIntent.getActivity(context, 0, openIntent,
                PendingIntent.FLAG_IMMUTABLE);

        return true;
    }

    public boolean send() {
        activeNotification = build();
        if (activeNotification == null)
            return false;

        if (notificationManager == null || notificationChannel == null)
            return false;

        if (selectedId < 0)
            selectedId = new Random().nextInt(10);
        notificationManager.notify(selectedId, activeNotification.build());

        return true;
    }

    public void cancel() {
        notificationManager.cancel(selectedId);
    }

    public String buildContent() {
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
                firstPart = Long.parseLong(primaryCell.getCellIdentifier()) / Mobile.getFactor(primaryCell);
                secondPart = Long.parseLong(primaryCell.getCellIdentifier()) % Mobile.getFactor(primaryCell);

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

            contentText.append("SIM ").append(i + 1).append(" (").append(simData.getNetworkPlmn());

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

            if (contentText.length() > 0 && contentText.charAt(contentText.length() - 1) == '\n')
                contentText.deleteCharAt(contentText.length() - 1);

            if (i == 0)
                contentText.append("\n\n");

            size++;
        }

        String text = contentText.toString();

        if (text.trim().isBlank()) {
            int subscriptionCount = context.getManager().getSimCount();

            for (int i = 0; i < subscriptionCount; i++) {
                if (i > 0)
                    contentText.append("\n\n");
                contentText.append("SIM ").append(i + 1).append(" (N/A)\nNo service");
            }

            if (subscriptionCount == 0)
                contentText.append("No SIM cards detected");

            text = contentText.toString();
        }

        if (size == 1)
            text = text.replace("\n\n", "");

        return text;
    }

    public NotificationCompat.Builder build() {
        NotificationCompat.Builder notification = null;

        try {
            notification = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                    .setSmallIcon(R.drawable.ic_launcher_monochrome)
                    .setContentTitle(context.getManager().getFullHeaderString())
                    .setContentText(buildContent())
                    .setContentIntent(openPendingIntent)
                    .setPriority(NotificationCompat.PRIORITY_MAX)
                    .setStyle(new NotificationCompat.BigTextStyle())
                    .setOngoing(true)
                    .setSilent(true)
                    .addAction(R.drawable.ic_launcher_monochrome, "Close", closingPendingIntent)
                    .setAllowSystemGeneratedContextualActions(false);
        } catch (Exception e) {
            notification = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                    .setSmallIcon(R.drawable.ic_launcher_monochrome)
                    .setContentTitle("NetManager is loading...")
                    .setContentText("The notification component has failed to load. (" + e.getMessage() + ")")
                    .setPriority(NotificationCompat.PRIORITY_MAX)
                    .setStyle(new NotificationCompat.BigTextStyle())
                    .setOngoing(true)
                    .setSilent(true)
                    .setAllowSystemGeneratedContextualActions(false);
        }

        return notification;
    }

    public Notification buildBootstrapNotification() {
        return new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                .setSmallIcon(R.drawable.ic_launcher_monochrome)
                .setContentTitle("Netmanager is starting...")
                .setContentText("Initialising...")
                .setOngoing(true)
                .setSilent(true)
                .build();
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
