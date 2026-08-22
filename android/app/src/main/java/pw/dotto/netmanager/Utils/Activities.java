package pw.dotto.netmanager.Utils;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

/**
 * NetManager's Activities class is a component that allows the app to start
 * external Android activities such as the Android Radio Info package.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class Activities {
    private static final String RADIO_INFO_PKG = "com.android.phone";
    private static final String RADIO_INFO_CLS = "com.android.phone.settings.RadioInfo";
    private static final String RADIO_INFO_PKG_LEGACY = "com.android.settings";
    private static final String RADIO_INFO_CLS_LEGACY = "com.android.settings.RadioInfo";

    private static final String SAMSUNG_INFO_PKG = "com.samsung.android.app.telephonyui";
    private static final String SAMSUNG_INFO_CLS = "com.samsung.android.app.telephonyui.hiddennetworksetting.MainActivity";

    private static final String HUAWEI_INFO_PKG = "com.huawei.android.projectmenu";
    private static final String HUAWEI_INFO_CLS = "com.huawei.android.projectmenu.ProjectMenuActivity";

    private static final String MEDIATEK_INFO_PKG = "com.mediatek.engineermode";
    private static final String MEDIATEK_INFO_CLS = "com.mediatek.engineermode.EngineerMode";

    private static final String XIAOMI_BAND_PKG = "com.android.phone";
    private static final String XIAOMI_BAND_CLS = "com.android.phone.settings.MiuiBandMode";

    /**
     * This method starts up Android's Radio Info package.
     *
     * @param context A valid application Context.
     * @return Whether the Activity was started successfully.
     */
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

    /**
     * This method starts up Samsung's Radio Info package.
     *
     * @param context A valid application Context.
     * @return Whether the Activity was started successfully.
     */
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

    /**
     * This method starts up Huawei's ProjectMenu package.
     *
     * @param context A valid application Context.
     * @return Whether the Activity was started successfully.
     */
    public static boolean openHuaweiInfo(Context context) {
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.setComponent(new ComponentName(HUAWEI_INFO_PKG, HUAWEI_INFO_CLS));

        try {
            context.startActivity(intent);
        } catch (Exception ignored) {
            return false;
        }

        return true;
    }

    /**
     * This method starts up Mediatek's EngineerMode package.
     *
     * @param context A valid application Context.
     * @return Whether the Activity was started successfully.
     */
    public static boolean openMediatekInfo(Context context) {
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.setComponent(new ComponentName(MEDIATEK_INFO_PKG, MEDIATEK_INFO_CLS));

        try {
            context.startActivity(intent);
        } catch (Exception ignored) {
            return false;
        }

        return true;
    }

    /**
     * This method starts up Xiaomi's BandMode package.
     *
     * @param context A valid application Context.
     * @return Whether the Activity was started successfully.
     */
    public static boolean openXiaomiInfo(Context context) {
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.setComponent(new ComponentName(XIAOMI_BAND_PKG, XIAOMI_BAND_CLS));

        try {
            context.startActivity(intent);
        } catch (Exception ignored) {
            return false;
        }

        return true;
    }
}
