package pw.dotto.netmanager.Core.Mobile;

import static android.content.Context.MODE_PRIVATE;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.telephony.PhoneStateListener;
import android.telephony.PhysicalChannelConfig;
import android.telephony.TelephonyManager;
import android.util.Log;

import androidx.annotation.RequiresApi;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import pw.dotto.netmanager.Core.Listeners.ExtendedPhoneStateListener;
import pw.dotto.netmanager.Utils.DebugLogger;

public class PhysicalChannelDumper {
    private static final int LISTEN_PHYSICAL_CHANNEL_CONFIGURATION = 0x00100000;
    private Handler handler;
    private Runnable legacyDumper;
    private PhoneStateListener modernDumper;

    private TelephonyManager telephonyManager;
    private Context context;
    private SharedPreferences sharedPreferences;

    private final List<String> physicalChannelData = new ArrayList<>();

    public PhysicalChannelDumper(TelephonyManager telephonyManager, Context context) {
        this.telephonyManager = telephonyManager;
        this.context = context;
        this.sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);

        DebugLogger
                .add("Registering PhysicalChannelDumper for Telephony " + telephonyManager.getNetworkOperator()
                        + "...");

        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.R) {
            setupLegacyDumper();
        } else {
            setupModernDumper();
        }
    }

    private void setupLegacyDumper() {
        handler = new Handler(Looper.getMainLooper());

        if (legacyDumper == null)
            legacyDumper = new Runnable() {
                @Override
                public void run() {
                    try {
                        Method method = TelephonyManager.class.getDeclaredMethod("getPhysicalChannelConfigList");
                        method.setAccessible(true);
                        List<?> configs = (List<?>) method.invoke(telephonyManager);

                        if (configs != null) {
                            physicalChannelData.clear();
                            for (Object obj : configs) {
                                DebugLogger.add("Old PhysicalChannelDumper config: " + obj.toString());
                                physicalChannelData.add(obj.toString());
                            }
                        }
                    } catch (Exception e) {
                        StringWriter sw = new StringWriter();
                        PrintWriter pw = new PrintWriter(sw);
                        e.printStackTrace(pw);
                        pw.flush();

                        DebugLogger.add(
                                "Reflection PhysicalChannelDumper exception: " + e.getMessage() + ", " + e.getCause()
                                        + ".\n" + sw);
                    }

                    long millis = 3000;
                    try {
                        long seconds = sharedPreferences.getLong("flutter.backgroundUpdateInterval", 3);
                        millis = seconds * 1000;
                    } catch (ClassCastException e) {
                        Log.e("pw.dotto.netmanager", "Broken SharedPreferences.", e);
                    } catch (Exception e) {
                        Log.w("pw.dotto.netmanager", e.getMessage() == null ? "No info." : e.getMessage());
                    }
                    handler.postDelayed(this, millis);
                }
            };

        handler.post(legacyDumper);
    }

    @RequiresApi(api = Build.VERSION_CODES.R)
    private void setupModernDumper() {
        modernDumper = new ExtendedPhoneStateListener(telephonyManager.getSubscriptionId()) {
            @Override
            public void onPhysicalChannelConfigurationChanged(List<?> configs) {
                DebugLogger.add("Received modern PhysicalChannelDumper update!");

                if (configs != null) {
                    physicalChannelData.clear();
                    for (Object physicalChannelConfig : configs) {
                        DebugLogger.add("Modern PhysicalChannelDumper config: " + physicalChannelConfig.toString());
                        physicalChannelData.add(physicalChannelConfig.toString());
                    }
                }
            }
        };

        try {
            telephonyManager.listen(modernDumper, LISTEN_PHYSICAL_CHANNEL_CONFIGURATION);
            DebugLogger
                    .add("Successfully registered a PhysicalChannelDumper for Telephony "
                            + telephonyManager.getNetworkOperator() + "!");
        } catch (Exception e) {
            StringWriter sw = new StringWriter();
            PrintWriter pw = new PrintWriter(sw);
            e.printStackTrace(pw);
            pw.flush();

            DebugLogger.add(
                    "Modern PhysicalChannelDumper exception: " + e.getMessage() + ", " + e.getCause() + ".\n" + sw);
        }
    }

    public String[] getPhysicalChannelData() {
        return physicalChannelData.toArray(new String[0]);
    }

    public void dispose() {
        if (modernDumper != null) {
            telephonyManager.listen(modernDumper, PhoneStateListener.LISTEN_NONE);
            modernDumper = null;
        } else if (legacyDumper != null && handler != null)
            handler.removeCallbacks(legacyDumper);
    }
}
