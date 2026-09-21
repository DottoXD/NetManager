package pw.dotto.netmanager.Speedtest;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Type;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.AtomicReference;

import io.flutter.plugin.common.MethodChannel;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Protocol;
import okhttp3.Response;
import okio.BufferedSink;
import pw.dotto.netmanager.Core.Manager;
import pw.dotto.netmanager.Utils.DeviceData;

/**
 * NetManager's Speed test client class is the speed test component which
 * currently does pretty much everything for in-app speed test.
 * The only supported backend at this time is LibreSpeed, an open source Speed
 * test software solution.
 *
 * @author DottoXD
 * @version 0.2.2
 */
public class Client {
    private String USER_AGENT = "NetManager-SpeedTest/Unknown";

    private static final int BUFFER_SIZE = 256 * 1024;
    private static final int UI_UPDATE_INTERVAL = 200;

    private static final long BATCH_UPDATE_THRESHOLD = 1024 * 1024;

    private static final int LATENCY_MAX_MS = 5000;
    private static final int PHASE_MAX_MS = 20000;
    private static final int PHASE_MIN_MS = 4000;
    private static final int PING_COUNT = 5;
    private static final int PING_INTERVAL_MS = 50;
    private static final int DOWNLOAD_GRACE_MS = 1500;
    private static final int UPLOAD_GRACE_MS = 3000;
    private static final int STREAM_START_DELAY_MS = 100;

    private static final int LIBRESPEED_DOWNLOAD_CHUNK_MB = 512;
    private static final int UPLOAD_REQUEST_MB = 20;

    private static final int GLOBAL_PING_INTERVAL_MS = 500;
    private static final int OVERALL_TEST_TIMEOUT_MS = 90000;

    private OkHttpClient httpClient;

    private final int streams = Math.max(2, Math.min(Runtime.getRuntime().availableProcessors(), 8));

    private final ExecutorService executor = Executors.newFixedThreadPool(streams + 2);
    private final ScheduledExecutorService watchdogExecutor = Executors.newSingleThreadScheduledExecutor();
    private final ExecutorService dnsExecutor = Executors.newFixedThreadPool(Math.min(streams, 4));
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private final AtomicLong globalPingsSent = new AtomicLong(0);
    private final AtomicLong globalPingsFailed = new AtomicLong(0);

    private final AtomicBoolean errorReported = new AtomicBoolean(false);
    private final AtomicBoolean isCancelled = new AtomicBoolean(false);

