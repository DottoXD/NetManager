package pw.dotto.netmanager.Core;

import android.annotation.SuppressLint;
import android.content.Context;
import android.telephony.CellInfo;
import android.telephony.CellInfoGsm;
import android.telephony.CellInfoLte;
import android.telephony.CellInfoNr;
import android.telephony.CellInfoWcdma;
import android.telephony.TelephonyManager;
import com.google.gson.Gson;
import java.util.ArrayList;
import java.util.List;
import pw.dotto.netmanager.Core.CellInfoData;
import pw.dotto.netmanager.MainActivity;

public class Manager {
  private final MainActivity context;

  public Manager(MainActivity context) {
    this.context = context;
  }

  private TelephonyManager getTelephony() {
    return (TelephonyManager) context.getSystemService(
        Context.TELEPHONY_SERVICE);
  }

  @SuppressLint("MissingPermission")
  public String getCarrier() {
    return getTelephony().getNetworkOperatorName();
  }

  @SuppressLint("MissingPermission")
  public String getNetworkData() {
    List<CellInfo> cellInfoList = getTelephony().getAllCellInfo();
    List<CellInfoData> dataList = new ArrayList<>();
    Gson gson = new Gson();

    for (CellInfo cellInfo : cellInfoList) {
      CellInfoData data;
      if (cellInfo instanceof CellInfoGsm) {
        CellInfoGsm cellInfoGsm = (CellInfoGsm) cellInfo;
        data = new CellInfoData(cellInfoGsm.isRegistered(),
            String.valueOf(cellInfoGsm.getCellIdentity().getCid()), "GSM",
            String.valueOf(cellInfoGsm.getCellIdentity().getArfcn()),
            String.valueOf(cellInfoGsm.getCellIdentity().getBsic()),
            String.valueOf(cellInfoGsm.getCellIdentity().getLac()));
      } else if (cellInfo instanceof CellInfoWcdma) {
        CellInfoWcdma cellInfoWcdma = (CellInfoWcdma) cellInfo;
        data = new CellInfoData(cellInfoWcdma.isRegistered(),
            String.valueOf(cellInfoWcdma.getCellIdentity().getCid()), "WCDMA",
            String.valueOf(cellInfoWcdma.getCellIdentity().getUarfcn()),
            String.valueOf(cellInfoWcdma.getCellIdentity().getPsc()),
            String.valueOf(cellInfoWcdma.getCellIdentity().getLac()),
            String.valueOf(cellInfoWcdma.getCellSignalStrength().getEcNo()));
      } else if (cellInfo instanceof CellInfoLte) {
        CellInfoLte cellInfoLte = (CellInfoLte) cellInfo;
        data = new CellInfoData(cellInfoLte.isRegistered(),
            String.valueOf(cellInfoLte.getCellIdentity().getCi()), "LTE",
            String.valueOf(cellInfoLte.getCellIdentity().getEarfcn()),
            String.valueOf(cellInfoLte.getCellIdentity().getPci()),
            String.valueOf(cellInfoLte.getCellIdentity().getTac()),
            String.valueOf(cellInfoLte.getCellIdentity().getBandwidth()),
            String.valueOf(cellInfoLte.getCellIdentity().getBands()),
            String.valueOf(cellInfoLte.getCellSignalStrength().getRsrp()),
            String.valueOf(cellInfoLte.getCellSignalStrength().getRsrq()),
            String.valueOf(cellInfoLte.getCellSignalStrength().getRssi()),
            String.valueOf(cellInfoLte.getCellSignalStrength().getRssnr()),
            String.valueOf(
                cellInfoLte.getCellSignalStrength().getTimingAdvance()));
      } else {
        throw new UnsupportedOperationException("Unsupported");
      }
      dataList.add(data);
    }

    return gson.toJson(dataList);
  }

  @SuppressLint("MissingPermission")
  public int getNetworkGen() {
    TelephonyManager telephony = getTelephony();
    if (!context.checkPermissions())
      return -1;

    switch (telephony.getDataNetworkType()) {
      case TelephonyManager.NETWORK_TYPE_UNKNOWN:
        return -1;

      case TelephonyManager.NETWORK_TYPE_GPRS:
      case TelephonyManager.NETWORK_TYPE_EDGE:
      case TelephonyManager.NETWORK_TYPE_CDMA:
      case TelephonyManager.NETWORK_TYPE_1xRTT:
      case TelephonyManager.NETWORK_TYPE_GSM:
        return 2;

      case TelephonyManager.NETWORK_TYPE_UMTS:
      case TelephonyManager.NETWORK_TYPE_EVDO_0:
      case TelephonyManager.NETWORK_TYPE_EVDO_A:
      case TelephonyManager.NETWORK_TYPE_EVDO_B:
      case TelephonyManager.NETWORK_TYPE_HSDPA:
      case TelephonyManager.NETWORK_TYPE_HSUPA:
      case TelephonyManager.NETWORK_TYPE_HSPA:
      case TelephonyManager.NETWORK_TYPE_EHRPD:
      case TelephonyManager.NETWORK_TYPE_HSPAP:
      case TelephonyManager.NETWORK_TYPE_TD_SCDMA:
        return 3;

      case TelephonyManager.NETWORK_TYPE_LTE:
      case TelephonyManager.NETWORK_TYPE_IWLAN:
        return 4;

      case TelephonyManager.NETWORK_TYPE_NR:
        return 5;

      default:
        return -1;
    }
  }
}
