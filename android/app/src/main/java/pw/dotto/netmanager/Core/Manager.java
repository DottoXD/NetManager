package pw.dotto.netmanager.Core;

import android.annotation.SuppressLint;
import android.content.Context;
import android.telephony.CellInfo;
import android.telephony.CellInfoGsm;
import android.telephony.CellInfoLte;
import android.telephony.CellInfoNr;
import android.telephony.CellInfoWcdma;
import android.telephony.NeighboringCellInfo;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import com.google.gson.Gson;
import java.util.ArrayList;
import java.util.List;
import pw.dotto.netmanager.Core.CellInfoData;
import pw.dotto.netmanager.MainActivity;

public class Manager {
  private final MainActivity context;

  private TelephonyManager secondManager;

  public Manager(MainActivity context) {
    this.context = context;
  }

  private TelephonyManager getTelephony() {
    return (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
  }

  private SubscriptionManager getSubscriptionManager() {
    return (SubscriptionManager) context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE);
  }

  @SuppressLint("MissingPermission")
  public String getFullHeaderString() {
    StringBuilder str = new StringBuilder();

    List<SubscriptionInfo> activeSubscriptionList = getSubscriptionManager().getActiveSubscriptionInfoList();
    if(activeSubscriptionList != null) {
            int networkGen = getSimNetworkGen(getTelephony());
            str.append(getTelephony().getNetworkOperatorName()).append(" ").append(networkGen == 0 ? "UNKNOWN" : (networkGen < 0 ? "NO SERVICE" : networkGen + "G"));

            if(activeSubscriptionList.size() > 1) {
              SubscriptionInfo info = activeSubscriptionList.get(1);
              if(secondManager == null) secondManager = getTelephony().createForSubscriptionId(info.getSubscriptionId());

              networkGen = getSimNetworkGen(secondManager);
              str.append(" | ").append(secondManager.getNetworkOperatorName()).append(" ").append(networkGen == 0 ? "UNKNOWN" : (networkGen < 0 ? "NO SERVICE" : networkGen + "G"));
            }
    } else str.append("No service");

    return str.toString().trim();
  }

  @SuppressLint("MissingPermission")
  public String getCarrier() {
    return getTelephony().getNetworkOperatorName();
  }

  @SuppressLint("MissingPermission") //deprecated
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
  public int getSimNetworkData(TelephonyManager telephony) { //temporarily return an int as i'm working on this
    if (telephony == null || !context.checkPermissions())
      return -1;

    for(CellInfo cell : telephony.getAllCellInfo()) {
      switch(cell.getCellConnectionStatus()) { //remember to check timestamp and eventually request an update for each band!!
        case CellInfo.CONNECTION_PRIMARY_SERVING:
          //we found the primary band
          break;
        case CellInfo.CONNECTION_SECONDARY_SERVING:
          //we found (CA bands?)
          break;
        case CellInfo.CONNECTION_NONE:
          //neighboring cell
          break;
        case CellInfo.CONNECTION_UNKNOWN:
          //i'm not too sure if i'll even use this
          break;
      }
    }

    return -1;
  }

  @SuppressLint("MissingPermission")
  public int getSimNetworkData(int simId) {
    switch(simId) {
      case 0:
        return getSimNetworkData(getTelephony());
      case 1:
        return getSimNetworkData(secondManager);
      default:
        return -1;
    }
  }

  @SuppressLint("MissingPermission")
  public int getSimNetworkGen(TelephonyManager telephony) {
    if (telephony == null || !context.checkPermissions())
      return -1;

    switch (telephony.getDataNetworkType()) {
      case TelephonyManager.NETWORK_TYPE_UNKNOWN:
        return 0;

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

  @SuppressLint("MissingPermission")
  public int getSimNetworkGen(int simId) {
    switch(simId) {
      case 0:
        return getSimNetworkGen(getTelephony());
      case 1:
        return getSimNetworkGen(secondManager);
      default:
        return -1;
    }
  }
}
