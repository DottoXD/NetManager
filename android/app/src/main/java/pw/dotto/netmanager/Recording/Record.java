package pw.dotto.netmanager.Recording;

import java.time.LocalDateTime;

/**
 * NetManager's Record class is the component that contains all base attributes for
 * a single record inside of a cell coverage recording.
 *
 * @author DottoXD
 * @version 0.0.4
 */
public class Record {
    private final int networkGen;
    private final int processedSignal;
    private final boolean usable;
    private final LocalDateTime dateTime;
    private final double lat;
    private final double lon;

    public Record(int networkGen, int processedSignal, boolean usable, double lat, double lon) {
        this.networkGen = networkGen;
        this.processedSignal = processedSignal;
        this.usable = usable;
        this.dateTime = LocalDateTime.now();
        this.lat = lat;
        this.lon = lon;
    }
}
