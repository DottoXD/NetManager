package pw.dotto.netmanager.Core.Sources.Shizuku;

import android.content.Context;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.lang.reflect.Method;

import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.NetManagerCore;
import pw.dotto.netmanager.Core.Sources.CellDataSource;
import pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource;
import pw.dotto.netmanager.Utils.DebugLogger;
import pw.dotto.netmanager.Utils.Permissions;
import rikka.shizuku.Shizuku;

public class ShizukuCellDataSource implements CellDataSource {
    private final TelephonyCellDataSource baseSource;

    public ShizukuCellDataSource(TelephonyCellDataSource baseSource) {
        this.baseSource = baseSource;
    }

    @Override
    public boolean isAvailable(Context context) {
        return Permissions.checkShizuku();
    }

    @Override
    public SIMData fetch(Context context, SIMSlotState simSlotState) {
        SIMData baseData = baseSource.fetch(context, simSlotState);
        NetManagerCore core = NetManagerCore.getInstance(context);

        // temp test
        if (baseData != null && core.isForegroundActive() && core.getAdvancedMode()) {
            try {
                Method newProcessMethod = Shizuku.class.getDeclaredMethod("newProcess", String[].class, String[].class,
                        String.class);
                newProcessMethod.setAccessible(true);

                Process process = (Process) newProcessMethod.invoke(null,
                        new String[] { "dumpsys", "telephony.registry" }, null, null);

                if (process != null) {
                    BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
                    String line;

                    while ((line = reader.readLine()) != null) {
                        DebugLogger.add("Shizuku Dump: " + line);
                    }

                    process.waitFor();
                    reader.close();
                }
            } catch (Exception e) {
                DebugLogger.add("Shizuku fetch failed for SIM " + simSlotState.simId + ": " + e.getMessage());
            }
        }

        return baseData;
    }
}