package pw.dotto.netmanager.Core.Events;

public class MobileNetmanagerEvent extends NetmanagerEvent {
    private final int simSlot;
    private final String network;
    private final String mccMnc;

    public MobileNetmanagerEvent(EventTypes eventType, String oldValue, String newValue, int simSlot, String network, String mccMnc) {
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
}
