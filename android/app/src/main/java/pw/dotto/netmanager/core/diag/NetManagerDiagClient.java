package pw.dotto.netmanager.core.diag;

import android.content.Context;
import android.net.LocalSocket;
import android.net.LocalSocketAddress;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonSyntaxException;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import pw.dotto.netmanager.utils.DebugLogger;

/**
 * NetManager's NetManagerDiagClient is the advanced diag component which owns
 * the connection to the NetManagerDiag root daemon (NetManagerDiag on GitHub) a
 * LocalSocket, a background reader and a listener mechanism used to forward
 * decoded events to Flutter's advanced-mode screens.
 *
 * This class doesn't use SIMData/CellData: it passes diag events as they are
 * and lets consumers interpret them.
 *
 * @author DottoXD
 * @version 0.2.3
 */
public class NetManagerDiagClient {
    private static final String SOCKET_NAME = "NetManagerDiag";
    private static final String BINARY_NAME = "libNetManagerDiag.so";
    private static final int CONNECT_RETRIES = 50;
    private static final long CONNECT_RETRY_DELAY_MS = 100;

    private static volatile NetManagerDiagClient instance;

    private final Context appContext;
    private final Gson gson = new Gson();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private final Object socketLock = new Object();
    private LocalSocket socket;
    private OutputStream socketOut;
    private Thread readerThread;
    private final AtomicBoolean connected = new AtomicBoolean(false);
    private final AtomicBoolean starting = new AtomicBoolean(false);

    private volatile long connectStartMs;
    private volatile boolean loggedConnectedStatus;
    private volatile boolean loggedFirstEvent;

    private final Map<String, Set<String>> featuresByOwner = new HashMap<>();
    private String lastSentEnable;
    private volatile StatusMessage lastStatus;

    private volatile NrMeasurementsEvent lastNrMeasurements;

    private final CopyOnWriteArrayList<Listener> listeners = new CopyOnWriteArrayList<>();

    public interface Listener {
        void onStatus(StatusMessage status);

        void onLteServingMeas(LteServingMeasEvent event);

        void onLteCellInfo(LteCellInfoEvent event);

        void onNrMeasurements(NrMeasurementsEvent event);

        void onError(String message);

        void onDisconnected();
    }

    public static class StatusMessage {
        public boolean connected;
        public String vendor;
        public String transport;
        public List<String> supported;
        public List<String> active;
        public List<Integer> slots_seen;
    }

    public static class LteServingMeasEvent {
        public String event;
        public Integer slot;
        public int earfcn;
        public int pci;
        public double rsrp_dbm;
        public double rsrq_db;
        public double rssi_dbm;
    }

    public static class LteCellInfoEvent {
        public String event;
        public Integer slot;
        public int earfcn;
        public int pci;
        public Double dl_bandwidth_mhz;
    }

    public static class NrLayerJson {
        public int nr_arfcn;
        public Integer serving_pci;
        public Integer serving_ssb;
        public List<Double> serving_rsrp_dbm;
        public int num_cells;
    }

    public static class NrMeasurementsEvent {
        public String event;
        public Integer slot;
        public List<NrLayerJson> layers;
    }

    private NetManagerDiagClient(Context context) {
        this.appContext = context.getApplicationContext();
    }

    public static NetManagerDiagClient getInstance(Context context) {
        if (instance == null) {
            synchronized (NetManagerDiagClient.class) {
                if (instance == null)
                    instance = new NetManagerDiagClient(context);
            }
        }

        return instance;
    }

    public static NetManagerDiagClient getInstanceIfCreated() {
        return instance;
    }

    public void addListener(Listener listener) {
        listeners.add(listener);
    }

    public void removeListener(Listener listener) {
        listeners.remove(listener);
    }

    public boolean isConnected() {
        return connected.get();
    }

    public StatusMessage getLastStatus() {
        return lastStatus;
    }

    public NrMeasurementsEvent getLastNrMeasurements() {
        return lastNrMeasurements;
    }

    public void connect() {
        if (connected.get() || !starting.compareAndSet(false, true))
            return;

        new Thread(this::connectBlocking, "NetManagerDiagConnect").start();
    }

    private void logEvent(String action) {
        DebugLogger.add("NetManagerDiag timeline: " + (SystemClock.elapsedRealtime() - connectStartMs) + "ms for '"
                + action + "'.");
    }

