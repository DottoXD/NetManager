package pw.dotto.netmanager.Recording;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.service.notification.StatusBarNotification;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import com.google.gson.Gson;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Random;

import pw.dotto.netmanager.Core.Manager;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.Mobile.SimReceiverManager;
import pw.dotto.netmanager.Fetchers.Location;
import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.R;

/**
 * NetManager's Recording Service class is the recording component which coordinates
 * all cell coverage recording actions.
 *
 * @author DottoXD
 * @version 0.0.4
 */
public class Service extends android.app.Service {
    private SharedPreferences sharedPreferences;
    private Manager core;
    private RecordedData recordedData;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private Runnable runnable;
    private int selectedSim = 0;

    private Gson gson = new Gson();

    private int selectedId = -1;

    public static final String NOTIFICATION_CHANNEL = "netmanager-rec";

    private String path;

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        core = new Manager(this);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String name = intent.getStringExtra("name");
        long intervalSeconds = intent.getLongExtra("interval", 10);
        String path = intent.getStringExtra("path");
        int selectedSim = intent.getIntExtra("selectedSim", 0);

        this.selectedSim = selectedSim;
        this.path = path + "/" + name;

        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel notificationChannel = notificationManager.getNotificationChannel(NOTIFICATION_CHANNEL);
            if (notificationChannel == null) {
                notificationChannel = new NotificationChannel(
                        NOTIFICATION_CHANNEL,
                        "NetManager Recording Service",
                        NotificationManager.IMPORTANCE_MIN);

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

        Intent closingIntent = new Intent(this, Receiver.class);
        closingIntent.setAction("CLOSE_RECORDING_NOTIFICATION");
        closingIntent.putExtra("id", selectedId);
        PendingIntent closingPendingIntent = PendingIntent.getBroadcast(this, 0, closingIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Intent openIntent = new Intent(this, MainActivity.class);
        PendingIntent openPendingIntent = PendingIntent.getActivity(this, 0, openIntent,
                PendingIntent.FLAG_IMMUTABLE);

        Notification notification1 = new NotificationCompat.Builder(this, NOTIFICATION_CHANNEL)
                .setContentTitle("NetManager Recording Service")
                .setContentText("You are currently recording all cell data (" + name + ")")
                .setSmallIcon(R.drawable.ic_launcher_monochrome)
                .setSilent(true)
                .setOngoing(true)
                .setContentIntent(openPendingIntent)
                .addAction(R.drawable.ic_launcher_monochrome, "Close", closingPendingIntent)
                .build();

        startForeground(selectedId, notification1);

        recordedData = new RecordedData(core.getSimOperator(selectedSim), core.getPlmn(selectedSim));

        runnable = new Runnable() {
            @Override
            public void run() {
                record();
                handler.postDelayed(this, intervalSeconds * 1000);
            }
        };
        handler.post(runnable);

        return START_NOT_STICKY;
    }

    private void record() {
        Location locationFetcher = Location.getInstance(this);
        android.location.Location loc = locationFetcher.getLastLocation();
        SIMData data = core.getSimNetworkData(selectedSim);

        if(loc != null && data != null) {
            int gen = data.getNetworkGen();
            if(gen == 4 && core.getNsaStatus(selectedSim)) gen++;

            int processedSignal = -1;
            if(data.getPrimaryCell() != null) {
                processedSignal = data.getPrimaryCell().getProcessedSignal();
            }

            Record record = new Record(gen, processedSignal, true, loc.getLatitude(), loc.getLongitude());
            recordedData.addRecord(record);
            saveToFile();
        }
    }

    private void saveToFile() {
        try (FileOutputStream fos = new FileOutputStream(new File(path))) {
            String json = gson.toJson(recordedData);
            fos.write(json.getBytes(StandardCharsets.UTF_8));
        } catch (IOException e) {
            //todo
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        saveToFile();

        if (core != null) {
            SimReceiverManager simReceiverManager = core.getSimReceiverManager();
            if (simReceiverManager != null)
                simReceiverManager.unregisterStateReceiver();
        }

        if (handler != null && runnable != null)
            handler.removeCallbacks(runnable);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE);
        } else {
            stopForeground(true);
        }
    }
}