    public void runSpeedTest(Context context, String pingUrl, String downloadUrl, String uploadUrl,
            MethodChannel channel) {
        errorReported.set(false);

        try {
            String version = context.getPackageManager().getPackageInfo(context.getPackageName(), 0).versionName;
            if (version == null)
                version = "0.0.0";
            this.USER_AGENT = this.USER_AGENT.replace("Unknown", version);
        } catch (Exception ignored) {
        }

        ScheduledFuture<?>[] watchdogHolder = new ScheduledFuture<?>[1];
        AtomicReference<Future<?>> testFutureRef = new AtomicReference<>();

        watchdogHolder[0] = watchdogExecutor.schedule(() -> {
            Future<?> testFuture = testFutureRef.get();
            if (testFuture != null && !testFuture.isDone()) {
                testFuture.cancel(true);
                reportError(channel, "Connection timed out.");
            }
        }, OVERALL_TEST_TIMEOUT_MS, TimeUnit.MILLISECONDS);

        testFutureRef.set(executor.submit(() -> {
            ConnectivityManager connectivityManager = (ConnectivityManager) context
                    .getSystemService(Context.CONNECTIVITY_SERVICE);
            AtomicReference<ConnectivityManager.NetworkCallback> callbackRef = new AtomicReference<>();

            try {
                globalPingsSent.set(0);
                globalPingsFailed.set(0);

                updateUI(channel, "LATENCY", 0, 0.0);

                Network mobileNetwork = getMobileNetwork(connectivityManager, callbackRef);
                OkHttpClient.Builder clientBuilder = new OkHttpClient.Builder()
                        .connectTimeout(4, TimeUnit.SECONDS)
                        .readTimeout(8, TimeUnit.SECONDS)
                        .writeTimeout(8, TimeUnit.SECONDS)
                        .retryOnConnectionFailure(false)
                        .protocols(Collections.singletonList(Protocol.HTTP_1_1))
                        .addInterceptor(chain -> {
                            Request original = chain.request();
                            Request withUA = original.newBuilder()
                                    .header("User-Agent", USER_AGENT)
                                    .build();
                            return chain.proceed(withUA);
                        });

                if (mobileNetwork != null) {
                    clientBuilder.socketFactory(mobileNetwork.getSocketFactory());
                    clientBuilder.dns(hostname -> {
                        if (dnsExecutor.isShutdown()) {
                            throw new UnknownHostException("DNS executor is shut down for " + hostname);
                        }
                        try {
                            Future<List<InetAddress>> lookup = dnsExecutor.submit(
                                    () -> Arrays.asList(mobileNetwork.getAllByName(hostname)));
                            try {
                                return lookup.get(4, TimeUnit.SECONDS);
                            } catch (Exception e) {
                                lookup.cancel(true);
                                throw new UnknownHostException("DNS lookup timed out for " + hostname);
                            }
                        } catch (RejectedExecutionException e) {
                            throw new UnknownHostException("DNS lookup rejected for " + hostname);
                        }
                    });
                }

                this.httpClient = clientBuilder.build();

                LatencyResult latency = measureLatency(pingUrl, channel);

                if (channel != null) {
                    mainHandler.post(() -> {
                        Map<String, Object> data = new HashMap<>();
                        data.put("ping", latency.avgPing);
                        data.put("jitter", latency.jitter);
                        data.put("packetLoss", latency.packetLoss);
                        channel.invokeMethod("latency", data);
                    });
                }

                Thread.sleep(1000);

                AtomicBoolean transitActive = new AtomicBoolean(true);
                trackPacketLoss(pingUrl, transitActive);

                updateUI(channel, "DOWNLOAD", 0, 0.0);
                double dlSpeed = measureDownload(downloadUrl, channel);

                Thread.sleep(1500);

                updateUI(channel, "UPLOAD", 0, 0.0);
                double ulSpeed = measureUpload(uploadUrl, channel);

                Thread.sleep(1000);

                transitActive.set(false);

                if (channel != null) {
                    mainHandler.post(() -> {
                        Map<String, Object> res = new HashMap<>();
                        res.put("download", dlSpeed);
                        res.put("upload", ulSpeed);
                        res.put("packetLoss", getPacketLoss());
                        channel.invokeMethod("complete", res);
                    });
                } else {
                    String serverName = pingUrl.replace("https://", "").split("/")[0];
                    saveScheduledResultToPrefs(context, latency.avgPing, latency.jitter, getPacketLoss(), dlSpeed,
                            ulSpeed, serverName);
                }
            } catch (Exception e) {
                if (!isCancelled.get()) {
                    String message = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
                    reportError(channel, message);
                }
            } finally {
                if (watchdogHolder[0] != null) {
                    watchdogHolder[0].cancel(false);
                }

                ConnectivityManager.NetworkCallback registeredCallback = callbackRef.get();
                if (connectivityManager != null && registeredCallback != null) {
                    try {
                        connectivityManager.unregisterNetworkCallback(registeredCallback);
                    } catch (Exception ignored) {
                    }
                }

                shutdown();
            }
        }));
    }

