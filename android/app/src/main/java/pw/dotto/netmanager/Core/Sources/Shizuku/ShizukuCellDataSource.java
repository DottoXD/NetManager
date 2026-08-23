package pw.dotto.netmanager.Core.Sources.Shizuku;

import android.content.Context;

import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.Sources.CellDataSource;

public class ShizukuCellDataSource implements CellDataSource {
    @Override
    public boolean isAvailable(Context context) {
        return false;
    }

    @Override
    public SIMData fetch(Context context, SIMSlotState simSlotState) {
        return null;
    }
}
