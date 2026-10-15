package pw.dotto.netmanager.Handlers;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.plugin.common.EventChannel;
import pw.dotto.netmanager.Core.Diag.NetManagerDiagClient;
import pw.dotto.netmanager.MainActivity;

/**
 * NetManager's DiagEventStreamHandler is an event channel handler for
 * diag-provided data in NetManager.
 * This class handles all diag-provided data streams targeted to the Flutter
 * side.
 *
 * @author DottoXD
 * @version 0.2.3
 */
public class DiagEventStreamHandler implements EventChannel.StreamHandler {
    private final WeakReference<MainActivity> activityReference;
    private NetManagerDiagClient.Listener listener;
    private AtomicBoolean active;

    public DiagEventStreamHandler(MainActivity activity) {
        activityReference = new WeakReference<>(activity);
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        MainActivity activity = activityReference.get();
        if (activity == null)
            return;

        dispose();
        active = new AtomicBoolean(true);
        AtomicBoolean listenerActive = active;
        listener = new NetManagerDiagClient.Listener() {
            @Override
            public void onStatus(NetManagerDiagClient.StatusMessage status) {
                sendEvent(listenerActive, events, "status", status);
            }

            @Override
            public void onLteServingMeas(NetManagerDiagClient.LteServingMeasEvent event) {
                sendEvent(listenerActive, events, "lteServingMeas", event);
            }

            @Override
            public void onLteCellInfo(NetManagerDiagClient.LteCellInfoEvent event) {
                sendEvent(listenerActive, events, "lteCellInfo", event);
            }

            @Override
            public void onNrMeasurements(NetManagerDiagClient.NrMeasurementsEvent event) {
                sendEvent(listenerActive, events, "nrMeasurements", event);
            }

            @Override
            public void onError(String message) {
                sendEvent(listenerActive, events, "error", message);
            }

            @Override
            public void onDisconnected() {
                sendEvent(listenerActive, events, "disconnected", null);
            }
        };

        NetManagerDiagClient.getInstance(activity).addListener(listener);
    }

    @Override
    public void onCancel(Object arguments) {
        dispose();
    }

    public void dispose() {
        if (active != null)
            active.set(false);
        removeListener();
        active = null;
    }

    private void removeListener() {
        if (listener == null)
            return;

        NetManagerDiagClient client = NetManagerDiagClient.getInstanceIfCreated();
        if (client != null)
            client.removeListener(listener);
        listener = null;
    }

    private void sendEvent(AtomicBoolean listenerActive, EventChannel.EventSink events, String type, Object data) {
        if (!listenerActive.get())
            return;

        MainActivity activity = activityReference.get();
        if (activity == null)
            return;

        events.success(activity.getGson().toJson(wrap(type, data)));
    }

    private static HashMap<String, Object> wrap(String type, Object data) {
        HashMap<String, Object> wrapped = new HashMap<>();
        wrapped.put("type", type);
        wrapped.put("data", data);
        return wrapped;
    }
}