    private void connectBlocking() {
        try {
            connectStartMs = SystemClock.elapsedRealtime();
            loggedConnectedStatus = false;
            loggedFirstEvent = false;

            LocalSocket s = tryConnect();
            if (s == null) {
                logEvent("NetManagerDiag daemon is not running, launching...");
                launchDaemon();
                logEvent("NetManagerDiag daemon has been launched!");

                for (int i = 0; i < CONNECT_RETRIES && s == null; i++) {
                    sleepQuietly(CONNECT_RETRY_DELAY_MS);
                    s = tryConnect();
                }
            } else {
                logEvent("NetManagerDiag daemon found to be already running!");
            }

            if (s == null) {
                DebugLogger.add("NetManagerDiag: could not connect after launching the daemon.");
                return;
            }

            synchronized (socketLock) {
                socket = s;

                try {
                    socketOut = s.getOutputStream();
                } catch (IOException e) {
                    DebugLogger.add("NetManagerDiag: failed to get output stream: " + e.getMessage() + ".");
                    closeQuietly(s);
                    socket = null;
                    socketOut = null;

                    return;
                }
            }

            connected.set(true);
            logEvent("Socket has connected to NetManagerDiag!");

            readerThread = new Thread(this::readLoop, "NetManagerDiagReader");
            readerThread.setDaemon(true);
            readerThread.start();

            synchronized (this) {
                lastSentEnable = null;
            }

            sendEnableRequest();
        } finally {
            starting.set(false);
        }
    }

    private LocalSocket tryConnect() {
        try {
            LocalSocket s = new LocalSocket();
            s.connect(new LocalSocketAddress(SOCKET_NAME, LocalSocketAddress.Namespace.ABSTRACT));

            return s;
        } catch (IOException e) {
            return null;
        }
    }

    private void launchDaemon() {
        String binaryPath;

        try {
            binaryPath = extractBinary().getAbsolutePath();
        } catch (IOException e) {
            DebugLogger.add("NetManagerDiag: failed to extract binary: " + e.getMessage() + ".");
            return;
        }

        try {
            ProcessBuilder pb = new ProcessBuilder("su", "-c",
                    "setsid " + binaryPath + " serve > /dev/null 2>&1 < /dev/null &");
            pb.redirectErrorStream(true);
            Process p = pb.start();
            p.waitFor();

            DebugLogger.add("NetManagerDiag: launch requested (" + binaryPath + ").");
        } catch (Exception e) {
            DebugLogger.add("NetManagerDiag: failed to launch daemon: " + e.getMessage() + ".");
        }
    }

    public static boolean isBundled(Context context) {
        try (ZipFile apk = new ZipFile(context.getApplicationInfo().sourceDir)) {
            return apk.getEntry(jniLibsEntryName()) != null;
        } catch (IOException e) {
            return false;
        }
    }

    private static String primaryAbi() {
        for (String abi : Build.SUPPORTED_ABIS) {
            if (abi.equals("arm64-v8a") || abi.equals("armeabi-v7a")) {
                return abi;
            }
        }

        return Build.SUPPORTED_ABIS.length > 0 ? Build.SUPPORTED_ABIS[0] : "arm64-v8a";
    }

    private static String jniLibsEntryName() {
        return "lib/" + primaryAbi() + "/" + BINARY_NAME;
    }

    private volatile File extractedBinary;

    private File extractBinary() throws IOException {
        File cached = extractedBinary;
        if (cached != null) {
            return cached;
        }

        String entryName = jniLibsEntryName();
        File dir = appContext.getNoBackupFilesDir();
        File dest = new File(dir, BINARY_NAME);
        File tmp = new File(dir, BINARY_NAME + ".tmp");

        try (ZipFile apk = new ZipFile(appContext.getApplicationInfo().sourceDir)) {
            ZipEntry entry = apk.getEntry(entryName);
            if (entry == null) {
                throw new IOException(
                        "No " + entryName + " entry in " + appContext.getApplicationInfo().sourceDir + ".");
            }

            try (InputStream in = apk.getInputStream(entry);
                    OutputStream out = new FileOutputStream(tmp)) {
                byte[] buf = new byte[1 << 16];
                int n;

                while ((n = in.read(buf)) > 0) {
                    out.write(buf, 0, n);
                }
            }
        }

        if (!tmp.renameTo(dest)) {
            throw new IOException(
                    "Failed to move extracted binary into its destination (" + tmp + " to " + dest + ").");
        }

        if (!dest.setExecutable(true, false)) {
            throw new IOException("Failed to mark " + dest + " as executable.");
        }

        extractedBinary = dest;
        return dest;
    }

