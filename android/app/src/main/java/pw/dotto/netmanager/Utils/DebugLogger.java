package pw.dotto.netmanager.Utils;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

/**
 * NetManager's DebugLogger is a core component which is used to log useful
 * debug data.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class DebugLogger {
    private static final List<String> logs = new ArrayList<>();
    private static final int MAX_SIZE = 300;

    public static void add(String msg) {
        SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss", Locale.getDefault());
        String timestamp = sdf.format(new Date());
        logs.add("[" + timestamp + "] - " + msg);

        if (logs.size() > MAX_SIZE)
            logs.remove(0);
    }

    public static String[] getLogs() {
        return logs.toArray(new String[0]);
    }
}
