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

/**
 * NetManager's EventManager is a core component which comes in handy whenever a
 * user wants different kinds of cell events logged.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class EventManager {
    private static EventManager instance;
    private final ArrayList<NetManagerEvent> events = new ArrayList<>();
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

    /**
     * Adds a NetManagerEvent to the EventManager's events list if event logging is
     * enabled.
     *
     * @param event A valid NetManagerEvent.
     */
    public void addEvent(NetManagerEvent event) {
        if (sharedPreferences == null || !sharedPreferences.getBoolean("flutter.logEvents", false))
            return;

        if (event instanceof MobileNetManagerEvent) {
            MobileNetManagerEvent mobileNetmanagerEvent = (MobileNetManagerEvent) event;
            MobileNetManagerEvent lastEvent = (MobileNetManagerEvent) getLastEventByType(
                    mobileNetmanagerEvent.getEventType(), mobileNetmanagerEvent.getSimSlot());

            if (lastEvent != null) {
                String oldValue = lastEvent.getNewValue();
                if (oldValue.equals("00000") || oldValue.contains("-1"))
                    oldValue = "N/A";
                mobileNetmanagerEvent.setOldValue(oldValue);
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
                DebugLogger.add("Unexpected error while loading the maxLogs value: " + e.getMessage());
            }

            if (maxLogs <= 0)
                maxLogs = 10;

            if (!events.isEmpty()) {
                if (events.size() > maxLogs)
                    events.subList(0, Math.toIntExact(events.size() - maxLogs)).clear();
            }

            if (!saveEvents())
                DebugLogger.add("Unexpected error while saving the events.");
        }
    }

    /**
     * Returns the last NetManagerEvent event logged of the provided type (or null).
     *
     * @param type    A valid EventTypes type.
     * @param simSlot A valid simSlot (0/1).
     */
    public NetManagerEvent getLastEventByType(EventTypes type, int simSlot) {
        for (int i = events.size() - 1; i >= 0; i--) {
            if (events.get(i).getEventType().equals(type)) {
                NetManagerEvent checkedEvent = events.get(i);

                if (checkedEvent instanceof MobileNetManagerEvent) {
                    MobileNetManagerEvent mobileNetmanagerEvent = (MobileNetManagerEvent) checkedEvent;
                    if (mobileNetmanagerEvent.getSimSlot() == simSlot)
                        return checkedEvent;
                }
            }
        }

        return null;
    }

    /**
     * Returns all logged NetManagerEvent events.
     *
     * @return All events.
     */
    public NetManagerEvent[] getEvents() {
        return events.toArray(new NetManagerEvent[0]);
    }

    /**
     * Saves all events in JSON format in Android's SharedPreferences.
     *
     * @return A boolean communicating if the operation was successful.
     */
    private boolean saveEvents() {
        if (sharedPreferences == null)
            return false;

        SharedPreferences.Editor sharedEditor = sharedPreferences.edit();
        String json = gson.toJson(events);
        sharedEditor.putString("loggedEvents", json);
        sharedEditor.apply();

        return true;
    }

    /**
     * Loads all events from Android's SharedPreferences.
     *
     * @return A boolean communicating if the operation was successful.
     */
    private boolean loadEvents() {
        if (sharedPreferences == null)
            return false;

        String json = sharedPreferences.getString("loggedEvents", "");
        if (json.trim().isEmpty())
            return false;

        events.clear();

        try {
            JsonArray arr = JsonParser.parseString(json).getAsJsonArray();

            for (JsonElement elem : arr) {
                JsonObject obj = elem.getAsJsonObject();
                NetManagerEvent event;

                if (obj.has("simSlot") && obj.has("network")) {
                    event = gson.fromJson(obj, MobileNetManagerEvent.class);
                } else {
                    event = gson.fromJson(obj, NetManagerEvent.class);
                }

                if (event != null)
                    events.add(event);
            }
        } catch (Exception e) {
            DebugLogger.add("Unexpected error while loading and parsing the events: " + e.getMessage());

            return false;
        }

        return true;
    }
}
