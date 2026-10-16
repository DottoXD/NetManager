package pw.dotto.netmanager.core.shizuku;

import android.telephony.TelephonyManager;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import pw.dotto.netmanager.utils.DebugLogger;
import rikka.shizuku.Shizuku;

/**
 * NetManager's ShizukuClient is an advanced NetManager component which
 * coordinates Shizuku-powered reflection, data fetching & more.
 * This is necessary for Shizuku-powered advanced mode.
 * 
 * TODO: proper per-SIM filtering in here!
 *
 * @author DottoXD
 * @version 0.2.3
 */
public class ShizukuClient {

    private static final int MAX_IMS_LOGS = 400;
    private static final int LOGCAT_LINES = 8000;

    private static final Pattern TYPE_STATUS_PATTERN = Pattern
            .compile("\\btype\\s*=\\s*(\\d+)\\s+status\\s*=\\s*(\\d+)");

    public static Map<String, Object> fetch(int subId, int simSlot) {
        Map<String, Object> payload = new HashMap<>();
        Map<String, Object> imsStatus = new HashMap<>();
        List<Map<String, String>> imsLogs = new ArrayList<>();

        try {
            Method newProcessMethod = Shizuku.class.getDeclaredMethod(
                    "newProcess", String[].class, String[].class, String.class);
            newProcessMethod.setAccessible(true);

            String stateBlob = ShizukuReflectionBridge.getAdvancedState(subId);
            Map<String, String> state = parseKeyValues(stateBlob);

            for (String key : state.keySet()) {
                if (key.startsWith("error")) {
                    DebugLogger.add("ShizukuClient: client reported " + key + "=" + state.get(key) + ".");
                }
            }

            if (stateBlob == null || stateBlob.isEmpty()) {
                payload.put("bridgeError", "no-state");
            }

            applyStateBlob(payload, state);

            String logcatOut = runCommand(newProcessMethod, new String[] {
                    "logcat", "-d", "-b", "main,system,radio,crash",
                    "-v", "threadtime", "-t", String.valueOf(LOGCAT_LINES) });

            if (logcatOut != null) {
                List<String> kept = new ArrayList<>();
                for (String line : logcatOut.split("\n")) {
                    if (isImsLog(line))
                        kept.add(line);
                }

                int start = Math.max(0, kept.size() - MAX_IMS_LOGS);
                for (int i = start; i < kept.size(); i++) {
                    String trimmed = kept.get(i).trim();
                    Map<String, String> imsLog = new HashMap<>();
                    imsLog.put("time", extractTime(trimmed));
                    imsLog.put("type", getLogType(trimmed));
                    imsLog.put("message", trimmed);

                    imsLogs.add(imsLog);
                }
            }

            String imsDump = runCommand(newProcessMethod, new String[] { "dumpsys", "ims" });
            if (imsDump != null) {
                String mmtelSms = null;
                String rcsState = null;
                String emergency = null;
                String regState = null;
                String regTech = null;
                String epdgState = null;

                for (String line : imsDump.split("\n")) {
                    String lower = line.toLowerCase();

                    Matcher m = TYPE_STATUS_PATTERN.matcher(lower);
                    while (m.find()) {
                        try {
                            int type = Integer.parseInt(m.group(1));
                            int status = Integer.parseInt(m.group(2));
                            if (type == 2)
                                mmtelSms = status >= 2 ? "Available" : "Unavailable";
                        } catch (NumberFormatException ignored) {
                        }
                    }

                    if (regState == null) {
                        if (lower.contains("registration")
                                || lower.contains("imsservice")
                                || lower.contains("mmtel")) {
                            if (lower.contains("registered") && !lower.contains("unregistered")
                                    && !lower.contains("not registered")) {
                                regState = "REGISTERED";
                            } else if (lower.contains("registering")) {
                                regState = "REGISTERING";
                            } else if (lower.contains("not registered")
                                    || lower.contains("unregistered")) {
                                regState = "UNREGISTERED";
                            }
                        }
                    }

                    if (regTech == null) {
                        Matcher rat = Pattern.compile(
                                "(?:accessnetworktype|registrationtech|regtech|rat)\\s*[=:]\\s*([A-Za-z0-9()\\- ]+)",
                                Pattern.CASE_INSENSITIVE).matcher(line);
                        if (rat.find()) {
                            String cand = "";
                            try {
                                cand = rat.group(1).trim();
                            } catch (Exception ignored) {
                            }

                            if (!cand.isEmpty() && cand.length() < 24) {
                                regTech = normalizeRat(cand);
                            }
                        }
                    }

                    if (epdgState == null) {
                        if (lower.contains("epdg") || lower.contains("iwlan")) {
                            if (lower.contains("connected") || lower.contains("established"))
                                epdgState = "Connected";
                            else if (lower.contains("disconnected") || lower.contains("closed"))
                                epdgState = "Disconnected";
                        }
                    }

                    if (lower.contains("rcs") && (lower.contains("registered")
                            || lower.contains("connected")
                            || lower.contains("active")
                            || lower.contains("ready"))) {
                        rcsState = "Registered";
                    }

                    if (lower.contains("emergency") && (lower.contains("capable")
                            || lower.contains("supported")
                            || lower.contains("available"))) {
                        emergency = "Supported";
                    }
                }

                if (mmtelSms != null)
                    imsStatus.put("mmtelSms", mmtelSms);
                if (rcsState != null)
                    imsStatus.put("rcsState", rcsState);
                if (emergency != null && !imsStatus.containsKey("emergencyCapable"))
                    imsStatus.put("emergencyCapable", emergency);
                if (regState != null)
                    imsStatus.put("registration", regState);
                if (regTech != null)
                    imsStatus.put("regTech", regTech);
                if (epdgState != null)
                    imsStatus.put("epdgStatus", epdgState);
            }

            imsStatus.putIfAbsent("registration", "UNKNOWN");
            imsStatus.putIfAbsent("regTech", "Unknown");
            imsStatus.putIfAbsent("mmtel", "Unavailable");
            imsStatus.putIfAbsent("mmtelVideo", "Unavailable");
            imsStatus.putIfAbsent("mmtelSms", "Unavailable");
            imsStatus.putIfAbsent("rcsState", "Unregistered");
            imsStatus.putIfAbsent("epdgStatus", "Disconnected");
            imsStatus.putIfAbsent("emergencyCapable", "Unsupported");

            payload.put("ims", imsStatus);
            payload.put("imsLogs", imsLogs);

        } catch (Exception e) {
            payload.put("error", e.getMessage());
        }

        return payload;
    }

