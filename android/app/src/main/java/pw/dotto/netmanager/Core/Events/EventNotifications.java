package pw.dotto.netmanager.Core.Events;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import androidx.core.app.NotificationCompat;

import java.util.Random;

import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.R;

/**
 * NetManager's EventNotifications class coordinates all notification
 * related operations for logged events.
 *
 * @author DottoXD
 * @version 0.1.5
 */
public class EventNotifications {
    private final Context context;

    private NotificationManager notificationManager;
    private NotificationChannel notificationChannel;
    private NotificationCompat.Builder activeNotification;

    private PendingIntent openPendingIntent;

    public static final String NOTIFICATION_CHANNEL = "netmanager-events";

    public EventNotifications(Context context) {
        this.context = context;
    }

    /**
     * Sets up NetManager's notification channel for event notifications.
     *
     * @return Whether the operation was successful.
     */
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
                        "NetManager Event Notifications",
                        NotificationManager.IMPORTANCE_DEFAULT);

                notificationManager.createNotificationChannel(notificationChannel);
            }
        }

        Intent openIntent = new Intent(context, MainActivity.class);
        openPendingIntent = PendingIntent.getActivity(context, 0, openIntent,
                PendingIntent.FLAG_IMMUTABLE);

        return true;
    }

    /**
     * Sends a notification for a given NetManagerEvent.
     *
     * @param event The event to generate a notification for.
     * @return Whether the notification was sent successfully.
     */
    public boolean send(NetManagerEvent event) {
        if (event == null)
            return false;

        activeNotification = build(event);
        if (activeNotification == null)
            return false;

        if (notificationManager == null)
            return false;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && notificationChannel == null)
            return false;

        int notificationId = new Random().nextInt(99) + 1;
        notificationManager.notify(notificationId, activeNotification.build());

        return true;
    }

    /**
     * Builds the actual contents of a NetManager event notification.
     *
     * @param event The event details to format.
     * @return A string containing the notification's formatted content.
     */
    public String buildContent(NetManagerEvent event) {
        StringBuilder contentText = new StringBuilder();

        if (event instanceof MobileNetManagerEvent) {
            MobileNetManagerEvent mobileEvent = (MobileNetManagerEvent) event;
            contentText.append("SIM ").append(mobileEvent.getSimSlot() + 1);

            if (mobileEvent.getNetwork() != null && !mobileEvent.getNetwork().trim().isEmpty()) {
                contentText.append(" (").append(mobileEvent.getNetwork()).append(")");
            }
            contentText.append("\n");
        }

        String oldValue = (event.getOldValue() != null) ? event.getOldValue() : "N/A";
        String newValue = (event.getNewValue() != null) ? event.getNewValue() : "N/A";

        contentText.append(oldValue).append(" → ").append(newValue);

        return contentText.toString();
    }

    /**
     * Builds a full notification body for a cell event.
     *
     * @param event The event.
     * @return A builder for NetManager's event notification.
     */
    public NotificationCompat.Builder build(NetManagerEvent event) {
        NotificationCompat.Builder notification;

        try {
            String title = event.getEventType().name().replace("MOBILE_", "").replace("_", " ");

            notification = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                    .setSmallIcon(R.drawable.ic_launcher_monochrome)
                    .setContentTitle(title)
                    .setContentText(buildContent(event))
                    .setContentIntent(openPendingIntent)
                    .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                    .setStyle(new NotificationCompat.BigTextStyle().bigText(buildContent(event)))
                    .setSilent(true)
                    .setAutoCancel(true);
        } catch (Exception e) {
            notification = new NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                    .setSmallIcon(R.drawable.ic_launcher_monochrome)
                    .setContentTitle("NetManager Event Notifications")
                    .setContentText("An event occurred. (" + e.getMessage() + ")")
                    .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                    .setSilent(true)
                    .setAutoCancel(true);
        }

        return notification;
    }
}