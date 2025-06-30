package pw.dotto.netmanager.Core.Events;

import androidx.annotation.Nullable;

public class MobileNetmanagerEvent extends NetmanagerEvent {
    private final int simSlot;
    private final String network;
    private final String mccMnc;

    public MobileNetmanagerEvent(EventTypes eventType, String oldValue, String newValue, int simSlot, String network,
            String mccMnc) {
        super(eventType, oldValue, newValue);

        this.simSlot = simSlot;
        this.network = network;
        this.mccMnc = mccMnc;
    }

    public int getSimSlot() {
        return simSlot;
    }

    public String getNetwork() {
        return network;
    }

    public String getMccMnc() {
        return mccMnc;
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
