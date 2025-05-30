package pw.dotto.netmanager.Core.MobileInfo.Events;

public class NetmanagerEvent {
    private final EventTypes eventType;
    private final String oldValue;
    private final String newValue;

    public NetmanagerEvent(EventTypes eventType, String oldValue, String newValue) {
        this.eventType = eventType;
        this.oldValue = oldValue;
        this.newValue = newValue;
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
}
