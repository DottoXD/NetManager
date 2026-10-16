package pw.dotto.netmanager.handlers;

import static pw.dotto.netmanager.core.shizuku.ShizukuClient.mapNetworkType;

import android.Manifest;
import android.annotation.SuppressLint;
import android.os.Build;
import android.telephony.ServiceState;
import android.telephony.TelephonyManager;

import androidx.annotation.RequiresPermission;

import java.lang.ref.WeakReference;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import pw.dotto.netmanager.core.base.SIMSlotState;
import pw.dotto.netmanager.core.Manager;
import pw.dotto.netmanager.core.NetManagerCore;
import pw.dotto.netmanager.MainActivity;
import pw.dotto.netmanager.utils.DebugLogger;

/**
 * NetManager's ImsRuntime is an advanced mode, runtime component which fetches
 * various pieces of IMS info eventually requested by other components across
 * the app.
 * This class performs reflection to gather extra data about network
 * registration info.
 *
 * @author DottoXD
 * @version 0.2.3
 */
public class ImsRuntime {
    private final WeakReference<MainActivity> activityReference;

    public ImsRuntime(MainActivity activity) {
        activityReference = new WeakReference<>(activity);
    }

    @RequiresPermission(allOf = { Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.READ_PHONE_STATE })
    Map<String, Object> readImsRuntimeState() {
        MainActivity activity = activityReference.get();
        if (activity == null)
            return new HashMap<>();

        Map<String, Object> out = new HashMap<>();

        final int TRANSPORT_WWAN = 1;
        final int TRANSPORT_WLAN = 2;
        final int DOMAIN_CS = 1;
        final int REG_HOME = 1;
        final int REG_ROAMING = 2;
        final int SERVICE_VOICE = 1;
        final int SERVICE_SMS = 2;
        final int SERVICE_VIDEO = 3;

        try {
            TelephonyManager tm = (TelephonyManager) activity.getSystemService(MainActivity.TELEPHONY_SERVICE);
            if (tm == null)
                return out;

            Manager core = activity.getCore();
            if (core != null) {
                TelephonyManager sub = core.getSubscription(activity.getSelectedSim());
                if (sub != null)
                    tm = sub;
            }

            SIMSlotState simSlotState = null;
            ServiceState ss = null;

            if (core != null)
                simSlotState = core.getSimSlotState(activity.getSelectedSim());

            if (simSlotState == null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                        && NetManagerCore.getInstance(activity).isForegroundActive())
                    ss = tm.getServiceState();
            } else {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    ss = simSlotState.serviceStateListener.getLatestServiceState();
                } else {
                    ss = simSlotState.legacyPhoneStateListener.getLatestServiceState();
                }
            }

            if (ss == null)
                return out;

            List<?> regs = getRegistrationList(ss);
            if (regs == null || regs.isEmpty())
                return out;

            boolean wwanVoiceRegistered = false;
            boolean wlanRegistered = false;
            boolean voiceSvc = false, smsSvc = false, videoSvc = false;
            int voiceRAT = TelephonyManager.NETWORK_TYPE_UNKNOWN;

            for (Object r : regs) {
                if (r == null)
                    continue;

                Class<?> rc = r.getClass();
                int transport = callInt(rc, r, "getTransportType", -1);
                int domain = callInt(rc, r, "getDomain", -1);
                int regState = callInt(rc, r, "getRegistrationState", -1);
                int accTech = callInt(rc, r, "getAccessNetworkTechnology",
                        TelephonyManager.NETWORK_TYPE_UNKNOWN);
                List<Integer> services = callIntList(rc, r, "getAvailableServices");
                boolean registered = regState == REG_HOME || regState == REG_ROAMING;

                if (transport == TRANSPORT_WLAN) {
                    if (registered)
                        wlanRegistered = true;
                } else if (transport == TRANSPORT_WWAN && domain == DOMAIN_CS && registered) {
                    wwanVoiceRegistered = true;
                    voiceRAT = accTech;
                    if (services != null) {
                        if (services.contains(SERVICE_VOICE))
                            voiceSvc = true;
                        if (services.contains(SERVICE_SMS))
                            smsSvc = true;
                        if (services.contains(SERVICE_VIDEO))
                            videoSvc = true;
                    }
                }
            }

            boolean anyRegistered = wwanVoiceRegistered || wlanRegistered;
            String regString = anyRegistered ? "REGISTERED" : "UNREGISTERED";
            String regTech;
            if (wlanRegistered)
                regTech = "IWLAN (Wi-Fi)";
            else if (wwanVoiceRegistered)
                regTech = mapNetworkType(voiceRAT);
            else
                regTech = "N/A";

            out.put("registration", regString);
            out.put("regTech", regTech);
            out.put("epdgStatus", wlanRegistered ? "Connected" : "Disconnected");
            out.put("mmtel", voiceSvc ? "Available" : "Unavailable");
            out.put("mmtelSms", smsSvc ? "Available" : "Unavailable");
            out.put("mmtelVideo", videoSvc ? "Available" : "Unavailable");
            out.put("emergencyCapable", "Unsupported");
        } catch (Throwable t) {
            DebugLogger.add("readImsRuntimeState failed: " + t);
        }

        return out;
    }

    private List<?> getRegistrationList(ServiceState ss) {
        try {
            Method m = ServiceState.class.getMethod("getNetworkRegistrationInfoList");
            Object r = m.invoke(ss);

            if (r instanceof List)
                return (List<?>) r;
        } catch (Throwable ignored) {
        }

        try {
            @SuppressLint("BlockedPrivateApi")
            Field f = ServiceState.class.getDeclaredField("mNetworkRegistrationInfos");
            f.setAccessible(true);
            Object r = f.get(ss);

            if (r instanceof List)
                return (List<?>) r;

            if (r != null && r.getClass().isArray())
                return Arrays.asList((Object[]) r);
        } catch (Throwable ignored) {
        }

        return null;
    }

    private int callInt(Class<?> cls, Object obj, String method, int def) {
        try {
            Method m = cls.getMethod(method);
            Object r = m.invoke(obj);

            return r instanceof Integer ? (Integer) r : def;
        } catch (Throwable ignored) {
            return def;
        }
    }

    @SuppressWarnings("unchecked")
    private List<Integer> callIntList(Class<?> cls, Object obj, String method) {
        try {
            Method m = cls.getMethod(method);
            Object r = m.invoke(obj);

            return r instanceof List ? (List<Integer>) r : null;
        } catch (Throwable ignored) {
            return null;
        }
    }
}
