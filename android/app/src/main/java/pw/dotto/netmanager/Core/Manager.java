package pw.dotto.netmanager.Core;

import android.annotation.SuppressLint;
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
import android.telephony.NetworkRegistrationInfo;
import android.telephony.ServiceState;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;

import java.util.List;
import java.util.Objects;

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
  private final Context context;

  private TelephonyManager firstManager;
  private TelephonyManager secondManager;

  public Manager(Context context) {
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
    if (activeSubscriptionList != null) { // always at least 1
      if (firstManager == null) {
        SubscriptionInfo firstInfo = activeSubscriptionList.get(0);
        firstManager = getTelephony().createForSubscriptionId(firstInfo.getSubscriptionId());
      }

      int networkGen = getSimNetworkGen(firstManager);
      boolean nrSa = networkGen == 5;

      if (networkGen == 4) {
        ServiceState state = firstManager.getServiceState();

        if (state != null && (state.toString().contains("nrState=CONNECTED")
            || state.toString().contains("nrState=NOT_RESTRICTED")))
          networkGen = 5;
      }

      str.append(firstManager.getNetworkOperatorName()).append(" ").append(
          networkGen == 0 ? "UNKNOWN" : (networkGen < 0 ? "NO SERVICE" : networkGen + "G" + (nrSa ? " (SA)" : "")));

      if (activeSubscriptionList.size() > 1) {
        SubscriptionInfo secondInfo = activeSubscriptionList.get(1);
        if (secondManager == null)
          secondManager = getTelephony().createForSubscriptionId(secondInfo.getSubscriptionId());

        networkGen = getSimNetworkGen(secondManager);
        nrSa = networkGen == 5;

        if (networkGen == 4) {
          ServiceState state = secondManager.getServiceState();

          if (state != null && (state.toString().contains("nrState=CONNECTED")
              || state.toString().contains("nrState=NOT_RESTRICTED")))
            networkGen = 5;
        }

        str.append(" | ").append(secondManager.getNetworkOperatorName()).append(" ").append(
            networkGen == 0 ? "UNKNOWN" : (networkGen < 0 ? "NO SERVICE" : networkGen + "G" + (nrSa ? " (SA)" : "")));
      }
    } else
      str.append("No service");

    return str.toString().trim();
  }

  @SuppressLint("MissingPermission")
  public String getSimCarrier(TelephonyManager telephony) {
    if (telephony == null || !Utils.checkPermissions(context))
      return "NetManager";

    return telephony.getNetworkOperatorName();
  }

  @SuppressLint("MissingPermission")
  public String getSimCarrier(int simId) {
    switch (simId) {
      case 0:
        return getSimCarrier(firstManager);
      case 1:
        return getSimCarrier(secondManager);
      default:
        return "NetManager";
    }
  }

  @SuppressLint("MissingPermission")
  public String getSimOperator(TelephonyManager telephony) {
    if (telephony == null || !Utils.checkPermissions(context))
      return "NetManager";

    return telephony.getSimOperatorName();
  }

  @SuppressLint("MissingPermission")
  public String getSimOperator(int simId) {
    switch (simId) {
      case 0:
        return getSimOperator(firstManager);
      case 1:
        return getSimOperator(secondManager);
      default:
        return "NetManager";
    }
  }

  @SuppressLint("MissingPermission")
  public SIMData getSimNetworkData(TelephonyManager telephony) {
    if (!Utils.checkPermissions(context))
      return null;

    if (telephony == null) {
      updateTelephonyManagers();
      return null;
    }

    SIMData data = new SIMData(getSimCarrier(telephony), getSimOperator(telephony), getSimNetworkGen(telephony),
        telephony.getSimOperator());
    String simOperator = telephony.getSimOperator();

    // telephony.requestCellInfoUpdate();
    for (CellInfo baseCell : telephony.getAllCellInfo()) {

      switch (baseCell.getCellConnectionStatus()) {
        case CellInfo.CONNECTION_PRIMARY_SERVING:
          if (baseCell instanceof CellInfoGsm) {
            GsmCellData gsmCellData = CellExtractors.getGsmCellData((CellInfoGsm) baseCell);
            String mccMnc = ((CellInfoGsm) baseCell).getCellIdentity().getMccString()
                + ((CellInfoGsm) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.setPrimaryCell(gsmCellData);
          } else if (baseCell instanceof CellInfoCdma) {
            CdmaCellData cdmaCellData = CellExtractors.getCdmaCellData((CellInfoCdma) baseCell);
            data.setPrimaryCell(cdmaCellData);
          } else if (baseCell instanceof CellInfoTdscdma) {
            TdscmaCellData tdscdmaCellData = CellExtractors.getTdscmaCellData((CellInfoTdscdma) baseCell);
            String mccMnc = ((CellInfoTdscdma) baseCell).getCellIdentity().getMccString()
                + ((CellInfoTdscdma) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.setPrimaryCell(tdscdmaCellData);
          } else if (baseCell instanceof CellInfoWcdma) {
            WcdmaCellData wcdmaCellData = CellExtractors.getWcdmaCellData((CellInfoWcdma) baseCell);
            String mccMnc = ((CellInfoWcdma) baseCell).getCellIdentity().getMccString()
                + ((CellInfoWcdma) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.setPrimaryCell(wcdmaCellData);
          } else if (baseCell instanceof CellInfoLte) {
            LteCellData lteCellData = CellExtractors.getLteCellData((CellInfoLte) baseCell);
            String mccMnc = ((CellInfoLte) baseCell).getCellIdentity().getMccString()
                + ((CellInfoLte) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.setPrimaryCell(lteCellData);
          } else if (baseCell instanceof CellInfoNr) {
            NrCellData nrCellData = CellExtractors.getNrCellData((CellInfoNr) baseCell);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
              CellIdentityNr identity = (CellIdentityNr) baseCell.getCellIdentity();
              String mccMnc = identity.getMccString() + identity.getMncString();

              if (mccMnc.equals(simOperator))
                data.setPrimaryCell(nrCellData);
            } else
              data.setPrimaryCell(nrCellData);
          }

          break;
        case CellInfo.CONNECTION_SECONDARY_SERVING:
          if (baseCell instanceof CellInfoGsm) {
            GsmCellData gsmCellData = CellExtractors.getGsmCellData((CellInfoGsm) baseCell);
            String mccMnc = ((CellInfoGsm) baseCell).getCellIdentity().getMccString()
                + ((CellInfoGsm) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.addActiveCell(gsmCellData);
          } else if (baseCell instanceof CellInfoCdma) {
            CdmaCellData cdmaCellData = CellExtractors.getCdmaCellData((CellInfoCdma) baseCell);
            data.addActiveCell(cdmaCellData);
          } else if (baseCell instanceof CellInfoTdscdma) {
            TdscmaCellData tdscdmaCellData = CellExtractors.getTdscmaCellData((CellInfoTdscdma) baseCell);
            String mccMnc = ((CellInfoTdscdma) baseCell).getCellIdentity().getMccString()
                + ((CellInfoTdscdma) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.addActiveCell(tdscdmaCellData);
          } else if (baseCell instanceof CellInfoWcdma) {
            WcdmaCellData wcdmaCellData = CellExtractors.getWcdmaCellData((CellInfoWcdma) baseCell);
            String mccMnc = ((CellInfoWcdma) baseCell).getCellIdentity().getMccString()
                + ((CellInfoWcdma) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.addActiveCell(wcdmaCellData);
          } else if (baseCell instanceof CellInfoLte) {
            LteCellData lteCellData = CellExtractors.getLteCellData((CellInfoLte) baseCell);
            String mccMnc = ((CellInfoLte) baseCell).getCellIdentity().getMccString()
                + ((CellInfoLte) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.addActiveCell(lteCellData);
          } else if (baseCell instanceof CellInfoNr) {
            NrCellData nrCellData = CellExtractors.getNrCellData((CellInfoNr) baseCell);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
              CellIdentityNr identity = (CellIdentityNr) baseCell.getCellIdentity();
              String mccMnc = identity.getMccString() + identity.getMncString();

              if (mccMnc.equals(simOperator))
                data.addActiveCell(nrCellData);
            } else
              data.addActiveCell(nrCellData);
          }

          break;
        case CellInfo.CONNECTION_NONE:
          if (baseCell instanceof CellInfoGsm) {
            GsmCellData gsmCellData = CellExtractors.getGsmCellData((CellInfoGsm) baseCell);
            String mccMnc = ((CellInfoGsm) baseCell).getCellIdentity().getMccString()
                + ((CellInfoGsm) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.addNeighborCell(gsmCellData);
          } else if (baseCell instanceof CellInfoCdma) {
            CdmaCellData cdmaCellData = CellExtractors.getCdmaCellData((CellInfoCdma) baseCell);
            data.addNeighborCell(cdmaCellData);
          } else if (baseCell instanceof CellInfoTdscdma) {
            TdscmaCellData tdscdmaCellData = CellExtractors.getTdscmaCellData((CellInfoTdscdma) baseCell);
            String mccMnc = ((CellInfoTdscdma) baseCell).getCellIdentity().getMccString()
                + ((CellInfoTdscdma) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.addNeighborCell(tdscdmaCellData);
          } else if (baseCell instanceof CellInfoWcdma) {
            WcdmaCellData wcdmaCellData = CellExtractors.getWcdmaCellData((CellInfoWcdma) baseCell);
            String mccMnc = ((CellInfoWcdma) baseCell).getCellIdentity().getMccString()
                + ((CellInfoWcdma) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.addNeighborCell(wcdmaCellData);
          } else if (baseCell instanceof CellInfoLte) {
            LteCellData lteCellData = CellExtractors.getLteCellData((CellInfoLte) baseCell);
            String mccMnc = ((CellInfoLte) baseCell).getCellIdentity().getMccString()
                + ((CellInfoLte) baseCell).getCellIdentity().getMncString();

            if (mccMnc.equals(simOperator))
              data.addNeighborCell(lteCellData);
          } else if (baseCell instanceof CellInfoNr) {
            NrCellData nrCellData = CellExtractors.getNrCellData((CellInfoNr) baseCell);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
              CellIdentityNr identity = (CellIdentityNr) baseCell.getCellIdentity();
              String mccMnc = identity.getMccString() + identity.getMncString();

              if (mccMnc.equals(simOperator))
                data.addNeighborCell(nrCellData);
            } else
              data.addNeighborCell(nrCellData);
          }

          break;
        case CellInfo.CONNECTION_UNKNOWN:
          // i'm not too sure if i'll even use this
          break;
      }
    }

    if (data.getPrimaryCell() != null)
      data.getPrimaryCell().setBasicCellData(DataExtractor.getBasicData(data.getPrimaryCell()));
    for (CellData cellData : data.getActiveCells()) {
      cellData.setBasicCellData(DataExtractor.getBasicData(cellData));
    }

    for (CellData cellData : data.getNeighborCells()) {
      cellData.setBasicCellData(DataExtractor.getBasicData(cellData));
    }

    if (data.getPrimaryCell() != null &&
        data.getPrimaryCell() instanceof LteCellData) {

      data.setActiveBw(data.getPrimaryCell().getBandwidth());
      for (CellData cellData : data.getActiveCells()) {
        data.setActiveBw(data.getActiveBw() + cellData.getBandwidth());
      }
    }

    return data;
  }

  @SuppressLint("MissingPermission")
  public SIMData getSimNetworkData(int simId) {
    switch (simId) {
      case 0:
        return getSimNetworkData(firstManager);
      case 1:
        return getSimNetworkData(secondManager);
      default:
        return null;
    }
  }

  @SuppressLint("MissingPermission")
  public int getSimNetworkGen(TelephonyManager telephony) {
    if (telephony == null || !Utils.checkPermissions(context))
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
        // Check for NR NSA
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
    switch (simId) {
      case 0:
        return getSimNetworkGen(firstManager);
      case 1:
        return getSimNetworkGen(secondManager);
      default:
        return -1;
    }
  }

  private void updateTelephonyManagers() {
    SubscriptionManager manager = getSubscriptionManager();
    if (!Utils.checkPermissions(context) || manager == null)
      return;

    @SuppressLint("MissingPermission")
    List<SubscriptionInfo> subscriptions = manager.getActiveSubscriptionInfoList(); // add safety check

    if (subscriptions == null)
      return;

    if (!subscriptions.isEmpty()) {
      int firstId = subscriptions.get(0).getSubscriptionId();
      firstManager = ((TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE))
          .createForSubscriptionId(firstId);
    }

    if (subscriptions.size() >= 2) {
      int secondId = subscriptions.get(1).getSubscriptionId();
      secondManager = ((TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE))
          .createForSubscriptionId(secondId);
    }
  }
}
