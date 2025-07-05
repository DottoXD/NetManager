package pw.dotto.netmanager.Sensors;

import android.content.Context;

public class Manager {
    private static Manager instance;

    public Manager(Context context) {

    }

    public static synchronized Manager getInstance(Context context) {
        if (context == null)
            return null;

        if (instance == null) {
            instance = new Manager(context.getApplicationContext());
        }

        return instance;
    }
}
