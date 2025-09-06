package pw.dotto.netmanager.Fetchers;

import android.content.Context;

public class Location { // to be implemented
    private static Location instance;

    public Location(Context context) {

    }

    public static synchronized Location getInstance(Context context) {
        if (context == null)
            return null;

        if (instance == null) {
            instance = new Location(context.getApplicationContext());
        }

        return instance;
    }

    public void destroy() {
        instance = null;
    }
}
