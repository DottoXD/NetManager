package pw.dotto.netmanager.Core.Sources;

import static pw.dotto.netmanager.Core.Mobile.Extractors.Cells.NrExtractor.getMaximumNrMhz;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.telephony.CellIdentity;
import android.telephony.CellIdentityNr;
import android.telephony.CellInfo;
import android.telephony.CellInfoCdma;
import android.telephony.CellInfoGsm;
import android.telephony.CellInfoLte;
import android.telephony.CellInfoNr;
import android.telephony.CellInfoTdscdma;
import android.telephony.CellInfoWcdma;
import android.telephony.CellSignalStrength;
import android.telephony.CellSignalStrengthNr;
import android.telephony.ServiceState;
import android.telephony.SignalStrength;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.GsmCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.LteCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.TdscdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.WcdmaCellData;
import pw.dotto.netmanager.Core.Mobile.Extractors.BasicData.DataManager;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.CdmaExtractor;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.GsmExtractor;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.LteExtractor;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.NrExtractor;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.TdscdmaExtractor;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.WcdmaExtractor;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.Processors.Preprocessors.Preprocessor;
import pw.dotto.netmanager.Utils.DebugLogger;
import pw.dotto.netmanager.Utils.Permissions;

/**
 * NetManager's TelephonyCellDataSource is the core mobile cell data source for
 * NetManager which gathers the entirety of its data from Android's Telephony
 * API.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class TelephonyCellDataSource implements CellDataSource {
    public static final int CELL_INFO_UNAVAILABLE = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
            ? CellInfo.UNAVAILABLE
            : Integer.MAX_VALUE;
    private static final int CONNECTION_NONE = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P ? CellInfo.CONNECTION_NONE
            : 0;
    private static final int CONNECTION_PRIMARY_SERVING = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P
            ? CellInfo.CONNECTION_PRIMARY_SERVING
            : 1;
    private static final int CONNECTION_SECONDARY_SERVING = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P
            ? CellInfo.CONNECTION_SECONDARY_SERVING
            : 2;
    private static final int CONNECTION_UNKNOWN = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P
            ? CellInfo.CONNECTION_UNKNOWN
            : CELL_INFO_UNAVAILABLE;

    private static final String UNKNOWN_MCCMNC = "UNKNOWN";

    private static final int MODEM_REFRESH_INTERVAL_SECONDS = 10;
    private final Map<Integer, Date> lastModemUpdateBySlot = new ConcurrentHashMap<>();

    private final List<Preprocessor> preprocessors;

    public TelephonyCellDataSource(List<Preprocessor> preprocessors) {
        this.preprocessors = preprocessors == null ? Collections.emptyList() : preprocessors;
    }

    @Override
    public boolean isAvailable(Context context) {
        return true;
    }

    @Override
    @SuppressLint("MissingPermission")
    public SIMData fetch(Context context, SIMSlotState simSlotState) {
        if (simSlotState == null || simSlotState.telephony == null
                || !Permissions.check(context, Permissions.READ_PHONE_STATE))
            return null;

        TelephonyManager telephony = simSlotState.telephony;
        int simId = simSlotState.simId;

        SIMData data = new SIMData(getSimCarrier(context, telephony), getSimOperator(context, telephony),
                getSimNetworkGen(context, telephony), telephony.getSimOperator(), getPlmn(context, telephony));

        String simOperator = telephony.getNetworkOperator();
        if ((simOperator == null || simOperator.isEmpty())
                && telephony.getPhoneType() == TelephonyManager.PHONE_TYPE_CDMA)
            simOperator = telephony.getSimOperator();

        if (simOperator == null || simOperator.isEmpty())
            simOperator = "00000";

        try {
            Date lastUpdate = lastModemUpdateBySlot.get(simId);
            boolean shouldUpdate = lastUpdate == null
                    || lastUpdate.toInstant().plusSeconds(MODEM_REFRESH_INTERVAL_SECONDS)
                            .isBefore(new Date().toInstant());

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && shouldUpdate) {
                telephony.requestCellInfoUpdate(ContextCompat.getMainExecutor(context),
                        new TelephonyManager.CellInfoCallback() {
                            @Override
                            public void onCellInfo(@NonNull List<CellInfo> cellInfo) {
                                lastModemUpdateBySlot.put(simId, new Date());
                            }
                        });
            }
        } catch (Exception e) {
            DebugLogger.add(
                    "Error while requesting SIMData update: " + (e.getMessage() == null ? "Error." : e.getMessage()));
        }

        List<CellInfo> cellInfo = new ArrayList<>();
        List<CellInfo> rawCells = telephony.getAllCellInfo();
        if (rawCells != null) {
            cellInfo.addAll(rawCells);
        }

        List<CellInfo> additionalCells = null;
        if (simSlotState != null) {
            if (simSlotState.cellInfoListener != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                additionalCells = simSlotState.cellInfoListener.getLatestCellInfo();
            } else if (simSlotState.legacyPhoneStateListener != null) {
                additionalCells = simSlotState.legacyPhoneStateListener.getLatestCellInfo();
            }
        }

        if (additionalCells != null && !additionalCells.isEmpty()) {
            if (cellInfo.isEmpty()) {
                cellInfo.addAll(additionalCells);
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Set<CellIdentity> existingIdentities = new HashSet<>();
                for (CellInfo cell : cellInfo) {
                    if (cell != null && cell.getCellIdentity() != null) {
                        existingIdentities.add(cell.getCellIdentity());
                    }
                }

                for (CellInfo additionalCell : additionalCells) {
                    if (additionalCell != null) {
                        CellIdentity identity = additionalCell.getCellIdentity();
                        if (identity != null && !existingIdentities.contains(identity)) {
                            cellInfo.add(additionalCell);
                            existingIdentities.add(identity);
                        }
                    }
                }
            } else {
                for (CellInfo additionalCell : additionalCells) {
                    if (additionalCell != null && !cellInfo.contains(additionalCell)) {
                        cellInfo.add(additionalCell);
                    }
                }
            }
        }

        for (Preprocessor preprocessor : preprocessors)
            cellInfo = preprocessor.process(cellInfo, simId);

        for (CellInfo baseCell : cellInfo) {
            classifyCell(context, baseCell, data, simOperator, telephony, simSlotState);
        }

        if (data.getActiveCells().length == 0) {
            for (CellData neighborCell : data.getNeighborCells()) {
                if (neighborCell.isRegistered()) {
                    if (data.getPrimaryCell() == null)
                        data.setPrimaryCell(neighborCell);
                    else
                        data.addActiveCell(neighborCell);

                    data.removeNeighborCell(neighborCell);
                }
            }
        }

        for (CellData cell : data.getActiveCells()) {
            if (data.getPrimaryCell() != null && cell.getChannelNumber() == data.getPrimaryCell().getChannelNumber())
                data.removeActiveCell(cell);

            for (CellData altCell : data.getActiveCells()) {
                if (cell == altCell)
                    continue;

                if (cell.getChannelNumber() == altCell.getChannelNumber())
                    data.removeActiveCell(cell);
            }
        }

        List<Integer> cellBandwidths = readCellBandwidths(telephony, simSlotState, context);

        String rawPlmn = getPlmn(context, telephony);
        int mcc = 0;
        try {
            mcc = rawPlmn.length() >= 3 ? Integer.parseInt(rawPlmn.substring(0, 3)) : 0;
        } catch (Exception ignored) {
        }

        if (data.getPrimaryCell() != null) {
            CellData primaryCell = data.getPrimaryCell();
            primaryCell.setBasicCellData(DataManager.getBasicData(primaryCell, mcc));

            if (primaryCell.getBand() == -1)
                primaryCell.setBand(primaryCell.getBasicCellData().getBand());

            data.addActiveCell(primaryCell);
        }

        for (CellData cellData : data.getActiveCells()) {
            cellData.setBasicCellData(DataManager.getBasicData(cellData, mcc));

            if (cellData.getBand() == -1)
                cellData.setBand(cellData.getBasicCellData().getBand());
        }

        for (CellData cellData : data.getNeighborCells()) {
            cellData.setBasicCellData(DataManager.getBasicData(cellData, mcc));

            if (cellData.getBand() == -1)
                cellData.setBand(cellData.getBasicCellData().getBand());
        }

        filterImpossibleBands(context, data, telephony, simSlotState, cellBandwidths);
        assignBandwidths(data, cellBandwidths);
        fixNrSignal(data, telephony);
        computeActiveBandwidth(data);

        return data;
    }

    private void classifyCell(Context context, CellInfo baseCell, SIMData data, String simOperator,
            TelephonyManager telephony,
            SIMSlotState slot) {
        int connectionStatus = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P ? baseCell.getCellConnectionStatus()
                : legacyConnectionStatus(baseCell);

        if (connectionStatus == CONNECTION_PRIMARY_SERVING) {
            if (baseCell instanceof CellInfoGsm) {
                GsmCellData gsmCellData = GsmExtractor.get((CellInfoGsm) baseCell);
                String mccMnc = buildMccMnc(
                        ((CellInfoGsm) baseCell).getCellIdentity().getMcc(),
                        ((CellInfoGsm) baseCell).getCellIdentity().getMnc(),
                        simOperator);

                if (data.getPrimaryCell() == null && getSimNetworkGen(context, telephony) == 2
                        && mccMnc.equals(simOperator))
                    data.setPrimaryCell(gsmCellData);
            } else if (baseCell instanceof CellInfoCdma) {
                data.setPrimaryCell(CdmaExtractor.get((CellInfoCdma) baseCell));
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && baseCell instanceof CellInfoTdscdma) {
                TdscdmaCellData tdscdmaCellData = TdscdmaExtractor.get((CellInfoTdscdma) baseCell);
                String mccMnc = ((CellInfoTdscdma) baseCell).getCellIdentity().getMccString()
                        + ((CellInfoTdscdma) baseCell).getCellIdentity().getMncString();

                if (data.getPrimaryCell() == null && mccMnc.equals(simOperator))
                    data.setPrimaryCell(tdscdmaCellData);
            } else if (baseCell instanceof CellInfoWcdma) {
                WcdmaCellData wcdmaCellData = WcdmaExtractor.get((CellInfoWcdma) baseCell);
                String mccMnc = buildMccMnc(
                        ((CellInfoWcdma) baseCell).getCellIdentity().getMcc(),
                        ((CellInfoWcdma) baseCell).getCellIdentity().getMnc(),
                        simOperator);

                if (data.getPrimaryCell() == null && mccMnc.equals(simOperator))
                    data.setPrimaryCell(wcdmaCellData);
            } else if (baseCell instanceof CellInfoLte) {
                LteCellData lteCellData = LteExtractor.get((CellInfoLte) baseCell);
                String mccMnc = buildMccMnc(
                        ((CellInfoLte) baseCell).getCellIdentity().getMcc(),
                        ((CellInfoLte) baseCell).getCellIdentity().getMnc(),
                        simOperator);

                if (mccMnc.equals(simOperator))
                    data.setPrimaryCell(lteCellData);
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && baseCell instanceof CellInfoNr) {
                NrCellData nrCellData = NrExtractor.get((CellInfoNr) baseCell);
                boolean isNsa = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
                        ? getNsaStatus(slot, telephony)
                        : getNsaStatusFromServiceState(telephony);

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    CellIdentityNr identity = (CellIdentityNr) baseCell.getCellIdentity();
                    String mccMnc = identity.getMccString() + identity.getMncString();

                    if (!mccMnc.contains("null")) {
                        if (mccMnc.equals(simOperator))
                            addPrimaryOrActive(data, nrCellData, isNsa);
                    } else { // hopefully it's not from another sim...
                        addPrimaryOrActive(data, nrCellData, isNsa);
                    }
                } else {
                    addPrimaryOrActive(data, nrCellData, isNsa);
                }
            }
        } else if (connectionStatus == CONNECTION_SECONDARY_SERVING) {
            addSecondaryCell(baseCell, data, simOperator);
        } else {
            addNeighborCell(baseCell, data, simOperator);
        }
    }

    private int legacyConnectionStatus(CellInfo baseCell) {
        return baseCell.isRegistered() ? CONNECTION_PRIMARY_SERVING : CONNECTION_NONE;
    }

    private void addPrimaryOrActive(SIMData data, NrCellData nrCellData, boolean isNsa) {
        if (!isNsa)
            data.setPrimaryCell(nrCellData);
        else
            data.addActiveCell(nrCellData);
    }

    private void addSecondaryCell(CellInfo baseCell, SIMData data, String simOperator) {
        if (baseCell instanceof CellInfoGsm) {
            GsmCellData gsmCellData = GsmExtractor.get((CellInfoGsm) baseCell);
            String mccMnc = buildMccMnc(
                    ((CellInfoGsm) baseCell).getCellIdentity().getMcc(),
                    ((CellInfoGsm) baseCell).getCellIdentity().getMnc(),
                    simOperator);
            if (!mccMnc.contains(UNKNOWN_MCCMNC)) {
                if (mccMnc.equals(simOperator))
                    data.addActiveCell(gsmCellData);
            } else
                data.addActiveCell(gsmCellData);
        } else if (baseCell instanceof CellInfoCdma) {
            data.addActiveCell(CdmaExtractor.get((CellInfoCdma) baseCell));
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && baseCell instanceof CellInfoTdscdma) {
            TdscdmaCellData tdscdmaCellData = TdscdmaExtractor.get((CellInfoTdscdma) baseCell);
            String mccMnc = ((CellInfoTdscdma) baseCell).getCellIdentity().getMccString()
                    + ((CellInfoTdscdma) baseCell).getCellIdentity().getMncString();
            if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                    data.addActiveCell(tdscdmaCellData);
            } else
                data.addActiveCell(tdscdmaCellData);
        } else if (baseCell instanceof CellInfoWcdma) {
            WcdmaCellData wcdmaCellData = WcdmaExtractor.get((CellInfoWcdma) baseCell);
            String mccMnc = buildMccMnc(
                    ((CellInfoWcdma) baseCell).getCellIdentity().getMcc(),
                    ((CellInfoWcdma) baseCell).getCellIdentity().getMnc(),
                    simOperator);
            if (!mccMnc.contains(UNKNOWN_MCCMNC)) {
                if (mccMnc.equals(simOperator))
                    data.addActiveCell(wcdmaCellData);
            } else
                data.addActiveCell(wcdmaCellData);
        } else if (baseCell instanceof CellInfoLte) {
            LteCellData lteCellData = LteExtractor.get((CellInfoLte) baseCell);
            String mccMnc = buildMccMnc(
                    ((CellInfoLte) baseCell).getCellIdentity().getMcc(),
                    ((CellInfoLte) baseCell).getCellIdentity().getMnc(),
                    simOperator);
            if (!mccMnc.contains(UNKNOWN_MCCMNC)) {
                if (mccMnc.equals(simOperator))
                    data.addActiveCell(lteCellData);
            } else
                data.addActiveCell(lteCellData);
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && baseCell instanceof CellInfoNr) {
            NrCellData nrCellData = NrExtractor.get((CellInfoNr) baseCell);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                CellIdentityNr identity = (CellIdentityNr) baseCell.getCellIdentity();
                String mccMnc = identity.getMccString() + identity.getMncString();
                if (!mccMnc.contains("null")) {
                    if (mccMnc.equals(simOperator))
                        data.addActiveCell(nrCellData);
                } else
                    data.addActiveCell(nrCellData);
            } else
                data.addActiveCell(nrCellData);
        }
    }

    private void addNeighborCell(CellInfo baseCell, SIMData data, String simOperator) {
        if (baseCell instanceof CellInfoGsm) {
            GsmCellData gsmCellData = GsmExtractor.get((CellInfoGsm) baseCell);
            String mccMnc = buildMccMnc(
                    ((CellInfoGsm) baseCell).getCellIdentity().getMcc(),
                    ((CellInfoGsm) baseCell).getCellIdentity().getMnc(),
                    simOperator);
            if (!mccMnc.contains(UNKNOWN_MCCMNC)) {
                if (mccMnc.equals(simOperator))
                    data.addNeighborCell(gsmCellData);
            } else
                data.addNeighborCell(gsmCellData);
        } else if (baseCell instanceof CellInfoCdma) {
            data.addNeighborCell(CdmaExtractor.get((CellInfoCdma) baseCell));
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && baseCell instanceof CellInfoTdscdma) {
            TdscdmaCellData tdscdmaCellData = TdscdmaExtractor.get((CellInfoTdscdma) baseCell);
            String mccMnc = ((CellInfoTdscdma) baseCell).getCellIdentity().getMccString()
                    + ((CellInfoTdscdma) baseCell).getCellIdentity().getMncString();
            if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                    data.addNeighborCell(tdscdmaCellData);
            } else
                data.addNeighborCell(tdscdmaCellData);
        } else if (baseCell instanceof CellInfoWcdma) {
            WcdmaCellData wcdmaCellData = WcdmaExtractor.get((CellInfoWcdma) baseCell);
            String mccMnc = buildMccMnc(
                    ((CellInfoWcdma) baseCell).getCellIdentity().getMcc(),
                    ((CellInfoWcdma) baseCell).getCellIdentity().getMnc(),
                    simOperator);
            if (!mccMnc.contains(UNKNOWN_MCCMNC)) {
                if (mccMnc.equals(simOperator))
                    data.addNeighborCell(wcdmaCellData);
            } else
                data.addNeighborCell(wcdmaCellData);
        } else if (baseCell instanceof CellInfoLte) {
            LteCellData lteCellData = LteExtractor.get((CellInfoLte) baseCell);
            String mccMnc = buildMccMnc(
                    ((CellInfoLte) baseCell).getCellIdentity().getMcc(),
                    ((CellInfoLte) baseCell).getCellIdentity().getMnc(),
                    simOperator);
            if (!mccMnc.contains(UNKNOWN_MCCMNC)) {
                if (mccMnc.equals(simOperator))
                    data.addNeighborCell(lteCellData);
            } else
                data.addNeighborCell(lteCellData);
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && baseCell instanceof CellInfoNr) {
            NrCellData nrCellData = NrExtractor.get((CellInfoNr) baseCell);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                CellIdentityNr identity = (CellIdentityNr) baseCell.getCellIdentity();
                String mccMnc = identity.getMccString() + identity.getMncString();
                if (!mccMnc.contains("null")) {
                    if (mccMnc.equals(simOperator))
                        data.addNeighborCell(nrCellData);
                } else
                    data.addNeighborCell(nrCellData);
            } else
                data.addNeighborCell(nrCellData);
        }
    }

    @SuppressLint("MissingPermission")
    private List<Integer> readCellBandwidths(TelephonyManager telephony, SIMSlotState slot, Context context) {
        List<Integer> cellBandwidths = new ArrayList<>();

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                int[] bandwidths = slot.serviceStateListener != null
                        ? slot.serviceStateListener.getUpdatedCellBandwidths()
                        : null;

                DebugLogger.add("Service state bandwidth for SIM " + slot.simId + ": " + Arrays.toString(bandwidths));

                if (context instanceof Activity) {
                    // todo: test if anything breaks on snapdragon samsungs
                    if (bandwidths == null) {
                        ServiceState state = telephony.getServiceState();
                        if (state != null)
                            bandwidths = state.getCellBandwidths();
                    }
                }

                if (bandwidths != null)
                    for (int bw : bandwidths)
                        cellBandwidths.add(bw / 1000);
            } else {
                int[] bandwidths = slot.legacyPhoneStateListener != null
                        ? slot.legacyPhoneStateListener.getUpdatedCellBandwidths()
                        : null;

                DebugLogger.add(
                        "Legacy service state bandwidth for SIM " + slot.simId + ": " + Arrays.toString(bandwidths));

                if (bandwidths != null)
                    for (int bw : bandwidths)
                        cellBandwidths.add(bw / 1000);
            }
        } catch (Exception e) {
            DebugLogger.add("Bandwidth calculator exception: " + e.getMessage());
        }
        return cellBandwidths;
    }

    @SuppressLint("MissingPermission")
    private void filterImpossibleBands(Context context, SIMData data, TelephonyManager telephony, SIMSlotState slot,
            List<Integer> cellBandwidths) {
        if (data.getPrimaryCell() == null)
            return;

        switch (data.getNetworkGen()) {
            case 2: // 2G cannot use multiple bands at the same time
                for (CellData cellData : data.getActiveCells())
                    if (cellData != data.getPrimaryCell())
                        data.removeActiveCell(cellData);
                break;

            case 3:
                if (data.getPrimaryCell() instanceof CdmaCellData || data.getPrimaryCell() instanceof TdscdmaCellData) {
                    for (CellData cellData : data.getActiveCells())
                        if (cellData != data.getPrimaryCell())
                            data.removeActiveCell(cellData);
                } else if (data.getPrimaryCell() instanceof WcdmaCellData) {
                    for (CellData cellData : data.getActiveCells())
                        if (!(cellData instanceof WcdmaCellData))
                            data.removeActiveCell(cellData);
                }
                break;

            case 4:
                if (cellBandwidths.isEmpty())
                    break; // might as well be the wrong amount of cell bandwidths

                boolean isNsa = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
                        ? getNsaStatus(slot, telephony)
                        : getNsaStatusFromServiceState(telephony);

                if (!isNsa)
                    for (CellData cellData : data.getActiveCells())
                        if (cellData instanceof NrCellData)
                            data.removeActiveCell(cellData);

                boolean clearActiveCells; // possibly port this to 5G SA in future

                if (Build.VERSION.SDK_INT == Build.VERSION_CODES.R) {
                    clearActiveCells = !(SubscriptionManager.getActiveDataSubscriptionId() == telephony
                            .getSubscriptionId());
                } else {
                    int status = getDataStatus(context, slot, telephony);

                    clearActiveCells = switch (status) {
                        case TelephonyManager.DATA_DISCONNECTED,
                                TelephonyManager.DATA_DISCONNECTING, TelephonyManager.DATA_SUSPENDED,
                                TelephonyManager.DATA_UNKNOWN ->
                            true;
                        default -> false;
                    };
                }

                if (clearActiveCells) {
                    DebugLogger.add(data.getActiveCells().length + " active cells have been cleared for SIM "
                            + data.getOperator() + "!");
                    data.clearActiveCells(); // (idle sim = no CA)
                }
                break;
        }
    }

    private void assignBandwidths(SIMData data, List<Integer> cellBandwidths) {
        // after pretty much everything, just before setting general bandwidth. might
        // confuse between multiple NR bands...
        CellData[] activeCells = data.getActiveCells();
        Arrays.sort(activeCells, (a, b) -> {
            boolean invalidA = a.getBandwidth() <= 0;
            boolean invalidB = b.getBandwidth() <= 0;

            if (invalidA != invalidB)
                return Boolean.compare(invalidA, invalidB);

            if (invalidA) {
                boolean isNrA = a instanceof NrCellData;
                boolean isNrB = b instanceof NrCellData;
                if (isNrA != isNrB)
                    return Boolean.compare(isNrB, isNrA);

                if (isNrA) {
                    int freqA = a.getBasicCellData().getFrequency();
                    int freqB = b.getBasicCellData().getFrequency();
                    return Integer.compare(freqB, freqA);
                }
            }

            return 0;
        });

        data.setActiveCells(activeCells);

        List<Integer> availableBandwidths = new ArrayList<>(cellBandwidths);
        for (CellData cell : activeCells) {
            int bw = cell.getBandwidth();
            if (bw > 0 && bw != CELL_INFO_UNAVAILABLE)
                availableBandwidths.remove(Integer.valueOf(bw));
        }

        availableBandwidths.sort(Collections.reverseOrder());

        for (CellData cell : data.getActiveCells()) {
            int bw = cell.getBandwidth();
            if (bw > 0 && bw != CELL_INFO_UNAVAILABLE)
                continue;

            if (cell instanceof NrCellData) {
                int maxBw = getMaximumNrMhz(cell.getBasicCellData().getFrequency());
                Optional<Integer> possibleBw = availableBandwidths.stream().filter(b -> b <= maxBw).findFirst();
                if (possibleBw.isPresent()) {
                    int nrBw = possibleBw.get();
                    cell.setBandwidth(nrBw);
                    availableBandwidths.remove(Integer.valueOf(nrBw));
                }
            } else if (!availableBandwidths.isEmpty()) {
                int lteBw = availableBandwidths.remove(0);
                cell.setBandwidth(lteBw);
            }
        }
    }

    private void fixNrSignal(SIMData data, TelephonyManager telephony) {
        if (data.getPrimaryCell() == null || !(data.getPrimaryCell() instanceof LteCellData))
            return;

        List<NrCellData> nrCells = new ArrayList<>();
        for (CellData cellData : data.getActiveCells()) {
            if (cellData instanceof NrCellData) {
                NrCellData nrCellData = (NrCellData) cellData;
                if (nrCellData.getProcessedSignal() == CELL_INFO_UNAVAILABLE
                        || nrCellData.getRawSignal() == CELL_INFO_UNAVAILABLE
                        || nrCellData.getSignalNoise() == CELL_INFO_UNAVAILABLE
                        || nrCellData.getSignalQuality() == CELL_INFO_UNAVAILABLE)
                    nrCells.add(nrCellData);
            }
        }

        nrCells.sort(
                (a, b) -> Integer.compare(b.getBasicCellData().getFrequency(), a.getBasicCellData().getFrequency()));

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q)
            return;

        List<CellSignalStrengthNr> signalStrengths = new ArrayList<>();
        SignalStrength signalStrength = telephony.getSignalStrength();
        if (signalStrength != null) {
            for (CellSignalStrength cellSignalStrength : signalStrength.getCellSignalStrengths()) {
                if (cellSignalStrength instanceof CellSignalStrengthNr)
                    signalStrengths.add((CellSignalStrengthNr) cellSignalStrength);
            }
        }
        signalStrengths.sort(Comparator.comparingInt(CellSignalStrengthNr::getSsRsrp)); // -110dBm -> -99dBm -> -78dBm

        int limit = Math.min(nrCells.size(), signalStrengths.size());
        for (int i = 0; i < limit; i++) {
            NrCellData nrCell = nrCells.get(i);
            CellSignalStrengthNr ssNr = signalStrengths.get(i);

            if (nrCell.getProcessedSignal() == CELL_INFO_UNAVAILABLE && ssNr.getSsRsrp() != CELL_INFO_UNAVAILABLE)
                nrCell.setProcessedSignal(ssNr.getSsRsrp());

            if (nrCell.getRawSignal() == CELL_INFO_UNAVAILABLE && ssNr.getCsiRsrp() != CELL_INFO_UNAVAILABLE)
                nrCell.setRawSignal(ssNr.getCsiRsrp());

            if (nrCell.getSignalNoise() == CELL_INFO_UNAVAILABLE) {
                if (ssNr.getSsSinr() != CELL_INFO_UNAVAILABLE) {
                    nrCell.setSignalNoise(ssNr.getSsSinr());
                } else if (ssNr.getCsiSinr() != CELL_INFO_UNAVAILABLE) {
                    nrCell.setSignalNoise(ssNr.getCsiSinr());
                    nrCell.setSignalNoiseString("CSI SINR");
                }
            }

            if (nrCell.getSignalQuality() == CELL_INFO_UNAVAILABLE) {
                if (ssNr.getSsRsrq() != CELL_INFO_UNAVAILABLE) {
                    nrCell.setSignalQuality(ssNr.getSsRsrq());
                } else if (ssNr.getCsiRsrq() != CELL_INFO_UNAVAILABLE) {
                    nrCell.setSignalQuality(ssNr.getCsiRsrq());
                    nrCell.setSignalNoiseString("CSI RSRQ");
                }
            }

            if (nrCell.getTimingAdvance() == CELL_INFO_UNAVAILABLE) {
                nrCell.setTimingAdvance(Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
                        ? ssNr.getTimingAdvanceMicros()
                        : CELL_INFO_UNAVAILABLE);
            }
        }
    }

    private void computeActiveBandwidth(SIMData data) {
        if (data.getPrimaryCell() == null)
            return;

        if (!(data.getPrimaryCell().getBandwidth() < 0
                || data.getPrimaryCell().getBandwidth() == CELL_INFO_UNAVAILABLE))
            data.setActiveBw(data.getPrimaryCell().getBandwidth());

        for (CellData cellData : data.getActiveCells()) {
            if (!(cellData.getBandwidth() < 0 || cellData.getBandwidth() == CELL_INFO_UNAVAILABLE)
                    && !data.getPrimaryCell().equals(cellData))
                data.setActiveBw(data.getActiveBw() + cellData.getBandwidth());
        }
    }

    @SuppressLint("MissingPermission")
    public static String getSimCarrier(Context context, TelephonyManager telephony) {
        if (telephony == null || (context != null && !Permissions.check(context, Permissions.READ_PHONE_STATE)))
            return "NetManager";
        return telephony.getNetworkOperatorName();
    }

    @SuppressLint("MissingPermission")
    public static String getSimOperator(Context context, TelephonyManager telephony) {
        if (telephony == null || (context != null && !Permissions.check(context, Permissions.READ_PHONE_STATE)))
            return "NetManager";
        return telephony.getSimOperatorName();
    }

    @SuppressLint("MissingPermission")
    public static String getPlmn(Context context, TelephonyManager telephony) {
        if (telephony == null || (context != null && !Permissions.check(context, Permissions.READ_PHONE_STATE)))
            return "00000";

        String plmn = null;
        try {
            plmn = telephony.getNetworkOperator();
        } catch (Exception ignored) {
        }
        return plmn == null || plmn.isEmpty() ? "00000" : plmn;
    }

    @SuppressLint("MissingPermission")
    public static int getSimNetworkGen(Context context, TelephonyManager telephony) {
        if (telephony == null || (context != null && !Permissions.check(context, Permissions.READ_PHONE_STATE)))
            return -1;

        int networkType = 0;
        try {
            networkType = telephony.getDataNetworkType();
        } catch (Exception ignored) {
        }

        return switch (networkType) {
            case TelephonyManager.NETWORK_TYPE_UNKNOWN -> 0;
            case TelephonyManager.NETWORK_TYPE_GPRS, TelephonyManager.NETWORK_TYPE_EDGE,
                    TelephonyManager.NETWORK_TYPE_CDMA, TelephonyManager.NETWORK_TYPE_1xRTT,
                    TelephonyManager.NETWORK_TYPE_GSM ->
                2;
            case TelephonyManager.NETWORK_TYPE_UMTS, TelephonyManager.NETWORK_TYPE_EVDO_0,
                    TelephonyManager.NETWORK_TYPE_EVDO_A, TelephonyManager.NETWORK_TYPE_EVDO_B,
                    TelephonyManager.NETWORK_TYPE_HSDPA, TelephonyManager.NETWORK_TYPE_HSUPA,
                    TelephonyManager.NETWORK_TYPE_HSPA, TelephonyManager.NETWORK_TYPE_EHRPD,
                    TelephonyManager.NETWORK_TYPE_HSPAP, TelephonyManager.NETWORK_TYPE_TD_SCDMA ->
                3;
            case TelephonyManager.NETWORK_TYPE_LTE, TelephonyManager.NETWORK_TYPE_IWLAN -> 4;
            case TelephonyManager.NETWORK_TYPE_NR -> 5;
            default -> -1;
        };
    }

    @SuppressLint("MissingPermission")
    public static boolean getNsaStatusFromServiceState(TelephonyManager telephony) {
        if (telephony == null)
            return false;

        ServiceState state = null;
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                state = telephony.getServiceState();
        } catch (Exception ignored) {
        }

        if (state != null) {
            String s = state.toString();
            return s.contains("nrState=CONNECTED") || s.contains("nsaState=5") || s.contains("EnDc=true");
        }
        return false;
    }

    @SuppressLint("MissingPermission")
    public static boolean getNsaStatus(SIMSlotState simSlotState, TelephonyManager telephony) {
        boolean result = false;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && simSlotState != null && simSlotState.nsaListener != null)
            result = simSlotState.nsaListener.getNsa();

        if (!result)
            result = getNsaStatusFromServiceState(telephony);

        return result;
    }

    @SuppressLint("MissingPermission")
    public static int getDataStatusFromTelephony(Context context, TelephonyManager telephony) {
        if (telephony == null || (context != null && !Permissions.check(context, Permissions.READ_PHONE_STATE)))
            return -1;
        return telephony.getDataState();
    }

    @SuppressLint("MissingPermission")
    public static int getDataStatus(Context context, SIMSlotState simSlotState, TelephonyManager telephony) {
        int status = -1;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && simSlotState != null
                && simSlotState.dataStateListener != null)
            status = simSlotState.dataStateListener.getState();
        else if (simSlotState != null && simSlotState.legacyPhoneStateListener != null)
            status = simSlotState.legacyPhoneStateListener.getDataState();

        if (status == -1)
            status = getDataStatusFromTelephony(context, telephony);

        return status;
    }

    @SuppressLint("MissingPermission")
    public static CellSignalStrength[] getSignalStrengths(Context context, SIMSlotState simSlotState,
            TelephonyManager telephony) {
        CellSignalStrength[] result = null;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && simSlotState != null
                && simSlotState.signalStrengthsListener != null)
            result = simSlotState.signalStrengthsListener.getLatestSignalStrengths();
        else if (simSlotState != null && simSlotState.legacyPhoneStateListener != null)
            result = simSlotState.legacyPhoneStateListener.getLatestSignalStrengths();

        if (result == null || result.length == 0) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || telephony == null
                    || (context != null && !Permissions.check(context, Permissions.READ_PHONE_STATE)))
                return null;

            SignalStrength signalStrength = telephony.getSignalStrength();
            if (signalStrength == null)
                return null;

            result = signalStrength.getCellSignalStrengths().toArray(new CellSignalStrength[0]);
        }
        return result;
    }

    public void clearSlotState(int simId) {
        lastModemUpdateBySlot.remove(simId);
    }

    private String buildMccMnc(int mcc, int mnc, String simOperator) {
        if (mcc == CellInfo.UNAVAILABLE || mnc == CellInfo.UNAVAILABLE) {
            return UNKNOWN_MCCMNC;
        }

        int mncLen = (simOperator != null && simOperator.length() >= 5)
                ? simOperator.length() - 3
                : (mnc >= 100 ? 3 : 2);

        String mccStr = String.format(Locale.ENGLISH, "%03d", mcc);
        String mncStr = String.format(Locale.ENGLISH, "%0" + mncLen + "d", mnc);

        return mccStr + mncStr;
    }
}