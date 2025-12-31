package pw.dotto.netmanager.Utils;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

public class Activities {
    private static final String RADIO_INFO_PKG = "com.android.phone";
    private static final String RADIO_INFO_CLS = "com.android.phone.settings.RadioInfo";
    private static final String RADIO_INFO_PKG_LEGACY = "com.android.settings";
    private static final String RADIO_INFO_CLS_LEGACY = "com.android.settings.RadioInfo";

    private static final String SAMSUNG_INFO_PKG = "com.samsung.android.app.telephonyui";
    private static final String SAMSUNG_INFO_CLS = "com.samsung.android.app.telephonyui.hiddennetworksetting.MainActivity";

    public static boolean openRadioInfo(Context context) {
        Intent intent = new Intent(Intent.ACTION_MAIN);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            intent.setComponent(new ComponentName(RADIO_INFO_PKG, RADIO_INFO_CLS));
        } else {
            intent.setComponent(new ComponentName(RADIO_INFO_PKG_LEGACY, RADIO_INFO_CLS_LEGACY));
        }

        try {
            context.startActivity(intent);
        } catch (Exception ignored) {
            return false;
        }

        return true;
    }

    public static boolean openSamsungInfo(Context context) {
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.setComponent(new ComponentName(SAMSUNG_INFO_PKG, SAMSUNG_INFO_CLS));

        try {
            context.startActivity(intent);
        } catch (Exception ignored) {
            return false;
        }

        return true;
    }
}
