package pw.dotto.netmanager.Speedtest;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;

import io.flutter.plugin.common.MethodChannel;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okio.BufferedSink;

/**
 * NetManager's Speed test client class is the speed test component which
 * currently does pretty much everything for in-app speedtest.
 * This component is heavily WIP and should be considered in an early testing
 * stage.
 * Data may be inaccurate or straight up wrong.
 * The only supported backend at this time is LibreSpeed, an open source Speed
 * test software solution.
 *
 * @author DottoXD
 * @version 0.0.4
 */
public class Client {
    private static final int STREAM_COUNT = 8;
    private static final int BUFFER_SIZE = 256 * 1024;
    private static final int UPLOAD_CHUNK_SIZE = 1024 * 1024;
    private static final int UI_UPDATE_INTERVAL = 300;

    private static final long BATCH_UPDATE_THRESHOLD = 1024 * 1024;

    private static final int LATENCY_MAX_MS = 5000;
    private static final int TRANSFER_MAX_MS = 20000;
    private static final int PING_COUNT = 5;
    private static final int PING_INTERVAL_MS = 50;

    private static final int STABILITY_WINDOW_MS = 3000;
    private static final double STABILITY_THRESHOLD = 0.075;
    private static final int STABILITY_MIN_SAMPLES = 10;

    private final OkHttpClient httpClient = new OkHttpClient.Builder()
            .connectTimeout(5, TimeUnit.SECONDS)
            .readTimeout(10, TimeUnit.SECONDS)
            .writeTimeout(10, TimeUnit.SECONDS)
            .retryOnConnectionFailure(true)
            .build();

    private final ExecutorService executor = Executors.newFixedThreadPool(STREAM_COUNT + 4);
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    public void runSpeedTest(String pingUrl, String downloadUrl, String uploadUrl, MethodChannel channel) {
        executor.execute(() -> {
            try {
                updateUI(channel, "LATENCY", 0);
                LatencyResult latency = measureLatency(pingUrl, channel);

                mainHandler.post(() -> {
                    Map<String, Object> data = new HashMap<>();
                    data.put("ping", latency.avgPing);
                    data.put("jitter", latency.jitter);
                    data.put("packetLoss", latency.packetLoss);
                    channel.invokeMethod("latency", data);
                });

                Thread.sleep(1000);

                updateUI(channel, "DOWNLOAD", 0);
                double dlSpeed = measureDownload(downloadUrl, channel);

                Thread.sleep(1500);

                updateUI(channel, "UPLOAD", 0);
                double ulSpeed = measureUpload(uploadUrl, channel);

                mainHandler.post(() -> {
                    Map<String, Object> res = new HashMap<>();
                    res.put("download", dlSpeed);
                    res.put("upload", ulSpeed);
                    channel.invokeMethod("complete", res);
                });

            } catch (Exception e) {
                // todo
            }
        });
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
            Request request = new Request.Builder().url(pingUrl).head().build();
            long start = System.currentTimeMillis();
            sent++;

            try (Response response = httpClient.newCall(request).execute()) {
                long rtt = System.currentTimeMillis() - start;
                if (response.isSuccessful()) {
                    pings.add(rtt);
                } else {
                    failed++;
                }
            } catch (IOException e) {
                failed++;
            }

            final double progress = (double) sent / PING_COUNT;
            final int currentSent = sent;
            final int currentFailed = failed;
            final List<Long> currentPings = new ArrayList<>(pings);

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
                data.put("packetLoss", (currentFailed * 100.0) / currentSent);
                data.put("progress", progress);
                channel.invokeMethod("latency", data);
            });

            try {
                Thread.sleep(PING_INTERVAL_MS);
            } catch (InterruptedException ignored) {
                // todo
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
        long startTime = System.currentTimeMillis();

        List<Future<?>> futures = new ArrayList<>();
        for (int i = 0; i < STREAM_COUNT; i++) {
            futures.add(executor.submit(() -> {
                Request request = new Request.Builder()
                        .url(downloadUrl + "?ckSize=100")
                        .addHeader("Accept-Encoding", "identity")
                        .build();

                try (Response response = httpClient.newCall(request).execute()) {
                    InputStream is = response.body().byteStream();
                    byte[] buf = new byte[BUFFER_SIZE];
                    int read;
                    long tempBytes = 0;

                    while (running.get() && (read = is.read(buf)) != -1) {
                        tempBytes += read;
                        if (tempBytes >= BATCH_UPDATE_THRESHOLD) {
                            totalBytes.addAndGet(tempBytes);
                            tempBytes = 0;
                        }
                    }

                    totalBytes.addAndGet(tempBytes);
                } catch (Exception ignored) {
                }
            }));
        }

        return monitorProgress(channel, "DOWNLOAD", startTime, totalBytes, running);
    }

    private double measureUpload(String uploadUrl, MethodChannel channel) throws Exception {
        AtomicLong totalBytes = new AtomicLong(0);
        AtomicBoolean running = new AtomicBoolean(true);
        long startTime = System.currentTimeMillis();

        byte[] payload = new byte[UPLOAD_CHUNK_SIZE];
        new Random().nextBytes(payload);

        List<Future<?>> futures = new ArrayList<>();
        for (int i = 0; i < STREAM_COUNT; i++) {
            futures.add(executor.submit(() -> {
                RequestBody requestBody = new RequestBody() {
                    @Override
                    public MediaType contentType() {
                        return MediaType.parse("application/octet-stream");
                    }

                    @Override
                    public void writeTo(@NonNull BufferedSink sink) throws IOException {
                        long tempBytes = 0;

                        while (running.get()) {
                            sink.write(payload);
                            tempBytes += payload.length;
                            if (tempBytes >= BATCH_UPDATE_THRESHOLD) {
                                totalBytes.addAndGet(tempBytes);
                                tempBytes = 0;
                            }
                        }

                        totalBytes.addAndGet(tempBytes);
                    }
                };

                Request request = new Request.Builder().url(uploadUrl).post(requestBody).build();
                try (Response response = httpClient.newCall(request).execute()) {
                } catch (Exception ignored) {
                }
            }));
        }

        return monitorProgress(channel, "UPLOAD", startTime, totalBytes, running);
    }

    private double monitorProgress(MethodChannel channel, String stage, long startTime, AtomicLong totalBytes,
            AtomicBoolean running) throws Exception {
        StabilityTracker stability = new StabilityTracker(STABILITY_WINDOW_MS, STABILITY_MIN_SAMPLES,
                STABILITY_THRESHOLD);
        long lastUpdate = 0;

        while (System.currentTimeMillis() - startTime < TRANSFER_MAX_MS) {
            Thread.sleep(50);
            long now = System.currentTimeMillis();

            if (now - lastUpdate > UI_UPDATE_INTERVAL) {
                double timeSec = (now - startTime) / 1000.0;
                if (timeSec > 0.1) {
                    double speed = (totalBytes.get() * 8.0 / 1_000_000.0) / timeSec;
                    updateUI(channel, stage, speed);
                    stability.record(now, speed);
                    if (stability.isStable())
                        break;
                }
                lastUpdate = now;
            }
        }

        running.set(false);
        double finalTime = (System.currentTimeMillis() - startTime) / 1000.0;
        return (totalBytes.get() * 8.0 / 1_000_000.0) / finalTime;
    }

    private void updateUI(MethodChannel channel, String stage, double speed) {
        mainHandler.post(() -> {
            Map<String, Object> data = new HashMap<>();
            data.put("stage", stage);
            data.put("speed", speed);
            channel.invokeMethod("update", data);
        });
    }
}