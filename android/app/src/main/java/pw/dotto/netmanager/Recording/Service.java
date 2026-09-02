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
import android.os.IBinder;
import android.service.notification.StatusBarNotification;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import com.google.gson.Gson;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import io.sentry.Sentry;
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
 * coordinates all cell coverage recording actions.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class Service extends android.app.Service {
    private String USER_AGENT = "NetManager-DriveTest/Unknown";
    private static final int DEFAULT_RECORDING_INTERVAL_SECONDS = 10;

    private static Service instance = null;
    private ScheduledExecutorService executorService;

    private Manager core;

    private final Map<Integer, RecordedData> recordedDataMap = new ConcurrentHashMap<>();
    private final Map<Integer, String> pathMap = new ConcurrentHashMap<>();
    private final List<Integer> activeSimSlots = new ArrayList<>();

    private final Object recordedDataLock = new Object();
    private int selectedSim = 0;

    private final Gson gson = new Gson();
    private int selectedId = -1;
    private boolean trackUsable = false;
    private String usabilityTestUrl = "";

    public static final String NOTIFICATION_CHANNEL = "netmanager-rec";
    private static final String DEFAULT_USABILITY_TEST_URL = "https://connectivitycheck.grapheneos.network/generate_204";

    private final OkHttpClient httpClient = new OkHttpClient.Builder()
            .connectTimeout(2, TimeUnit.SECONDS)
            .readTimeout(2, TimeUnit.SECONDS)
            .writeTimeout(2, TimeUnit.SECONDS)
            .retryOnConnectionFailure(false)
            .followRedirects(false)
            .followSslRedirects(false)
            .addInterceptor(chain -> {
                Request original = chain.request();
                Request withUA = original.newBuilder()
                        .header("User-Agent", USER_AGENT)
                        .build();
                return chain.proceed(withUA);
            })
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
        instance = this;

        try {
            startForeground();
            core = new Manager(this, "recording", DEFAULT_RECORDING_INTERVAL_SECONDS);
            Location.getInstance(this);
        } catch (Exception e) {
            stopSelf();
        }
    }

    public RecordedData getRecordedData() {
        return recordedDataMap.get(selectedSim);
    }

    public RecordedData getRecordedData(int simSlot) {
        return recordedDataMap.get(simSlot);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) {
            stopSelf();
            return START_NOT_STICKY;
        }

        if (executorService == null || executorService.isShutdown()) {
            executorService = Executors.newSingleThreadScheduledExecutor();
        }

        if (!recordedDataMap.isEmpty()) {
            return START_NOT_STICKY;
        }

        String name = intent.getStringExtra("name");
        int intervalSeconds = intent.getIntExtra("interval", DEFAULT_RECORDING_INTERVAL_SECONDS);
        String basePath = intent.getStringExtra("path");
        int selectedSim = intent.getIntExtra("selectedSim", 0);
        boolean dualSimMode = intent.getBooleanExtra("dualSimMode", false);
        boolean trackUsable = intent.getBooleanExtra("trackUsable", false);
        String usabilityTestUrl = intent.getStringExtra("usabilityTestUrl");

        if (core != null)
            core.updateInterval(intervalSeconds);

        if (usabilityTestUrl == null)
            usabilityTestUrl = DEFAULT_USABILITY_TEST_URL;

        this.selectedSim = selectedSim;
        this.trackUsable = trackUsable;
        this.usabilityTestUrl = usabilityTestUrl;

        activeSimSlots.clear();
        activeSimSlots.add(selectedSim);
        if (dualSimMode && core != null && core.getSimCount() > 1) {
            activeSimSlots.add(selectedSim == 0 ? 1 : 0);
        }

        pathMap.clear();
        recordedDataMap.clear();
        for (int simSlot : activeSimSlots) {
            String suffix = dualSimMode ? "_SIM" + (simSlot + 1) : "";
            String fullPath = basePath + "/" + name + suffix + ".nmr";

            pathMap.put(simSlot, fullPath);
            recordedDataMap.put(simSlot, new RecordedData(core.getSimOperator(simSlot), core.getPlmn(simSlot)));
        }

        Intent closingIntent = new Intent(this, Receiver.class);
        closingIntent.setAction("CLOSE_RECORDING_NOTIFICATION");
        closingIntent.putExtra("id", selectedId);
        PendingIntent closingPendingIntent = PendingIntent.getBroadcast(this, 0, closingIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        Intent openIntent = new Intent(this, MainActivity.class);
        PendingIntent openPendingIntent = PendingIntent.getActivity(this, 0, openIntent,
                PendingIntent.FLAG_IMMUTABLE);

        String notificationMessage = dualSimMode
                ? "You are currently recording all Dual SIM cell data (" + name + ")"
                : "You are currently recording all cell data (" + name + ")";

        Notification recordingNotification = new NotificationCompat.Builder(this, NOTIFICATION_CHANNEL)
                .setContentTitle("NetManager Recording Service")
                .setContentText(notificationMessage)
                .setSmallIcon(R.drawable.ic_launcher_monochrome)
                .setSilent(true)
                .setOngoing(true)
                .setContentIntent(openPendingIntent)
                .addAction(R.drawable.ic_launcher_monochrome, "Close", closingPendingIntent)
                .build();

        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (notificationManager != null) {
            notificationManager.notify(selectedId, recordingNotification);
        }

        try {
            executorService.scheduleWithFixedDelay(this::record, 0, intervalSeconds, TimeUnit.SECONDS);
        } catch (Exception e) {
            stopSelf();
        }

        return START_NOT_STICKY;
    }

    private void record() {
        Location locationFetcher = Location.getInstance(this);
        if (locationFetcher == null) {
            return;
        }

        android.location.Location loc = locationFetcher.getLastLocation();
        if (loc == null) {
            return;
        }

        boolean isUsable = true;
        if (trackUsable) {
            isUsable = testUsability();
        }

        for (int simSlot : activeSimSlots) {
            SIMData data = core.getSimNetworkData(simSlot);

            if (data == null) {
                continue;
            }

            Record record = new Record(isUsable, loc.getLatitude(), loc.getLongitude(), data);

            synchronized (recordedDataLock) {
                RecordedData targetData = recordedDataMap.get(simSlot);
                if (targetData != null) {
                    targetData.addRecord(record);
                    saveToFile(simSlot);
                }
            }
        }
    }

    private void startForeground() {
        NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (notificationManager == null)
            return;

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
            selectedId = new Random().nextInt(9) + 1;

        Notification notification = new NotificationCompat.Builder(this, NOTIFICATION_CHANNEL)
                .setContentTitle("NetManager Recording Service")
                .setContentText("Initializing...")
                .setSmallIcon(R.drawable.ic_launcher_monochrome)
                .setSilent(true)
                .setOngoing(true)
                .build();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(selectedId, notification, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION);
        } else {
            startForeground(selectedId, notification);
        }
    }

    private void saveToFile(int simSlot) {
        String filePath = pathMap.get(simSlot);
        RecordedData recData = recordedDataMap.get(simSlot);
        if (filePath == null || recData == null)
            return;

        synchronized (recordedDataLock) {
            try (FileOutputStream fos = new FileOutputStream(new File(filePath))) {
                String json = gson.toJson(recData);
                fos.write(json.getBytes(StandardCharsets.UTF_8));
            } catch (IOException e) {
                Sentry.captureException(e, scope -> scope.setExtra("feature", "Service saveToFile SIM" + simSlot));
            }
        }
    }

    private void saveAllFiles() {
        for (int simSlot : activeSimSlots) {
            saveToFile(simSlot);
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
        saveAllFiles();

        instance = null;

        Location locationFetcher = Location.getInstance(this);
        if (locationFetcher != null) {
            locationFetcher.dispose();
        }

        if (core != null) {
            SimReceiverManager simReceiverManager = core.getSimReceiverManager();
            if (simReceiverManager != null)
                simReceiverManager.unregisterStateReceiver();

            core.dispose();
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
        super.onDestroy();
    }
}
