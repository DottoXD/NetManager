package pw.dotto.netmanager.Recording;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import pw.dotto.netmanager.Core.Mobile.SIMData;

/**
 * NetManager's Record class contains base attributes
 * for a single record inside a cell coverage recording.
 *
 * @author DottoXD
 * @version 0.1.6
 */
public class Record {
    private final boolean usable;
    private final String dateTime;
    private final double lat;
    private final double lon;
    private final SIMData simData;

    public Record(boolean usable, double lat, double lon, SIMData simData) {
        this.usable = usable;
        this.dateTime = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        this.lat = lat;
        this.lon = lon;
        this.simData = simData;
    }

    public boolean isUsable() { return usable; }
    public String getDateTime() { return dateTime; }
    public double getLat() { return lat; }
    public double getLon() { return lon; }
    public SIMData getSimData() { return simData; }
}