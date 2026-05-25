package pw.dotto.netmanager.Recording;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
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
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import pw.dotto.netmanager.Core.Manager;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.Mobile.SimReceiverManager;
import pw.dotto.netmanager.Fetchers.Location;
import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.R;

/**
 * NetManager's Recording Service class is the recording component which
 * coordinates
 * all cell coverage recording actions.
 *
 * @author DottoXD
 * @version 0.0.4
 */
public class Service extends android.app.Service {
    private static Service instance = null;
    private ScheduledExecutorService executorService;

    private Manager core;
    private RecordedData recordedData;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private int selectedSim = 0;

    private Gson gson = new Gson();
    private int selectedId = -1;
    private String path;
    private boolean trackUsable = false;
    private String usabilityTestUrl = "";

    public static final String NOTIFICATION_CHANNEL = "netmanager-rec";
    private static final String DEFAULT_USABILITY_TEST_URL = "https://connectivitycheck.gstatic.com/generate_204";

    private final OkHttpClient httpClient = new OkHttpClient.Builder()
            .connectTimeout(2, TimeUnit.SECONDS)
            .readTimeout(2, TimeUnit.SECONDS)
            .writeTimeout(2, TimeUnit.SECONDS)
            .retryOnConnectionFailure(false)
            .followRedirects(false)
            .followSslRedirects(false)
            .build();

    public static Service getInstance() {
        return instance;
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        core = new Manager(this);
        instance = this;
    }

    public RecordedData getRecordedData() {
        return this.recordedData;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (executorService == null || executorService.isShutdown()) {
            executorService = Executors.newSingleThreadScheduledExecutor();
        }

        String name = intent.getStringExtra("name");
        int intervalSeconds = intent.getIntExtra("interval", 10);
        String path = intent.getStringExtra("path");
        int selectedSim = intent.getIntExtra("selectedSim", 0);
        boolean trackUsable = intent.getBooleanExtra("trackUsable", false);
        String usabilityTestUrl = intent.getStringExtra("usabilityTestUrl");

        if (usabilityTestUrl == null)
            usabilityTestUrl = DEFAULT_USABILITY_TEST_URL;

        this.selectedSim = selectedSim;
        this.path = path + "/" + name;
        this.trackUsable = trackUsable;
        this.usabilityTestUrl = usabilityTestUrl;

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
        executorService.scheduleWithFixedDelay(new Runnable() {
            @Override
            public void run() {
                record();
            }
        }, 0, intervalSeconds, TimeUnit.SECONDS);

        return START_NOT_STICKY;
    }

    private void record() {
        Location locationFetcher = Location.getInstance(this);
        android.location.Location loc = locationFetcher.getLastLocation();
        SIMData data = core.getSimNetworkData(selectedSim);

        if (loc != null && data != null) {
            int gen = data.getNetworkGen();
            if (gen == 4 && core.getNsaStatus(selectedSim))
                gen++;

            int processedSignal;
            if (data.getPrimaryCell() != null) {
                processedSignal = data.getPrimaryCell().getProcessedSignal();
            } else {
                processedSignal = -1;
            }

            boolean isUsable = true;
            if (trackUsable) {
                isUsable = testUsability();
            }

            Record record = new Record(gen, processedSignal, isUsable, loc.getLatitude(), loc.getLongitude());

            synchronized (recordedData) {
                recordedData.addRecord(record);
                saveToFile();
            }
        }
    }

    private void saveToFile() {
        try (FileOutputStream fos = new FileOutputStream(new File(path))) {
            String json = gson.toJson(recordedData);
            fos.write(json.getBytes(StandardCharsets.UTF_8));
        } catch (IOException e) {
            // todo
        }
    }

    private boolean testUsability() {
        ConnectivityManager manager = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        if (manager == null)
            return false;

        Network[] networks = manager.getAllNetworks();

        for (Network network : networks) {
            NetworkCapabilities capabilities = manager.getNetworkCapabilities(network);
            if (capabilities != null && capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) {
                if (capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
                    return ping(network);
                }
            }
        }

        return false;
    }

    private boolean ping(Network network) {
        OkHttpClient betterClient = httpClient;

        if (network != null) {
            betterClient = httpClient.newBuilder().socketFactory(network.getSocketFactory()).build();
        }

        Request request = new Request.Builder().url(usabilityTestUrl).build();

        try (Response response = betterClient.newCall(request).execute()) {
            return response.code() == 204 || response.code() == 200;
        } catch (Exception e) {
            return false;
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        saveToFile();

        instance = null;

        if (core != null) {
            SimReceiverManager simReceiverManager = core.getSimReceiverManager();
            if (simReceiverManager != null)
                simReceiverManager.unregisterStateReceiver();
        }

        if (executorService != null) {
            executorService.shutdown();

            try {
                if (!executorService.awaitTermination(2, TimeUnit.SECONDS)) {
                    executorService.shutdownNow();
                }
            } catch (InterruptedException e) {
                executorService.shutdownNow();
            }
        }

        stopForeground(STOP_FOREGROUND_REMOVE);
    }
}
