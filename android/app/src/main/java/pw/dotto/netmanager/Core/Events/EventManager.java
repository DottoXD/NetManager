package pw.dotto.netmanager.Core.Events;

import java.util.ArrayList;

public class EventManager {
    private static EventManager instance;
    private final ArrayList<NetmanagerEvent> events = new ArrayList<>();

    public EventManager() {

    }

    public static synchronized EventManager getInstance() {
        if(instance == null) {
            instance = new EventManager();
        }

        return instance;
    }

    public void addEvent(NetmanagerEvent event) {

    }

    public NetmanagerEvent[] getEvents() {
        return events.toArray(new NetmanagerEvent[0]);
    }
}