    private static Map<String, String> parseKeyValues(String blob) {
        Map<String, String> out = new HashMap<>();

        if (blob == null)
            return out;

        for (String line : blob.split("\n")) {
            int eq = line.indexOf('=');
            if (eq <= 0)
                continue;

            out.put(line.substring(0, eq).trim(), line.substring(eq + 1).trim());
        }

        return out;
    }

    private static void applyStateBlob(Map<String, Object> payload, Map<String, String> states) {
        boolean volte = getBool(states, "cc.carrier_volte_available_bool")
                || getBool(states, "cc.carrier_volte_capable_bool")
                || getBool(states, "cc.carrier_volte_provisioned_bool")
                || getBool(states, "cc.carrier_default_volte_switch_on_bool");

        boolean vonr = getBool(states, "cc.carrier_vonr_available_bool")
                || getBool(states, "cc.carrier_vonr_enabled_bool");

        boolean wfc = getBool(states, "cc.carrier_wfc_ims_available_bool")
                || getBool(states, "cc.wfc_ims_available_bool")
                || getBool(states, "cc.carrier_default_wfc_ims_enabled_bool");

        boolean vt = getBool(states, "cc.carrier_vt_available_bool");

        payload.put("volte", volte);
        payload.put("vonr", vonr);
        payload.put("wfc", wfc);
        payload.put("vt", vt);

        payload.put("wfcWifiOnly", getBool(states, "cc.carrier_wfc_supports_wifi_only_bool"));
        payload.put("wfcDefaultEnabled", getBool(states, "cc.carrier_default_wfc_ims_enabled_bool"));
        payload.put("crossSimIms", getBool(states, "cc.carrier_cross_sim_ims_available_bool"));
        payload.put("emergencyWfc", getBool(states, "cc.carrier_allow_emergency_call_over_wfc_bool"));

        boolean rcs = getBool(states, "cc.carrier_supports_rcs_bool")
                || getBool(states, "cc.use_rcs_sip_options_bool")
                || getBool(states, "cc.use_rcs_presence_bool");
        payload.put("rcsSupported", rcs);
        payload.put("rcsSingleReg", getBool(states, "cc.rcs_single_registration_required_bool"));

        payload.put("lteCa", getInt(states, "cc.lte_plus_threshold_bandwidth_khz_int") > 0);

        String nrArr = states.get("cc.carrier_nr_availabilities_int_array");

        boolean nsa = !nrArr.isEmpty() && containsToken(nrArr, "1");
        boolean sa = !nrArr.isEmpty() && containsToken(nrArr, "2");
        payload.put("nsaSupported", nsa);
        payload.put("saSupported", sa);
        payload.put("nrEnabled", nsa || sa
                || getBool(states, "cc.carrier_nr_availabilities_loaded_bool")
                || getBool(states, "cc.carrier_nr_enabled_bool"));
    }

    private static boolean getBool(Map<String, String> values, String key) {
        String v = values.get(key);

        return v != null && (v.equalsIgnoreCase("true") || v.equals("1"));
    }

