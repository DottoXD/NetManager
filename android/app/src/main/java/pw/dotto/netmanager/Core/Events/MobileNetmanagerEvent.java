package pw.dotto.netmanager.Core.Events;

import androidx.annotation.Nullable;

public class MobileNetmanagerEvent extends NetmanagerEvent {
    private final int simSlot;
    private final String network;

    public MobileNetmanagerEvent(EventTypes eventType, String newValue, int simSlot, String network) {
        super(eventType, newValue);

        if (newValue.equals("00000") || newValue.contains("-1"))
            setNewValue("N/A");

        this.simSlot = simSlot;
        this.network = network;
    }

    public int getSimSlot() {
        return simSlot;
    }

    public String getNetwork() {
        return network;
    }

    @Override
    public boolean equals(@Nullable Object obj) {
        if (obj instanceof MobileNetmanagerEvent) {
            MobileNetmanagerEvent event = (MobileNetmanagerEvent) obj;
            if (event.getSimSlot() == simSlot)
                return super.equals(obj);
        }

        return false;
    }
}
