package pw.dotto.netmanager.Handlers;

import android.os.Build;
import android.os.SystemClock;

import androidx.annotation.RequiresApi;

import java.lang.ref.WeakReference;
import java.util.concurrent.TimeUnit;

import pw.dotto.netmanager.Core.Diag.NetManagerDiagClient;
import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.Utils.DebugLogger;

/**
 * NetManager's DiagRuntime is an advanced mode, runtime component which fetches
 * various pieces of modem data from NetManagerDiag, along with handling its
 * lifetime and its presence in the app's release bundle.
 *
 * @author DottoXD
 * @version 0.2.3
 */
public class DiagRuntime {
    private static final String DIAG_PROC_PATTERN = "[l]ibNetManagerDiag\\.so serve";
    private final WeakReference<MainActivity> activityReference;

    public DiagRuntime(MainActivity activity) {
        activityReference = new WeakReference<>(activity);
    }

    int checkDiagStatus() {
        MainActivity activity = activityReference.get();
        if (activity == null)
            return 1;

        if (!NetManagerDiagClient.isBundled(activity)) {
            DebugLogger.add(
                    "NetManagerDiag is not bundled as an asset for this ABI.");
            return 2;
        }

        try {
            Process p = Runtime.getRuntime().exec(new String[] { "su", "-c", "id" });
            boolean exited = waitForProcess(p, 10, TimeUnit.SECONDS);
            if (!exited || p.exitValue() != 0) {
                DebugLogger.add("NetManagerDiag root probe " + (exited ? "exited " + p.exitValue() : "timed out")
                        + ": permission denied.");
                return 1;
            }
        } catch (Exception e) {
            DebugLogger.add("NetManagerDiag root probe threw: " + e.getMessage() + ".");
            return 1;
        }

        DebugLogger.add("NetManagerDiag is working correctly.");
        return 0;
    }

    boolean isDiagSupported() {
        MainActivity activity = activityReference.get();
        if (activity == null)
            return false;

        boolean bundled = NetManagerDiagClient.isBundled(activity);
        if (!bundled)
            DebugLogger.add("NetManagerDiag is not bundled as an asset for this ABI.");
        return bundled;
    }

    public boolean isDaemonRunning() {
        MainActivity activity = activityReference.get();
        if (activity == null)
            return false;

        try {
            Process p = Runtime.getRuntime()
                    .exec(new String[] { "su", "-c", "pgrep -f '" + DIAG_PROC_PATTERN + "' >/dev/null" });
            boolean exited = waitForProcess(p, 3, TimeUnit.SECONDS);
            return exited && p.exitValue() == 0;
        } catch (Exception e) {
            return true;
        }
    }

    boolean waitForDaemonExit(int timeoutSeconds) {
        int iterations = Math.max(1, timeoutSeconds * 5);
        String cmd = "for i in $(seq 1 " + iterations + "); do "
                + "pgrep -f '" + DIAG_PROC_PATTERN + "' >/dev/null || exit 0; "
                + "sleep 0.2; "
                + "done; exit 1";
        try {
            Process p = Runtime.getRuntime().exec(new String[] { "su", "-c", cmd });
            boolean exited = waitForProcess(p, timeoutSeconds + 5L, TimeUnit.SECONDS);

            return exited && p.exitValue() == 0;
        } catch (Exception e) {
            DebugLogger.add("NetManagerDiag waitForDaemonExit: " + e.getMessage() + ".");
            return false;
        }
    }

    boolean sendKillSignal(boolean force) {
        try {
            String cmd = "pkill " + (force ? "-9 " : "") + "-f '" + DIAG_PROC_PATTERN + "'";
            Process p = Runtime.getRuntime().exec(new String[] { "su", "-c", cmd });
            boolean exited = waitForProcess(p, 5, TimeUnit.SECONDS);

            return exited && p.exitValue() == 0;
        } catch (Exception e) {
            DebugLogger.add("NetManagerDiag stopDiagDaemon: " + (force ? "SIGKILL" : "SIGTERM") + " attempt threw: "
                    + e.getMessage() + ".");
            return false;
        }
    }

    boolean stopDiagDaemon() {
        NetManagerDiagClient client = NetManagerDiagClient.getInstanceIfCreated();

        if (client != null && client.isConnected()) {
            client.shutdown();
            if (waitForDaemonExit(3)) {
                client.disconnect();
                DebugLogger.add("NetManagerDiag stopDiagDaemon: graceful shutdown (IPC request) succeeded.");

                return true;
            }
            DebugLogger
                    .add("NetManagerDiag stopDiagDaemon: graceful IPC shutdown did not take effect within 3s, escalating to SIGTERM.");
        } else {
            DebugLogger.add("NetManagerDiag stopDiagDaemon: no active connection, escalating to SIGTERM.");
        }

        if (sendKillSignal(false) && waitForDaemonExit(3)) {
            DebugLogger.add("NetManagerDiag stopDiagDaemon: SIGTERM succeeded.");
            if (client != null)
                client.disconnect();

            return true;
        }

        DebugLogger.add(
                "NetManagerDiag stopDiagDaemon: SIGTERM did not take effect within 3s, escalating to SIGKILL.");
        boolean killed = sendKillSignal(true) && waitForDaemonExit(3);
        if (client != null)
            client.disconnect();

        return killed;
    }

    private static boolean waitForProcess(Process process, long timeout, TimeUnit unit) throws InterruptedException {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            return waitForProcessApi26(process, timeout, unit);

        return waitForProcessFallback(process, unit.toMillis(timeout));
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private static boolean waitForProcessApi26(Process process, long timeout, TimeUnit unit)
            throws InterruptedException {
        return process.waitFor(timeout, unit);
    }

    private static boolean waitForProcessFallback(Process process, long timeoutMillis) throws InterruptedException {
        long timeout = Math.max(0L, timeoutMillis);
        long deadline = SystemClock.uptimeMillis() + timeout;

        while (true) {
            try {
                process.exitValue();
                return true;
            } catch (IllegalThreadStateException ignored) {
            }

            long remaining = deadline - SystemClock.uptimeMillis();
            if (remaining <= 0L)
                return false;
            Thread.sleep(Math.min(50L, remaining));
        }
    }
}
