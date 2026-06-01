package pw.dotto.netmanager.Recording;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * NetManager's RecordedData class is the component that contains all base
 * attributes for
 * a cell coverage record.
 *
 * @author DottoXD
 * @version 0.0.5
 */
public class RecordedData {
    private final String operator;
    private final String network;
    private final String date;
    private final List<Record> records = new CopyOnWriteArrayList<>();

    public RecordedData(String operator, String network) {
        this.operator = operator;
        this.network = network;
        this.date = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
    }

    public void addRecord(Record record) {
        if (!records.contains(record))
            records.add(record);
    }

    public void removeRecord(Record record) {
        if (records.contains(record))
            records.remove(record);
    }
}
