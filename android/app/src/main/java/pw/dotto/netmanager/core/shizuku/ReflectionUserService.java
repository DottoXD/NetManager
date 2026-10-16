package pw.dotto.netmanager.core.shizuku;

import static pw.dotto.netmanager.core.sources.telephony.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import android.annotation.SuppressLint;
import android.os.Parcel;
import android.os.Parcelable;
import android.os.PersistableBundle;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

/**
 * NetManager's ReflectionUserService is an advanced NetManager component which
 * makes Shizuku, if available, perform reflection on behalf of NetManager to
 * gather extra cell data & carrier config data on modern Android versions.
 *
 * @author DottoXD
 * @version 0.2.3
 */
public class ReflectionUserService extends IReflectionUserService.Stub {

    private static final String[] BOOL_CARRIERCONFIG_KEYS = {
            "carrier_volte_available_bool",
            "carrier_volte_capable_bool",
            "carrier_volte_provisioned_bool",
            "carrier_default_volte_switch_on_bool",
            "carrier_vonr_available_bool",
            "carrier_vonr_enabled_bool",
            "carrier_wfc_ims_available_bool",
            "wfc_ims_available_bool",
            "carrier_default_wfc_ims_enabled_bool",
            "carrier_wfc_supports_wifi_only_bool",
            "carrier_vt_available_bool",
            "carrier_cross_sim_ims_available_bool",
            "carrier_allow_emergency_call_over_wfc_bool",
            "carrier_supports_rcs_bool",
            "use_rcs_sip_options_bool",
            "use_rcs_presence_bool",
            "rcs_single_registration_required_bool",
            "carrier_nr_availabilities_loaded_bool",
            "carrier_nr_enabled_bool",
    };

    public ReflectionUserService() {
    }

    @Override
    public int getHiddenIntField(byte[] signalStrengthBytes, String className, String fieldName) {
        if (signalStrengthBytes == null) {
            return CELL_INFO_UNAVAILABLE;
        }

        Parcel parcel = Parcel.obtain();
        try {
            parcel.unmarshall(signalStrengthBytes, 0, signalStrengthBytes.length);
            parcel.setDataPosition(0);

            Parcelable signalStrength = parcel.readParcelable(getClass().getClassLoader());
            if (signalStrength == null) {
                return CELL_INFO_UNAVAILABLE;
            }

            Class<?> targetClass = Class.forName(className);
            if (!targetClass.isInstance(signalStrength)) {
                return CELL_INFO_UNAVAILABLE;
            }

            Field field = targetClass.getDeclaredField(fieldName);
            field.setAccessible(true);

            return (int) field.get(signalStrength);
        } catch (Exception ignored) {
            return CELL_INFO_UNAVAILABLE;
        } finally {
            parcel.recycle();
        }
    }

    @Override
    public String getAdvancedState(int subId) {
        StringBuilder sb = new StringBuilder();

        try {
            PersistableBundle cc = loadCarrierConfig(subId);

            if (cc == null) {
                sb.append("error.carrierConfig=bundle-null\n");
                return sb.toString();
            }

            sb.append("info.cc.size=").append(cc.size()).append("\n");

            for (String key : BOOL_CARRIERCONFIG_KEYS) {
                sb.append("cc.").append(key).append('=')
                        .append(cc.getBoolean(key, false)).append("\n");
            }

            sb.append("cc.lte_plus_threshold_bandwidth_khz_int=")
                    .append(cc.getInt("lte_plus_threshold_bandwidth_khz_int", 0)).append("\n");

            int[] nr = cc.getIntArray("carrier_nr_availabilities_int_array");
            if (nr != null) {
                StringBuilder arr = new StringBuilder();

                for (int i = 0; i < nr.length; i++) {
                    if (i > 0)
                        arr.append(",");
                    arr.append(nr[i]);
                }

                sb.append("cc.carrier_nr_availabilities_int_array=")
                        .append(arr).append('\n');
            }
        } catch (Throwable t) {
            sb.append("error.carrierConfig=")
                    .append(t.getClass().getSimpleName()).append(":")
                    .append(t.getMessage() == null ? "" : t.getMessage().replace("\n", " "))
                    .append('\n');
        }

        return sb.toString();
    }

    private PersistableBundle loadCarrierConfig(int subId) {
        try {
            @SuppressLint("PrivateApi")
            Class<?> smClass = Class.forName("android.os.ServiceManager");
            Object binder = smClass.getMethod("getService", String.class)
                    .invoke(null, "carrier_config");

            if (binder == null)
                return null;

            String descriptor = (String) binder.getClass()
                    .getMethod("getInterfaceDescriptor").invoke(binder);
            Class<?> stubClass = Class.forName(descriptor + "$Stub");
            Object service = stubClass
                    .getMethod("asInterface", Class.forName("android.os.IBinder"))
                    .invoke(null, binder);

            if (service == null)
                return null;

            int[] candidates = (subId > 0) ? new int[] { subId, 1, 0 } : new int[] { 1, 0 };

            for (int sid : candidates) {
                try {
                    Method m = service.getClass()
                            .getMethod("getConfigForSubId", int.class, String.class);
                    Object r = m.invoke(service, sid, "com.android.shell");

                    if (r instanceof PersistableBundle)
                        return (PersistableBundle) r;
                } catch (NoSuchMethodException ignored) {
                }

                try {
                    Method m = service.getClass().getMethod("getConfigForSubId", int.class);
                    Object r = m.invoke(service, sid);

                    if (r instanceof PersistableBundle)
                        return (PersistableBundle) r;
                } catch (NoSuchMethodException ignored) {
                }
            }

            try {
                Method m = service.getClass().getMethod("getConfig");
                Object r = m.invoke(service);
                if (r instanceof PersistableBundle)
                    return (PersistableBundle) r;
            } catch (NoSuchMethodException ignored) {
            }
        } catch (Throwable ignored) {
        }

        return null;
    }

    @Override
    public void destroy() {
        System.exit(0);
    }
}