    private LatencyResult measureLatency(String pingUrl, MethodChannel channel) {
        List<Long> pings = new ArrayList<>();
        int sent = 0;
        int failed = 0;
        long startTime = System.currentTimeMillis();

        // Warmup!!
        try (Response response = httpClient.newCall(new Request.Builder().url(pingUrl).head().build()).execute()) {
        } catch (Exception ignored) {
        }

        while (sent < PING_COUNT && (System.currentTimeMillis() - startTime) < LATENCY_MAX_MS) {
            String currentPingUrl = pingUrl.contains("empty")
                    ? pingUrl + (pingUrl.contains("?") ? "&n=" : "?n=") + System.nanoTime()
                    : pingUrl;

            Request request = new Request.Builder().url(currentPingUrl).head().build();
            long start = System.currentTimeMillis();
            sent++;
            globalPingsSent.incrementAndGet();

            try (Response response = httpClient.newCall(request).execute()) {
                long rtt = System.currentTimeMillis() - start;
                if (response.code() != 0) {
                    pings.add(rtt);
                } else {
                    failed++;
                    globalPingsFailed.incrementAndGet();
                }
            } catch (IOException e) {
                failed++;
                globalPingsFailed.incrementAndGet();
            }

            final double progress = (double) sent / PING_COUNT;
            final List<Long> currentPings = new ArrayList<>(pings);

            if (channel != null) {
                mainHandler.post(() -> {
                    Map<String, Object> data = new HashMap<>();

                    long sum = 0;
                    for (long tempPings : currentPings)
                        sum += tempPings;

                    int avg = currentPings.isEmpty() ? 0 : (int) (sum / currentPings.size());

                    long jitterSum = 0;
                    for (int i = 1; i < currentPings.size(); i++)
                        jitterSum += Math.abs(currentPings.get(i) - currentPings.get(i - 1));
                    int jitter = currentPings.size() > 1 ? (int) (jitterSum / (currentPings.size() - 1)) : 0;

                    data.put("ping", avg);
                    data.put("jitter", jitter);
                    data.put("packetLoss", getPacketLoss());
                    data.put("progress", progress);
                    channel.invokeMethod("latency", data);
                });
            }

            try {
                Thread.sleep(PING_INTERVAL_MS);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Speed test cancelled: " + e.getMessage());
            }
        }

        LatencyResult result = new LatencyResult();
        long finalSum = 0;
        for (long p : pings)
            finalSum += p;

        result.avgPing = pings.isEmpty() ? 0 : (int) (finalSum / pings.size());

        long finalJitterSum = 0;
        for (int i = 1; i < pings.size(); i++)
            finalJitterSum += Math.abs(pings.get(i) - pings.get(i - 1));
        result.jitter = pings.size() > 1 ? (int) (finalJitterSum / (pings.size() - 1)) : 0;

        result.packetLoss = (failed * 100.0) / sent;

        return result;
    }

    private double measureDownload(String downloadUrl, MethodChannel channel) throws Exception {
        AtomicLong totalBytes = new AtomicLong(0);
        AtomicBoolean running = new AtomicBoolean(true);
        List<Future<?>> futures = new ArrayList<>();

        try {
            for (int i = 0; i < streams; i++) {
                if (executor.isShutdown())
                    break;
                try {
                    futures.add(executor.submit(() -> {
                        String finalDownloadUrl = buildDownloadUrl(downloadUrl);
                        Request request = new Request.Builder()
                                .url(finalDownloadUrl)
                                .addHeader("Accept-Encoding", "identity")
                                .build();

                        byte[] buf = new byte[BUFFER_SIZE];

                        while (running.get()) {
                            if (isOpenSpeedTestDownload(downloadUrl)) {
                                request = new Request.Builder()
                                        .url(finalDownloadUrl + (finalDownloadUrl.contains("?") ? "&n=" : "?n=")
                                                + System.nanoTime())
                                        .addHeader("Accept-Encoding", "identity")
                                        .build();
                            }

                            try (Response response = httpClient.newCall(request).execute()) {
                                if (!response.isSuccessful() || response.body() == null) {
                                    throw new IOException(
                                            "Download request failed with HTTP status code " + response.code() + ".");
                                }

                                InputStream is = response.body().byteStream();

                                int read;
                                long tempBytes = 0;

                                try {
                                    while (running.get() && (read = is.read(buf)) != -1) {
                                        tempBytes += read;
                                        if (tempBytes >= BATCH_UPDATE_THRESHOLD) {
                                            totalBytes.addAndGet(tempBytes);
                                            tempBytes = 0;
                                        }
                                    }
                                } finally {
                                    if (tempBytes > 0)
                                        totalBytes.addAndGet(tempBytes);
                                }
                            } catch (Exception ignored) {
                                try {
                                    Thread.sleep(100);
                                } catch (InterruptedException e) {
                                    Thread.currentThread().interrupt();
                                    return;
                                }
                            }
                        }
                    }));
                } catch (RejectedExecutionException ignored) {
                    break;
                }

                if (i + 1 < streams)
                    Thread.sleep(STREAM_START_DELAY_MS);
            }

            return monitorProgress(channel, "DOWNLOAD", totalBytes, running, DOWNLOAD_GRACE_MS);
        } finally {
            running.set(false);

            for (Future<?> f : futures) {
                f.cancel(true);
            }
        }
    }