    private void readLoop() {
        LocalSocket s;
        synchronized (socketLock) {
            s = socket;
        }

        if (s == null)
            return;

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(s.getInputStream(), StandardCharsets.UTF_8))) {
            String line;

            while ((line = reader.readLine()) != null) {
                handleLine(line);
            }
        } catch (IOException e) {
            DebugLogger.add("NetManagerDiag: reader stopped: " + e.getMessage() + ".");
        } finally {
            handleDisconnect();
        }
    }

    private void handleLine(String line) {
        if (line.isEmpty())
            return;

        try {
            JsonObject obj = gson.fromJson(line, JsonObject.class);
            if (obj == null)
                return;

            if (obj.has("status")) {
                StatusMessage status = gson.fromJson(obj.get("status"), StatusMessage.class);

                lastStatus = status;
                if (status != null && status.connected && !loggedConnectedStatus) {
                    loggedConnectedStatus = true;
                    logEvent("NetManagerDiag daemon reports modem session as up (transport " + status.transport + ").");
                }

                notifyListeners(l -> l.onStatus(status));
            } else if (obj.has("error")) {
                String message = obj.get("error").getAsString();
                DebugLogger.add("NetManagerDiag error: " + message + ".");
                notifyListeners(l -> l.onError(message));
            } else if (obj.has("event")) {
                dispatchEvent(obj);
            }
        } catch (JsonSyntaxException e) {
            DebugLogger.add("NetManagerDiag: unparsable line: " + e.getMessage() + ".");
        } catch (RuntimeException e) {
            DebugLogger.add("NetManagerDiag: failed to handle line: " + e + ".");
        }
    }

    private void dispatchEvent(JsonObject obj) {
        String type = obj.get("event").getAsString();
        if (!loggedFirstEvent) {
            loggedFirstEvent = true;
            logEvent("First event (" + type + ").");
        }

        switch (type) {
            case "lte_serving_meas" -> {
                LteServingMeasEvent ev = gson.fromJson(obj, LteServingMeasEvent.class);
                notifyListeners(l -> l.onLteServingMeas(ev));
            }
            case "lte_cell_info" -> {
                LteCellInfoEvent ev = gson.fromJson(obj, LteCellInfoEvent.class);
                notifyListeners(l -> l.onLteCellInfo(ev));
            }
            case "nr_measurements" -> {
                NrMeasurementsEvent ev = gson.fromJson(obj, NrMeasurementsEvent.class);
                lastNrMeasurements = ev;
                notifyListeners(l -> l.onNrMeasurements(ev));
            }
            default -> DebugLogger.add("NetManagerDiag: unrecognised event type '" + type + "'.");
        }
    }

    private void handleDisconnect() {
        connected.set(false);
        lastNrMeasurements = null;

        synchronized (socketLock) {
            closeQuietly(socket);
            socket = null;
            socketOut = null;
        }

        notifyListeners(Listener::onDisconnected);
    }

    public synchronized void requestFeatures(String owner, Set<String> features, boolean wanted) {
        Set<String> isMine = featuresByOwner.computeIfAbsent(owner, k -> new HashSet<>());

        if (wanted)
            isMine.addAll(features);
        else
            isMine.removeAll(features);

        if (connected.get())
            sendEnableRequest();
        else if (wanted)
            connect();
    }

    private Set<String> mergedFeatures() {
        Set<String> all = new HashSet<>();
        for (Set<String> s : featuresByOwner.values())
            all.addAll(s);
        return all;
    }

    private synchronized void sendEnableRequest() {
        java.util.List<String> sorted = new java.util.ArrayList<>(mergedFeatures());
        java.util.Collections.sort(sorted);

        StringBuilder sb = new StringBuilder("{\"enable\":[");
        for (int i = 0; i < sorted.size(); i++) {
            if (i > 0)
                sb.append(',');
            sb.append('"').append(sorted.get(i)).append('"');
        }

        sb.append("]}\n");
        String payload = sb.toString();

        if (payload.equals(lastSentEnable))
            return;

        OutputStream out;
        synchronized (socketLock) {
            out = socketOut;
        }

        if (out == null)
            return;

        try {
            out.write(payload.getBytes(StandardCharsets.UTF_8));
            out.flush();
            lastSentEnable = payload;
        } catch (IOException e) {
            DebugLogger.add("NetManagerDiag: failed to send enable request: " + e.getMessage() + ".");
        }
    }

    public void shutdown() {
        OutputStream out;
        synchronized (socketLock) {
            out = socketOut;
        }

        if (out == null)
            return;

        try {
            out.write("{\"shutdown\":true}\n".getBytes(StandardCharsets.UTF_8));
            out.flush();
            DebugLogger.add("NetManagerDiag: shutdown requested.");
        } catch (IOException e) {
            DebugLogger.add("NetManagerDiag: failed to send shutdown request: " + e.getMessage() + ".");
        }
    }

    public void disconnect() {
        synchronized (socketLock) {
            closeQuietly(socket);
            socket = null;
            socketOut = null;
        }

        connected.set(false);
    }

    private void notifyListeners(java.util.function.Consumer<Listener> action) {
        mainHandler.post(() -> {
            for (Listener l : listeners)
                action.accept(l);
        });
    }

    private static void sleepQuietly(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException ignored) {
            Thread.currentThread().interrupt();
        }
    }

    private static void closeQuietly(LocalSocket s) {
        if (s == null)
            return;
        try {
            s.close();
        } catch (IOException ignored) {
        }
    }
}