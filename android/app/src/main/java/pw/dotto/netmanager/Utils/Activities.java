package pw.dotto.netmanager.Utils;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;

public class Activities {
    private static final String RADIO_INFO_PKG = "com.android.phone";
    private static final String RADIO_INFO_CLS = "com.android.phone.settings.RadioInfo";
    private static final String SAMSUNG_INFO_PKG = "com.samsung.android.app.telephonyui";
    private static final String SAMSUNG_INFO_CLS = "com.samsung.android.app.telephonyui.hiddennetworksetting.MainActivity";

    public static void openRadioInfo(Context context) {
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.setComponent(new ComponentName(RADIO_INFO_PKG, RADIO_INFO_CLS));
        context.startActivity(intent);
    }

    public static void openSamsungInfo(Context context) {
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.setComponent(new ComponentName(SAMSUNG_INFO_PKG, SAMSUNG_INFO_CLS));
        context.startActivity(intent);
    }
}