    private String buildDownloadUrl(String downloadUrl) {
        String lowerUrl = downloadUrl.toLowerCase();
        if (lowerUrl.contains("garbage.php")) {
            return downloadUrl + (downloadUrl.contains("?") ? "&ckSize=" : "?ckSize=")
                    + LIBRESPEED_DOWNLOAD_CHUNK_MB;
        }

        if (lowerUrl.contains("getspeed")) {
            return downloadUrl + (downloadUrl.contains("?") ? "&ckSize=" : "?ckSize=") + 100;
        }

        return downloadUrl;
    }

    private boolean isOpenSpeedTestDownload(String downloadUrl) {
        return downloadUrl.toLowerCase().contains("downloading");
    }

    private double measureUpload(String uploadUrl, MethodChannel channel) throws Exception {
        AtomicLong totalBytes = new AtomicLong(0);
        AtomicBoolean running = new AtomicBoolean(true);
        byte[] payload = new byte[1024 * 1024];
        new Random().nextBytes(payload);
        final int requestSize = LIBRESPEED_UPLOAD_REQUEST_MB * 1024 * 1024;

        RequestBody requestBody = new RequestBody() {
            @Override
            public MediaType contentType() {
                return MediaType.parse("application/octet-stream");
            }

            @Override
            public long contentLength() {
                return requestSize;
            }

            @Override
            public void writeTo(@NonNull BufferedSink sink) throws IOException {
                long remaining = requestSize;
                long tempBytes = 0;

                while (remaining > 0) {
                    int writeSize = (int) Math.min(payload.length, remaining);
                    sink.write(payload, 0, writeSize);
                    remaining -= writeSize;
                    tempBytes += writeSize;

                    if (tempBytes >= BATCH_UPDATE_THRESHOLD) {
                        totalBytes.addAndGet(tempBytes);
                        tempBytes = 0;
                    }
                }

                if (tempBytes > 0)
                    totalBytes.addAndGet(tempBytes);
            }
        };

        List<Future<?>> futures = new ArrayList<>();

        try {
            for (int i = 0; i < streams; i++) {
                if (executor.isShutdown())
                    break;
                try {
                    futures.add(executor.submit(() -> {
                        while (running.get()) {
                            String finalUploadUrl = uploadUrl;
                            if (!uploadUrl.toLowerCase().contains("upload.php")) {
                                finalUploadUrl += (uploadUrl.contains("?") ? "&n=" : "?n=") + System.nanoTime();
                            }

                            Request request = new Request.Builder()
                                    .url(finalUploadUrl)
                                    .header("Content-Encoding", "identity")
                                    .post(requestBody)
                                    .build();

                            try (Response response = httpClient.newCall(request).execute()) {
                                if (!response.isSuccessful()) {
                                    throw new IOException(
                                            "Upload request failed with HTTP status code " + response.code() + ".");
                                }
                            } catch (Exception ignored) {
                                if (Thread.currentThread().isInterrupted())
                                    return;
                                try {
                                    Thread.sleep(100);
                                } catch (InterruptedException e) {
                                    Thread.currentThread().interrupt();
                                    return;
                                }
                            }
                        }
                    }));
                } catch (RejectedExecutionException ignored) {
                    break;
                }

                if (i + 1 < streams)
                    Thread.sleep(STREAM_START_DELAY_MS);
            }

            return monitorProgress(channel, "UPLOAD", totalBytes, running, UPLOAD_GRACE_MS);
        } finally {
            running.set(false);

            for (Future<?> f : futures) {
                f.cancel(true);
            }
        }
    }

