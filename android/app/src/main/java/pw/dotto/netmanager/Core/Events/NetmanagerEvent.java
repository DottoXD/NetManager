package pw.dotto.netmanager.Core.Events;

import java.time.LocalDateTime;

public abstract class NetmanagerEvent {
    private final EventTypes eventType;
    private final String oldValue;
    private final String newValue;
    private final LocalDateTime dateTime;

    public NetmanagerEvent(EventTypes eventType, String oldValue, String newValue) {
        this.eventType = eventType;
        this.oldValue = oldValue;
        this.newValue = newValue;
        dateTime = LocalDateTime.now();
    }

    public EventTypes getEventType() {
        return eventType;
    }

    public String getOldValue() {
        return oldValue;
    }

    public String getNewValue() {
        return newValue;
    }

    public LocalDateTime getDateTime() {
        return dateTime;
    }
}
