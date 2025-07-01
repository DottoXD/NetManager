package pw.dotto.netmanager.Core.Events;

import static android.content.Context.MODE_PRIVATE;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.util.ArrayList;

public class EventManager {
    private static EventManager instance;
    private final ArrayList<NetmanagerEvent> events = new ArrayList<>();
    private final SharedPreferences sharedPreferences;

    public EventManager(Context context) {
        sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
        loadEvents();
    }

    public static synchronized EventManager getInstance(Context context) {
        if (context == null)
            return null;

        if (instance == null) {
            instance = new EventManager(context.getApplicationContext());
        }

        return instance;
    }

    public void addEvent(NetmanagerEvent event) {
        if (sharedPreferences == null || !sharedPreferences.getBoolean("flutter.logEvents", false))
            return;

        if (event instanceof MobileNetmanagerEvent) {
            MobileNetmanagerEvent mobileNetmanagerEvent = (MobileNetmanagerEvent) event;
            MobileNetmanagerEvent lastEvent = (MobileNetmanagerEvent) getLastEventByType(
                    mobileNetmanagerEvent.getEventType());

            if (lastEvent != null) {
                mobileNetmanagerEvent.setOldValue(lastEvent.getNewValue());
            } else
                mobileNetmanagerEvent.setOldValue("N/A");

            if (mobileNetmanagerEvent.equals(lastEvent))
                return;

            events.add(mobileNetmanagerEvent);

            int maxLogs = 10;
            try {
                maxLogs = sharedPreferences.getInt("flutter.maximumLogs", 10);
            } catch (Exception e) {
                // todo
            }

            if (maxLogs <= 0)
                maxLogs = 10;

            if (events != null && !events.isEmpty()) {
                if (events.size() > maxLogs)
                    events.remove(0);
            }

            saveEvents();
        }
    }

    public NetmanagerEvent getLastEventByType(EventTypes type) {
        for (int i = events.size() - 1; i > 0; i--) {
            if (events.get(i).getEventType().equals(type))
                return events.get(i);
        }

        return null;
    }

    public NetmanagerEvent[] getEvents() {
        return events.toArray(new NetmanagerEvent[0]);
    }

    private void saveEvents() {
        if (sharedPreferences == null)
            return;

        SharedPreferences.Editor sharedEditor = sharedPreferences.edit();
        String json = new Gson().toJson(events);
        sharedEditor.putString("loggedEvents", json);
        Log.w("pw.dotto.netmanager", "Saved " + json);
        sharedEditor.apply();
    }

    private void loadEvents() {
        if (sharedPreferences == null)
            return;

        String json = sharedPreferences.getString("loggedEvents", "[]");
        Log.w("pw.dotto.netmanager", "Retrieved " + json);
        if (json.trim().isEmpty())
            return;

        ArrayList<NetmanagerEvent> loaded = new Gson().fromJson(json, new TypeToken<ArrayList<NetmanagerEvent>>() {
        }.getType());
        events.clear();
        events.addAll(loaded);
    }
}