    private double monitorProgress(MethodChannel channel, String stage, AtomicLong totalBytes,
            AtomicBoolean running, long graceMs) throws Exception {
        long testStartNs = System.nanoTime();
        long measurementStartNs = testStartNs;
        long baselineBytes = 0;
        long lastUpdateNs = 0;
        double timeBonusMs = 0.0;
        boolean graceTimeDone = false;

        while (running.get()) {
            long nowNs = System.nanoTime();

            if (!graceTimeDone && nowNs - testStartNs >= TimeUnit.MILLISECONDS.toNanos(graceMs)) {
                long bytesAtGraceEnd = totalBytes.get();

                if (bytesAtGraceEnd > 0) {
                    baselineBytes = bytesAtGraceEnd;
                    measurementStartNs = nowNs;
                }

                timeBonusMs = 0.0;
                graceTimeDone = true;
                lastUpdateNs = nowNs;
            }

            if (!graceTimeDone) {
                Thread.sleep(20);
                continue;
            }

            long elapsedNs = nowNs - measurementStartNs;
            long elapsedMs = TimeUnit.NANOSECONDS.toMillis(elapsedNs);

            if (nowNs - lastUpdateNs >= TimeUnit.MILLISECONDS.toNanos(UI_UPDATE_INTERVAL)) {
                long measuredBytes = Math.max(0L, totalBytes.get() - baselineBytes);
                double timeSec = elapsedNs / 1_000_000_000.0;
                double speed = timeSec > 0.0
                        ? (measuredBytes * 8.0 / 1_000_000.0) / timeSec
                        : 0.0;

                double bytesPerSecond = timeSec > 0.0
                        ? measuredBytes / timeSec
                        : 0.0;
                double bonus = Math.min(400.0, (5.0 * bytesPerSecond) / 100_000.0);
                timeBonusMs += bonus;

                double progress = Math.min(1.0, (elapsedMs + timeBonusMs) / PHASE_MAX_MS);
                updateUI(channel, stage, speed, progress);
                lastUpdateNs = nowNs;

                if (elapsedMs >= PHASE_MIN_MS && elapsedMs + timeBonusMs >= PHASE_MAX_MS)
                    break;
            }

            Thread.sleep(20);
        }

        long finalEndBytes = totalBytes.get();
        long finalEndNs = System.nanoTime();
        running.set(false);

        long finalElapsedNs = Math.max(1L, finalEndNs - measurementStartNs);
        long finalBytes = Math.max(0L, finalEndBytes - baselineBytes);
        double finalSeconds = finalElapsedNs / 1_000_000_000.0;
        double finalSpeed = (finalBytes * 8.0 / 1_000_000.0) / finalSeconds;

        updateUI(channel, stage, finalSpeed, 1.0);

        return finalSpeed;
    }