    private static int getInt(Map<String, String> values, String key) {
        String v = values.get(key);

        if (v == null)
            return 0;

        try {
            return Integer.parseInt(v.trim());
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private static boolean containsToken(String csv, String token) {
        if (csv == null)
            return false;

        for (String part : csv.split(",")) {
            if (part.trim().equals(token))
                return true;
        }

        return false;
    }

    private static String runCommand(Method newProcessMethod, String[] cmd) {
        try {
            Process p = (Process) newProcessMethod.invoke(null, cmd, null, null);

            if (p == null)
                return null;

            StringBuilder sb = new StringBuilder();
            try (BufferedReader r = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
                String line;

                while ((line = r.readLine()) != null)
                    sb.append(line).append('\n');
            }

            p.waitFor();
            return sb.toString();
        } catch (Exception e) {
            return null;
        }
    }

    private static boolean isImsLog(String line) {
        if (line == null)
            return false;

        String lower = line.toLowerCase();
        if (lower.contains("listen:") || lower.contains("vvmpkginstalledrcvr")
                || lower.contains("notifynow") || lower.contains("callervm"))
            return false;

        return lower.contains("ims") || lower.contains("sip") || lower.contains("volte")
                || lower.contains("vowifi") || lower.contains("vonr") || lower.contains("mmtel")
                || lower.contains("rcs") || lower.contains("epdg") || lower.contains("iwlan")
                || lower.contains("qtiims") || lower.contains("mtkims");
    }

    private static String extractTime(String line) {
        Pattern p = Pattern.compile(
                "\\b(\\d{2}-\\d{2}\\s+\\d{2}:\\d{2}:\\d{2}(?:\\.\\d{1,3})?"
                        + "|\\d{2}:\\d{2}:\\d{2}(?:\\.\\d{1,3})?)\\b");
        Matcher m = p.matcher(line);

        return m.find() ? m.group(1) : "Now";
    }

    private static String getLogType(String line) {
        String lower = line.toLowerCase();

        if (lower.contains("error") || lower.contains("fail") || lower.contains("warn")
                || lower.contains("exception"))
            return "WARNING";

        if (lower.contains("epdg") || lower.contains("iwlan") || lower.contains("tunnel"))
            return "IWLAN/ePDG";

        if (lower.contains("rcs") || lower.contains("presence") || lower.contains("msisdn"))
            return "RCS";

        if (lower.contains("mmtel") || lower.contains("vowifi") || lower.contains("volte")
                || lower.contains("vonr") || lower.contains("sip_call")
                || lower.contains("capability"))
            return "MMTEL";

        if (lower.contains("handover") || lower.contains("hostate")
                || lower.contains("srctech") || lower.contains("tartech")
                || lower.contains("rat_change") || lower.contains("rat transition")
                || lower.contains("technology_changed"))
            return "HANDOVER";

        if (lower.contains("register") || lower.contains("regstate") || lower.contains("reg_state")
                || lower.contains("deregister") || lower.contains("sip_200")
                || lower.contains("onregistered"))
            return "REGISTRATION";

        return "IMS_EVENT";
    }

    private static String normalizeRat(String raw) {
        String u = raw.toUpperCase();

        if (u.contains("IWLAN") || u.contains("WLAN") || u.contains("WIFI"))
            return "IWLAN (Wi-Fi)";
        if (u.contains("NR") || u.contains("5G") || u.contains("NEWRADIO"))
            return "NR (5G)";
        if (u.contains("LTE") || u.contains("4G") || u.contains("EUTRAN"))
            return "LTE (4G)";
        if (u.contains("UTRAN") || u.contains("UMTS") || u.contains("3G") || u.contains("HSPA"))
            return "UMTS (3G)";
        if (u.contains("GERAN") || u.contains("GSM") || u.contains("2G") || u.contains("EDGE"))
            return "GSM (2G)";
        return raw;
    }

    public static String mapNetworkType(int t) {
        return switch (t) {
            case TelephonyManager.NETWORK_TYPE_LTE -> "LTE (4G)";
            case TelephonyManager.NETWORK_TYPE_NR -> "NR (5G)";
            case TelephonyManager.NETWORK_TYPE_IWLAN -> "IWLAN (Wi-Fi)";
            case TelephonyManager.NETWORK_TYPE_UMTS, TelephonyManager.NETWORK_TYPE_HSPA,
                    TelephonyManager.NETWORK_TYPE_HSDPA, TelephonyManager.NETWORK_TYPE_HSUPA ->
                "UMTS (3G)";
            case TelephonyManager.NETWORK_TYPE_GSM, TelephonyManager.NETWORK_TYPE_GPRS,
                    TelephonyManager.NETWORK_TYPE_EDGE ->
                "GSM (2G)";
            default -> "Unknown";
        };
    }
}