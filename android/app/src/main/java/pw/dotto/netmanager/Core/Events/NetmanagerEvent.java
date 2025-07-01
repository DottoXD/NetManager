package pw.dotto.netmanager.Core.Events;

import androidx.annotation.Nullable;

import java.time.LocalDateTime;

public abstract class NetmanagerEvent {
    private final EventTypes eventType;
    private String oldValue;
    private final String newValue;
    private final String dateTime;

    public NetmanagerEvent(EventTypes eventType, String newValue) {
        this.eventType = eventType;
        this.newValue = newValue;
        dateTime = LocalDateTime.now().toString();
    }

    public void setOldValue(String oldValue) {
        this.oldValue = oldValue;
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

    public String getDateTime() {
        return dateTime;
    }

    @Override
    public boolean equals(@Nullable Object obj) {
        if (obj instanceof NetmanagerEvent) {
            NetmanagerEvent event = (NetmanagerEvent) obj;

            return event.getEventType().equals(eventType)
                    && (event.getOldValue().equals(oldValue) && event.getNewValue().equals(newValue));
        }

        return false;
    }
}
