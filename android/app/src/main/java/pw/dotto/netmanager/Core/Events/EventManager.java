package pw.dotto.netmanager.Core.Events;

import static android.content.Context.MODE_PRIVATE;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import java.util.ArrayList;

import pw.dotto.netmanager.Utils.DebugLogger;

public class EventManager {
    private static EventManager instance;
    private final ArrayList<NetmanagerEvent> events = new ArrayList<>();
    private final SharedPreferences sharedPreferences;
    private final Gson gson;

    public EventManager(Context context) {
        gson = new Gson();
        sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);

        if (!loadEvents())
            DebugLogger.add("Unexpected error while loading events.");
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
                    mobileNetmanagerEvent.getEventType(), mobileNetmanagerEvent.getSimSlot());

            if (lastEvent != null) {
                mobileNetmanagerEvent.setOldValue(lastEvent.getNewValue());
            } else
                mobileNetmanagerEvent.setOldValue("N/A");

            if (mobileNetmanagerEvent.equals(lastEvent)
                    || mobileNetmanagerEvent.getOldValue().equals(mobileNetmanagerEvent.getNewValue()))
                return;

            events.add(mobileNetmanagerEvent);

            long maxLogs = 10;
            try {
                maxLogs = sharedPreferences.getLong("flutter.maximumLogs", 10);
            } catch (Exception e) {
                // todo
            }

            if (maxLogs <= 0)
                maxLogs = 10;

            if (!events.isEmpty()) {
                if (events.size() > maxLogs)
                    events.subList(0, Math.toIntExact(events.size() - maxLogs)).clear(); // maxLogs shouldn't be bigger
                                                                                         // than an int?
            }

            if (!saveEvents())
                DebugLogger.add("Unexpected error while saving events.");
        }
    }

    public NetmanagerEvent getLastEventByType(EventTypes type, int simSlot) { // add new method with same name when i'll
                                                                              // add more types
        for (int i = events.size() - 1; i >= 0; i--) {
            if (events.get(i).getEventType().equals(type)) {
                NetmanagerEvent checkedEvent = events.get(i);

                if (checkedEvent instanceof MobileNetmanagerEvent) {
                    MobileNetmanagerEvent mobileNetmanagerEvent = (MobileNetmanagerEvent) checkedEvent;
                    if (mobileNetmanagerEvent.getSimSlot() == simSlot)
                        return checkedEvent;
                }
            }
        }

        return null;
    }

    public NetmanagerEvent[] getEvents() {
        return events.toArray(new NetmanagerEvent[0]);
    }

    private boolean saveEvents() {
        if (sharedPreferences == null)
            return false;

        SharedPreferences.Editor sharedEditor = sharedPreferences.edit();
        String json = gson.toJson(events);
        sharedEditor.putString("loggedEvents", json);
        sharedEditor.apply();

        return true;
    }

    private boolean loadEvents() {
        if (sharedPreferences == null)
            return false;

        String json = sharedPreferences.getString("loggedEvents", "[]");
        if (json.trim().isEmpty())
            return false;

        events.clear();

        try {
            JsonArray arr = JsonParser.parseString(json).getAsJsonArray();

            for (JsonElement elem : arr) {
                JsonObject obj = elem.getAsJsonObject();
                NetmanagerEvent event;

                if (obj.has("simSlot") && obj.has("network")) {
                    event = gson.fromJson(obj, MobileNetmanagerEvent.class);
                } else {
                    event = gson.fromJson(obj, NetmanagerEvent.class);
                }

                if (event != null)
                    events.add(event);
            }
        } catch (Exception e) {
            // todo add sentry

            return false;
        }

        return true;
    }
}
