package pw.dotto.netmanager.Core.Sources.Diag;

import android.content.Context;

import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.Sources.CellDataSource;
import pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource;

public class DiagCellDataSource implements CellDataSource {
    private final TelephonyCellDataSource baseSource;

    public DiagCellDataSource(TelephonyCellDataSource baseSource) {
        this.baseSource = baseSource;
    }

    @Override
    public boolean isAvailable(Context context) {
        return false;
    }

    @Override
    public SIMData fetch(Context context, SIMSlotState simSlotState) {
        return null;
    }
}
