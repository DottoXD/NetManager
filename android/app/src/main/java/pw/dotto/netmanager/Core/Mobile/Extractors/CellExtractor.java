package pw.dotto.netmanager.Core.Mobile.Extractors;

import android.os.Build;
import android.telephony.CellIdentityCdma;
import android.telephony.CellIdentityGsm;
import android.telephony.CellIdentityLte;
import android.telephony.CellIdentityNr;
import android.telephony.CellIdentityTdscdma;
import android.telephony.CellIdentityWcdma;
import android.telephony.CellInfoCdma;
import android.telephony.CellInfoGsm;
import android.telephony.CellInfoLte;
import android.telephony.CellInfoNr;
import android.telephony.CellInfoTdscdma;
import android.telephony.CellInfoWcdma;
import android.telephony.CellSignalStrengthCdma;
import android.telephony.CellSignalStrengthGsm;
import android.telephony.CellSignalStrengthLte;
import android.telephony.CellSignalStrengthNr;
import android.telephony.CellSignalStrengthTdscdma;
import android.telephony.CellSignalStrengthWcdma;

import androidx.annotation.NonNull;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.GsmCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.LteCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.TdscdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.WcdmaCellData;

public class CellExtractor { // data to be moved out of here
    @NonNull
    public static GsmCellData getGsmCellData(CellInfoGsm baseCell) {
        CellIdentityGsm identityGsm = (CellIdentityGsm) baseCell.getCellIdentity();

        int band = -1;

        CellSignalStrengthGsm signalGsm = (CellSignalStrengthGsm) baseCell.getCellSignalStrength();
        return new GsmCellData(
                String.valueOf(identityGsm.getCid()),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ? signalGsm.getRssi() : -1),
                signalGsm.getDbm(),
                identityGsm.getArfcn(),
                identityGsm.getBsic(),
                identityGsm.getLac(),
                -1, // signalGsm.getRsrq(),
                -1, // signalGsm.getSnr(),
                (signalGsm.getTimingAdvance() == Integer.MAX_VALUE ? -1 : signalGsm.getTimingAdvance()),
                -1, // identityGsm.getBandwidth(),
                band,
                baseCell.isRegistered());
    }

    @NonNull
    public static CdmaCellData getCdmaCellData(CellInfoCdma baseCell) {
        CellIdentityCdma identityCdma = (CellIdentityCdma) baseCell.getCellIdentity();

        int band = -1;

        CellSignalStrengthCdma signalCdma = (CellSignalStrengthCdma) baseCell.getCellSignalStrength();
        return new CdmaCellData(
                String.valueOf(identityCdma.getBasestationId()),
                signalCdma.getCdmaDbm(),
                -1, // signalCdma.getCdmaEcio(),
                -1, // ??,
                identityCdma.getSystemId(),
                -1, // identityCdma.getTac(),
                -1, // signalCdma.getRsrq(),
                signalCdma.getEvdoSnr(),
                -1, // signalCdma.getTimingAdvance(),
                -1, // identityCdma.getBandwidth(),
                band,
                baseCell.isRegistered());
    }

    @NonNull
    public static TdscdmaCellData getTdscdmaCellData(CellInfoTdscdma baseCell) {
        CellIdentityTdscdma identityTdscdma = (CellIdentityTdscdma) baseCell.getCellIdentity();

        int band = -1;

        CellSignalStrengthTdscdma signalTdscdma = (CellSignalStrengthTdscdma) baseCell.getCellSignalStrength();
        return new TdscdmaCellData(
                String.valueOf(identityTdscdma.getCid()),
                signalTdscdma.getDbm(),
                signalTdscdma.getRscp(),
                identityTdscdma.getUarfcn(),
                identityTdscdma.getCpid(),
                identityTdscdma.getLac(),
                -1, // signalTdscdma.getRsrq(),
                -1, // signalTdscdma.getSnr(),
                -1, // signalTdscdma.getTimingAdvance(),
                -1, // identityTdscdma.getBandwidth(),
                band,
                baseCell.isRegistered());
    }

    @NonNull
    public static WcdmaCellData getWcdmaCellData(CellInfoWcdma baseCell) {
        CellIdentityWcdma identityWcdma = (CellIdentityWcdma) baseCell.getCellIdentity();

        int band = -1;

        CellSignalStrengthWcdma signalWcdma = (CellSignalStrengthWcdma) baseCell.getCellSignalStrength();
        return new WcdmaCellData(
                String.valueOf(identityWcdma.getCid()),
                -1, // signalWcdma.getDbm(),
                signalWcdma.getDbm(),
                identityWcdma.getUarfcn(),
                identityWcdma.getPsc(),
                identityWcdma.getLac(),
                -1, // signalWcdma.getRsrq(),
                -1, // signalWcdma.getRssnr(),
                -1, // signalWcdma.getTimingAdvance(),
                -1, // identityWcdma.getBandwidth(),
                band,
                baseCell.isRegistered());
    }

    @NonNull
    public static LteCellData getLteCellData(CellInfoLte baseCell) {
        CellIdentityLte identityLte = (CellIdentityLte) baseCell.getCellIdentity();

        int band = -1;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            int[] bands = identityLte.getBands();
            if (bands.length > 0)
                band = bands[0];
        }

        CellSignalStrengthLte signalLte = (CellSignalStrengthLte) baseCell.getCellSignalStrength();
        return new LteCellData(
                String.valueOf(identityLte.getCi()),
                signalLte.getRssi(),
                signalLte.getRsrp(),
                identityLte.getEarfcn(),
                identityLte.getPci(),
                identityLte.getTac(),
                signalLte.getRsrq(),
                signalLte.getRssnr(),
                (signalLte.getTimingAdvance() == Integer.MAX_VALUE ? -1 : signalLte.getTimingAdvance()),
                (identityLte.getBandwidth() == Integer.MAX_VALUE ? -1 : identityLte.getBandwidth() / 1000),
                band,
                baseCell.isRegistered());
    }

    @NonNull
    public static NrCellData getNrCellData(CellInfoNr baseCell) {
        CellIdentityNr identityNr = (CellIdentityNr) baseCell.getCellIdentity();

        int band = -1;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            int[] bands = identityNr.getBands();
            if (bands.length > 0)
                band = bands[0];
        }

        CellSignalStrengthNr signalNr = (CellSignalStrengthNr) baseCell.getCellSignalStrength();
        return new NrCellData(
                String.valueOf(identityNr.getNci()),
                signalNr.getCsiRsrp(),
                signalNr.getSsRsrp(),
                identityNr.getNrarfcn(),
                identityNr.getPci(),
                identityNr.getTac(),
                signalNr.getSsRsrq(),
                signalNr.getSsSinr(),
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
                        ? (signalNr.getTimingAdvanceMicros() == Integer.MAX_VALUE ? -1
                                : signalNr.getTimingAdvanceMicros())
                        : -1),
                -1, // identityNr.getBandwidth()
                band,
                baseCell.isRegistered());
    }
}