    private void trackPacketLoss(String pingUrl, AtomicBoolean isTrackerActive) {
        if (executor.isShutdown())
            return;
        try {
            executor.execute(() -> {
                while (isTrackerActive.get()) {
                    Request request = new Request.Builder().url(pingUrl.contains("empty")
                            ? pingUrl + (pingUrl.contains("?") ? "&n=" : "?n=") + System.nanoTime()
                            : pingUrl).head().build();
                    globalPingsSent.incrementAndGet();
                    try (Response response = httpClient.newCall(request).execute()) {
                        if (response.code() == 0) {
                            globalPingsFailed.incrementAndGet();
                        }
                    } catch (IOException e) {
                        globalPingsFailed.incrementAndGet();
                    }

                    try {
                        Thread.sleep(GLOBAL_PING_INTERVAL_MS);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
            });
        } catch (RejectedExecutionException ignored) {
        }
    }

    private double getPacketLoss() {
        long sent = globalPingsSent.get();
        if (sent == 0)
            return 0.0;
        return (globalPingsFailed.get() * 100.0) / sent;
    }

    private void updateUI(MethodChannel channel, String stage, double speed, double progress) {
        if (isCancelled.get() || channel == null)
            return;

        mainHandler.post(() -> {
            if (isCancelled.get())
                return;

            Map<String, Object> data = new HashMap<>();
            data.put("stage", stage);
            data.put("speed", speed);
            data.put("progress", progress);
            data.put("packetLoss", getPacketLoss());
            channel.invokeMethod("update", data);
        });
    }

    private Network getMobileNetwork(ConnectivityManager connectivityManager,
            AtomicReference<ConnectivityManager.NetworkCallback> callbackOut) {
        if (connectivityManager == null)
            return null;

        final Network[] selectedNetwork = new Network[1];
        final CountDownLatch latch = new CountDownLatch(1);

        NetworkRequest request = new NetworkRequest.Builder()
                .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                .addTransportType(NetworkCapabilities.TRANSPORT_CELLULAR)
                .build();

        ConnectivityManager.NetworkCallback callback = new ConnectivityManager.NetworkCallback() {
            @Override
            public void onAvailable(@NonNull Network network) {
                selectedNetwork[0] = network;
                latch.countDown();
            }

            @Override
            public void onUnavailable() {
                latch.countDown();
            }
        };

        callbackOut.set(callback);
        try {
            connectivityManager.requestNetwork(request, callback);
            latch.await(5, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        return selectedNetwork[0];
    }

    private void saveScheduledResultToPrefs(Context context, int ping, int jitter, double packetLoss, double download,
            double upload, String serverName) {
        SharedPreferences prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        String existingJson = prefs.getString("flutter.pendingSpeedtests", "[]");

        Gson gson = new Gson();
        Type listType = new TypeToken<List<Map<String, Object>>>() {
        }.getType();
        List<Map<String, Object>> pendingList = gson.fromJson(existingJson, listType);

        if (pendingList == null) {
            pendingList = new ArrayList<>();
        }

        Manager manager = new Manager(context, "speedtest", 5);
        int simId = 0;

        if (manager.getSimCount() > 1) {
            if (!manager.isActiveDataSubscription(simId))
                simId = 1;
        }

        String carrier = manager.getSimCarrier(simId);
        String plmn = manager.getPlmn(simId);
        int gen = manager.getSimNetworkGen(simId);
        if (manager.getNsaStatus(simId))
            gen = 5;

        manager.dispose();

        Map<String, Object> result = new HashMap<>();
        result.put("timestamp", System.currentTimeMillis());
        result.put("download", download);
        result.put("upload", upload);
        result.put("ping", ping);
        result.put("jitter", jitter);
        result.put("packetLoss", packetLoss);
        result.put("carrier", carrier);
        result.put("plmn", plmn);
        result.put("networkGen", gen);
        result.put("serverName", serverName);
        result.put("deviceModel", DeviceData.getInstance(null).getModel());

        pendingList.add(result);

        prefs.edit().putString("flutter.pendingSpeedtests", gson.toJson(pendingList)).apply();
    }

    private void reportError(MethodChannel channel, String message) {
        if (isCancelled.get() || channel == null)
            return;

        if (errorReported.compareAndSet(false, true)) {
            mainHandler.post(() -> channel.invokeMethod("error", message));
        }
    }

    public void stopTest() {
        isCancelled.set(true);
        shutdown();
    }

    public void shutdown() {
        if (httpClient != null) {
            httpClient.dispatcher().cancelAll();
        }

        executor.shutdown();
        watchdogExecutor.shutdown();
        dnsExecutor.shutdown();

        new Thread(() -> {
            try {
                if (!executor.awaitTermination(2, TimeUnit.SECONDS)) {
                    executor.shutdownNow();
                }

                if (!watchdogExecutor.awaitTermination(2, TimeUnit.SECONDS)) {
                    watchdogExecutor.shutdownNow();
                }

                if (!dnsExecutor.awaitTermination(2, TimeUnit.SECONDS)) {
                    dnsExecutor.shutdownNow();
                }
            } catch (InterruptedException e) {
                executor.shutdownNow();
                dnsExecutor.shutdownNow();
                watchdogExecutor.shutdownNow();
                Thread.currentThread().interrupt();
            }
        }).start();
    }
}