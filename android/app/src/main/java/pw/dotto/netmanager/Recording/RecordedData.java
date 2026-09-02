package pw.dotto.netmanager.Recording;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * NetManager's RecordedData class contains base
 * attributes for a cell coverage record file.
 *
 * @author DottoXD
 * @version 0.1.6
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
        if (record != null) {
            records.add(record);
        }
    }

    public void removeRecord(Record record) {
        records.remove(record);
    }

    public String getOperator() {
        return operator;
    }

    public String getNetwork() {
        return network;
    }

    public String getDate() {
        return date;
    }

    public List<Record> getRecords() {
        return records;
    }
}