package pw.dotto.netmanager.Utils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class DebugLogger {
    private static final List<String> logs = new ArrayList<>();
    private static final int MAX_SIZE = 300;

    public static void add(String msg) {
        LocalDateTime now = LocalDateTime.now();
        logs.add("[" + now.getHour() + ":" + now.getMinute() + ":" + now.getSecond() + "] - " + msg);

        if (logs.size() > MAX_SIZE)
            logs.remove(0);
    }

    public static String[] getLogs() {
        return logs.toArray(new String[0]);
    }
}
