package pw.dotto.netmanager.Core;

import android.annotation.SuppressLint;
import android.content.Context;
import android.telephony.CellInfo;
import android.telephony.CellInfoCdma;
import android.telephony.CellInfoGsm;
import android.telephony.CellInfoLte;
import android.telephony.CellInfoNr;
import android.telephony.CellInfoTdscdma;
import android.telephony.CellInfoWcdma;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;

import java.util.List;
import pw.dotto.netmanager.Core.MobileInfo.CellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.GsmCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.LteCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.TdscmaCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.WcdmaCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellExtractors;
import pw.dotto.netmanager.Core.MobileInfo.DataExtractor;
import pw.dotto.netmanager.Core.MobileInfo.SIMData;
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
      boolean nrSa = networkGen == 5 && true; //got to replace true with the actual check
      str.append(getTelephony().getNetworkOperatorName()).append(" ").append(networkGen == 0 ? "UNKNOWN" : (networkGen < 0 ? "NO SERVICE" : networkGen + "G" + (nrSa ? " (SA)" : "")));

      if(activeSubscriptionList.size() > 1) {
        SubscriptionInfo info = activeSubscriptionList.get(1);
        if(secondManager == null) secondManager = getTelephony().createForSubscriptionId(info.getSubscriptionId());

        networkGen = getSimNetworkGen(secondManager);
        nrSa = networkGen == 5 && true; //got to replace true with the actual check
        str.append(" | ").append(secondManager.getNetworkOperatorName()).append(" ").append(networkGen == 0 ? "UNKNOWN" : (networkGen < 0 ? "NO SERVICE" : networkGen + "G" + (nrSa ? " (SA)" : "")));
      }
    } else str.append("No service");

    return str.toString().trim();
  }

  @SuppressLint("MissingPermission")
  public String getSimCarrier(TelephonyManager telephony) {
    if (telephony == null || !context.checkPermissions())
      return "NetManager";

    return telephony.getNetworkOperatorName();
  }

  @SuppressLint("MissingPermission")
  public String getSimCarrier(int simId) {
    switch(simId) {
      case 0:
        return getSimCarrier(getTelephony());
      case 1:
        return getSimCarrier(secondManager);
      default:
        return "NetManager";
    }
  }

  @SuppressLint("MissingPermission")
  public String getSimOperator(TelephonyManager telephony) {
    if (telephony == null || !context.checkPermissions())
      return "NetManager";

    return telephony.getSimOperatorName();
  }

  @SuppressLint("MissingPermission")
  public String getSimOperator(int simId) {
    switch(simId) {
      case 0:
        return getSimOperator(getTelephony());
      case 1:
        return getSimOperator(secondManager);
      default:
        return "NetManager";
    }
  }

  @SuppressLint("MissingPermission")
  public SIMData getSimNetworkData(TelephonyManager telephony) { //temporarily return an int as i'm working on this
    if (telephony == null || !context.checkPermissions())
      return null;

    SIMData data = new SIMData(getSimCarrier(telephony), getSimOperator(telephony), getSimNetworkGen(telephony), telephony.getSimOperator());

    for (CellInfo baseCell : telephony.getAllCellInfo()) {
      switch (baseCell.getCellConnectionStatus()) { //remember to check timestamp and eventually request an update for each band!!
        case CellInfo.CONNECTION_PRIMARY_SERVING:
          if (baseCell instanceof CellInfoGsm) {
            GsmCellData gsmCellData = CellExtractors.getGsmCellData((CellInfoGsm) baseCell);
            data.setPrimaryCell(gsmCellData);
          } else if (baseCell instanceof CellInfoCdma) {
            CdmaCellData cdmaCellData = CellExtractors.getCdmaCellData((CellInfoCdma) baseCell);
            data.setPrimaryCell(cdmaCellData);
          } else if (baseCell instanceof CellInfoTdscdma) {
            TdscmaCellData tdscdmaCellData = CellExtractors.getTdscmaCellData((CellInfoTdscdma) baseCell);
            data.setPrimaryCell(tdscdmaCellData);
          } else if (baseCell instanceof CellInfoWcdma) {
            WcdmaCellData wcdmaCellData = CellExtractors.getWcdmaCellData((CellInfoWcdma) baseCell);
            data.setPrimaryCell(wcdmaCellData);
          } else if (baseCell instanceof CellInfoLte) {
            LteCellData lteCellData = CellExtractors.getLteCellData((CellInfoLte) baseCell);
            data.setPrimaryCell(lteCellData);
          } else if (baseCell instanceof CellInfoNr) {
            NrCellData nrCellData = CellExtractors.getNrCellData((CellInfoNr) baseCell);
            data.setPrimaryCell(nrCellData);
          }

          break;
        case CellInfo.CONNECTION_SECONDARY_SERVING:
          if (baseCell instanceof CellInfoGsm) {
            GsmCellData gsmCellData = CellExtractors.getGsmCellData((CellInfoGsm) baseCell);
            data.addActiveCell(gsmCellData);
          } else if (baseCell instanceof CellInfoCdma) {
            CdmaCellData cdmaCellData = CellExtractors.getCdmaCellData((CellInfoCdma) baseCell);
            data.addActiveCell(cdmaCellData);
          } else if (baseCell instanceof CellInfoTdscdma) {
            TdscmaCellData tdscdmaCellData = CellExtractors.getTdscmaCellData((CellInfoTdscdma) baseCell);
            data.addActiveCell(tdscdmaCellData);
          } else if (baseCell instanceof CellInfoWcdma) {
            WcdmaCellData wcdmaCellData = CellExtractors.getWcdmaCellData((CellInfoWcdma) baseCell);
            data.addActiveCell(wcdmaCellData);
          } else if (baseCell instanceof CellInfoLte) {
            LteCellData lteCellData = CellExtractors.getLteCellData((CellInfoLte) baseCell);
            data.addActiveCell(lteCellData);
          } else if (baseCell instanceof CellInfoNr) {
            NrCellData nrCellData = CellExtractors.getNrCellData((CellInfoNr) baseCell);
            data.addActiveCell(nrCellData);
          }

          break;
        case CellInfo.CONNECTION_NONE:
          if (baseCell instanceof CellInfoGsm) {
            GsmCellData gsmCellData = CellExtractors.getGsmCellData((CellInfoGsm) baseCell);
            data.addNeighborCell(gsmCellData);
          } else if (baseCell instanceof CellInfoCdma) {
            CdmaCellData cdmaCellData = CellExtractors.getCdmaCellData((CellInfoCdma) baseCell);
            data.addNeighborCell(cdmaCellData);
          } else if (baseCell instanceof CellInfoTdscdma) {
            TdscmaCellData tdscdmaCellData = CellExtractors.getTdscmaCellData((CellInfoTdscdma) baseCell);
            data.addNeighborCell(tdscdmaCellData);
          } else if (baseCell instanceof CellInfoWcdma) {
            WcdmaCellData wcdmaCellData = CellExtractors.getWcdmaCellData((CellInfoWcdma) baseCell);
            data.addNeighborCell(wcdmaCellData);
          } else if (baseCell instanceof CellInfoLte) {
            LteCellData lteCellData = CellExtractors.getLteCellData((CellInfoLte) baseCell);
            data.addNeighborCell(lteCellData);
          } else if (baseCell instanceof CellInfoNr) {
            NrCellData nrCellData = CellExtractors.getNrCellData((CellInfoNr) baseCell);
            data.addNeighborCell(nrCellData);
          }

          break;
        case CellInfo.CONNECTION_UNKNOWN:
          //i'm not too sure if i'll even use this
          break;
      }
    }

    data.getPrimaryCell().setBasicCellData(DataExtractor.getBasicData(data.getPrimaryCell()));
    for(CellData cellData : data.getActiveCells()) {
      cellData.setBasicCellData(cellData.getBasicCellData());
    }

    for(CellData cellData : data.getNeighborCells()) {
      cellData.setBasicCellData(cellData.getBasicCellData());
    }

    if (
            data.getPrimaryCell() != null &&
            data.getPrimaryCell() instanceof LteCellData
    ) {
      for (CellData cellData : data.getActiveCells()) {
        data.setActiveBw(data.getActiveBw() + cellData.getBandwidth());
      }
    }

    return data;
  }

  @SuppressLint("MissingPermission")
  public SIMData getSimNetworkData(int simId) {
    switch(simId) {
      case 0:
        return getSimNetworkData(getTelephony());
      case 1:
        return getSimNetworkData(secondManager);
      default:
        return null;
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
        //Check for NR NSA
        return 4;

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
