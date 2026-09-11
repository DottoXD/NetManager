package pw.dotto.netmanager.Core.Processors.Postprocessors;

import android.content.Context;
import android.os.Build;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;

import java.util.List;

import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.TdscdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.WcdmaCellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.NetManagerCore;
import pw.dotto.netmanager.Core.Sources.TelephonyCellDataSource;
import pw.dotto.netmanager.Utils.DebugLogger;

/**
 * NetManager's ImpossibleCellsPostprocessor is a cell data postprocessor
 * which efficiently gets rid of cells which are absolutely impossible for the UE to be using.
 *
 * @author DottoXD
 * @version 0.2.0
 */
public class ImpossibleCellsPostprocessor implements Postprocessor {
    @Override
    public SIMData process(SIMData data, int simId, NetManagerCore netManagerCore) {
        if (data == null || data.getPrimaryCell() == null)
            return data;

        SIMSlotState slot = netManagerCore.getSlot(simId);
        if (slot == null || slot.telephony == null)
            return data;

        Context context = netManagerCore.getAppContext();
        TelephonyManager telephony = slot.telephony;
        List<Integer> cellBandwidths = netManagerCore.getCellBandwidths(simId);

        switch (data.getNetworkGen()) {
            case 2: // 2G cannot use multiple bands at the same time
                for (CellData cellData : data.getActiveCells()) {
                    if (cellData != data.getPrimaryCell()) {
                        data.removeActiveCell(cellData);
                        data.addNeighborCell(cellData);
                    }
                }
                break;

            case 3:
                if (data.getPrimaryCell() instanceof CdmaCellData || data.getPrimaryCell() instanceof TdscdmaCellData) {
                    for (CellData cellData : data.getActiveCells()) {
                        if (cellData != data.getPrimaryCell())
                            data.removeActiveCell(cellData);
                    }
                } else if (data.getPrimaryCell() instanceof WcdmaCellData) {
                    for (CellData cellData : data.getActiveCells()) {
                        if (!(cellData instanceof WcdmaCellData))
                            data.removeActiveCell(cellData);
                    }
                }
                break;

            case 4:
                if (cellBandwidths.isEmpty())
                    break;

                boolean isNsa = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
                        ? TelephonyCellDataSource.getNsaStatus(slot, telephony)
                        : TelephonyCellDataSource.getNsaStatusFromServiceState(telephony);

                if (!isNsa) {
                    for (CellData cellData : data.getActiveCells()) {
                        if (cellData instanceof NrCellData)
                            data.removeActiveCell(cellData);
                    }
                }

                boolean clearActiveCells;

                if (Build.VERSION.SDK_INT == Build.VERSION_CODES.R) {
                    clearActiveCells = !(SubscriptionManager.getActiveDataSubscriptionId() == telephony.getSubscriptionId());
                } else {
                    int status = TelephonyCellDataSource.getDataStatus(context, slot, telephony);

                    clearActiveCells = switch (status) {
                        case TelephonyManager.DATA_DISCONNECTED,
                             TelephonyManager.DATA_DISCONNECTING,
                             TelephonyManager.DATA_SUSPENDED,
                             TelephonyManager.DATA_UNKNOWN -> true;
                        default -> false;
                    };
                }

                if (clearActiveCells) {
                    DebugLogger.add(data.getActiveCells().length + " active cells have been cleared for SIM "
                            + data.getOperator() + "!");
                    data.clearActiveCells();
                }
                break;
        }

        return data;
    }
}