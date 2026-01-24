package pw.dotto.netmanager.Core.Events;

import androidx.annotation.Nullable;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * NetManager's NetManagerEvent is a loggable event for generic events.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public abstract class NetManagerEvent {
    private final EventTypes eventType;
    private String oldValue;
    private String newValue;
    private final String dateTime;

    public NetManagerEvent(EventTypes eventType, String newValue) {
        this.eventType = eventType;
        this.newValue = newValue;
        dateTime = LocalDateTime.now().toString();
    }

    /**
     * Sets the old value of the event.
     *
     * @param oldValue The event's old value.
     */
    public void setOldValue(String oldValue) {
        this.oldValue = oldValue;
    }

    /**
     * Sets the new value of the event.
     *
     * @param newValue The event's new value.
     */
    public void setNewValue(String newValue) {
        this.newValue = newValue;
    }

    /**
     * Gets the EventTypes type of the event.
     *
     * @return The event's type.
     */
    public EventTypes getEventType() {
        return eventType;
    }

    /**
     * Gets the old value of the event.
     *
     * @return A string containing the old value of the event.
     */
    public String getOldValue() {
        return oldValue;
    }

    /**
     * Gets the new value of the event.
     *
     * @return A string containing the new value of the event.
     */
    public String getNewValue() {
        return newValue;
    }

    /**
     * Gets the date and time of when the event occured.
     *
     * @return A string containing the date and time of the event based on the
     *         device's timezone.
     */
    public String getDateTime() {
        return dateTime;
    }

    @Override
    public boolean equals(@Nullable Object obj) {
        if (obj instanceof NetManagerEvent) {
            NetManagerEvent event = (NetManagerEvent) obj;

            return event.getEventType().equals(eventType)
                    && Objects.equals(event.getOldValue(), oldValue) && Objects.equals(event.getNewValue(), newValue);
        }

        return false;
    }
}
