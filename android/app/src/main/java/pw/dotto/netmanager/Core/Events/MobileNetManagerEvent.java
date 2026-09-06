package pw.dotto.netmanager.Core.Events;

import static pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import androidx.annotation.Nullable;

/**
 * NetManager's MobileNetManagerEvent is a loggable event for mobile cell
 * events.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class MobileNetManagerEvent extends NetManagerEvent {
    private final int simSlot;
    private final String network;

    public MobileNetManagerEvent(EventTypes eventType, String newValue, int simSlot, String network) {
        super(eventType, newValue);

        if (newValue.equals("00000") || newValue.contains("-1") || newValue.contains(String.valueOf(CELL_INFO_UNAVAILABLE)))
            setNewValue("N/A");

        this.simSlot = simSlot;
        this.network = network;
    }

    /**
     * Gets the SIM card slot's index of the event.
     *
     * @return The event's SIM slot index.
     */
    public int getSimSlot() {
        return simSlot;
    }

    /**
     * Gets the mobile network name of the event.
     *
     * @return A string containing the network's name.
     */
    public String getNetwork() {
        return network;
    }

    @Override
    public boolean equals(@Nullable Object obj) {
        if (obj instanceof MobileNetManagerEvent) {
            MobileNetManagerEvent event = (MobileNetManagerEvent) obj;
            if (event.getSimSlot() == simSlot)
                return super.equals(obj);
        }

        return false;
    }
}
