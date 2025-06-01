package pw.dotto.netmanager.Core;

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
import android.telephony.NetworkRegistrationInfo;
import android.telephony.PhoneStateListener;
import android.telephony.ServiceState;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyCallback;
import android.telephony.TelephonyDisplayInfo;
import android.telephony.TelephonyManager;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import java.util.Date;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.Executor;

import pw.dotto.netmanager.Core.MobileInfo.CellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.GsmCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.LteCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.TdscmaCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.WcdmaCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellExtractors;
import pw.dotto.netmanager.Core.MobileInfo.DataExtractor;
import pw.dotto.netmanager.Core.MobileInfo.DisplayInfoListener;
import pw.dotto.netmanager.Core.MobileInfo.SIMData;
import pw.dotto.netmanager.MainActivity;

public class Manager {
  private final Context context;

  private TelephonyManager firstManager;
  private TelephonyManager secondManager;

  private DisplayInfoListener[] nsa = { null, null };
  private Date lastModemUpdate = null;
  private static final int updateInterval = 10;

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
    if (!Utils.checkPermissions(context))
      return "UNKNOWN";

    StringBuilder str = new StringBuilder();

    List<SubscriptionInfo> activeSubscriptionList = getSubscriptionManager().getActiveSubscriptionInfoList();
    if (activeSubscriptionList != null) { // always at least 1
      if (firstManager == null) {
        SubscriptionInfo firstInfo = activeSubscriptionList.get(0);
        firstManager = getTelephony().createForSubscriptionId(firstInfo.getSubscriptionId());
      }

      int networkGen = getSimNetworkGen(firstManager);
      boolean nrSa = networkGen == 5;

      if (networkGen == 4 && getNsaStatus(0))
        networkGen = 5;

      if (firstManager.getNetworkOperatorName().trim().isEmpty())
        return "NO SERVICE";

      str.append(firstManager.getNetworkOperatorName()).append(" ").append(
          networkGen == 0 ? "UNKNOWN" : (networkGen < 0 ? "NO SERVICE" : networkGen + "G" + (nrSa ? " (SA)" : "")));

      if (activeSubscriptionList.size() > 1) {
        SubscriptionInfo secondInfo = activeSubscriptionList.get(1);
        if (secondManager == null)
          secondManager = getTelephony().createForSubscriptionId(secondInfo.getSubscriptionId());

        networkGen = getSimNetworkGen(secondManager);
        nrSa = networkGen == 5;

        if (networkGen == 4 && getNsaStatus(1))
          networkGen = 5;

        if (secondManager.getNetworkOperatorName() != null && !secondManager.getNetworkOperatorName().trim().isEmpty())
          str.append(" | ").append(secondManager.getNetworkOperatorName()).append(" ").append(
              networkGen == 0 ? "UNKNOWN" : (networkGen < 0 ? "NO SERVICE" : networkGen + "G" + (nrSa ? " (SA)" : "")));
      }
    } else
      str.append("NO SERVICE");

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

    try {
      if (lastModemUpdate == null || (context instanceof Activity
          && lastModemUpdate.toInstant().plusSeconds(updateInterval).isBefore(new Date().toInstant()))) {
        Log.w("pw.dotto.netmanager", "Requesting updated cell info.");
        telephony.requestCellInfoUpdate(ContextCompat.getMainExecutor(context),
            new TelephonyManager.CellInfoCallback() {
              @Override
              public void onCellInfo(@NonNull List<CellInfo> cellInfo) {
                Log.w("pw.dotto.netmanager", "Found new cell: " + cellInfo);
                lastModemUpdate = new Date();
              }
            });
      }
    } catch (Exception e) {
      Log.w("pw.dotto.netmanager", e.getMessage() == null ? "Error." : e.getMessage());
    }

    // telephony.requestCellInfoUpdate();
    for (CellInfo baseCell : telephony.getAllCellInfo()) {
      Log.w("pw.dotto.netmanager", "Detected cell: " + baseCell.toString());

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

            lteCellData.setCellIdentifier(mccMnc); // test
            /* if (mccMnc.equals(simOperator)) */
            data.addActiveCell(lteCellData);
          } else if (baseCell instanceof CellInfoNr) {
            NrCellData nrCellData = CellExtractors.getNrCellData((CellInfoNr) baseCell);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
              CellIdentityNr identity = (CellIdentityNr) baseCell.getCellIdentity();
              String mccMnc = identity.getMccString() + identity.getMncString();

              nrCellData.setCellIdentifier(mccMnc); // test
              /* if (mccMnc.equals(simOperator)) */
              data.addActiveCell(nrCellData);
            } else
              data.addActiveCell(nrCellData);
          }

          break;
        case CellInfo.CONNECTION_NONE:
        case CellInfo.CONNECTION_UNKNOWN:
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

            lteCellData.setCellIdentifier(mccMnc); // test

            /* if (mccMnc.equals(simOperator)) */
            data.addNeighborCell(lteCellData);
          } else if (baseCell instanceof CellInfoNr) {
            NrCellData nrCellData = CellExtractors.getNrCellData((CellInfoNr) baseCell);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
              CellIdentityNr identity = (CellIdentityNr) baseCell.getCellIdentity();
              String mccMnc = identity.getMccString() + identity.getMncString();

              nrCellData.setCellIdentifier(mccMnc); // test
              /* if (mccMnc.equals(simOperator)) */
              data.addNeighborCell(nrCellData);
            } else
              data.addNeighborCell(nrCellData);
          }

          break;
      }
    }

    if (data.getPrimaryCell() != null) {
      Log.w("pw.dotto.netmanager", data.getPrimaryCell().toString());
      data.getPrimaryCell().setBasicCellData(DataExtractor.getBasicData(data.getPrimaryCell()));
    }

    data.addNeighborCell(data.getPrimaryCell());
    data.addActiveCell(data.getPrimaryCell());

    for (CellData cellData : data.getActiveCells()) {
      Log.w("pw.dotto.netmanager", cellData.toString());
      cellData.setBasicCellData(DataExtractor.getBasicData(cellData));
    }

    for (CellData cellData : data.getNeighborCells()) {
      Log.w("pw.dotto.netmanager", cellData.toString());
      cellData.setBasicCellData(DataExtractor.getBasicData(cellData));
    }

    if (data.getPrimaryCell() != null &&
        data.getPrimaryCell() instanceof LteCellData) {

      data.setActiveBw(data.getPrimaryCell().getBandwidth());
      for (CellData cellData : data.getActiveCells()) {
        if (!(cellData.getBandwidth() < 0 || cellData.getBandwidth() == CellInfo.UNAVAILABLE))
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

  @SuppressLint("MissingPermission")
  public String getPlmn(TelephonyManager telephony) {
    if (telephony == null || !Utils.checkPermissions(context))
      return "00000";

    return telephony.getNetworkOperator();
  }

  @SuppressLint("MissingPermission")
  public String getPlmn(int simId) {
    switch (simId) {
      case 0:
        return getPlmn(firstManager);
      case 1:
        return getPlmn(secondManager);
      default:
        return "00000";
    }
  }

  @SuppressLint("MissingPermission")
  private void updateTelephonyManagers() {
    if (!Utils.checkPermissions(context))
      return;

    SubscriptionManager manager = getSubscriptionManager();
    if (manager == null)
      return;

    List<SubscriptionInfo> subscriptions = manager.getActiveSubscriptionInfoList();

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

    Executor executor = ContextCompat.getMainExecutor(context);
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (firstManager != null) {
        nsa[0] = new DisplayInfoListener();
        firstManager.registerTelephonyCallback(executor, nsa[0]);
      }

      if (secondManager != null) {
        nsa[1] = new DisplayInfoListener();
        secondManager.registerTelephonyCallback(executor, nsa[1]);
      }
    }
  }

  @SuppressLint("MissingPermission")
  public int getSimCount() {
    if (!Utils.checkPermissions(context))
      return 0;

    SubscriptionManager manager = getSubscriptionManager();
    if (manager == null)
      return 0;

    List<SubscriptionInfo> subscriptions = manager.getActiveSubscriptionInfoList();
    return subscriptions == null ? 0 : subscriptions.size();
  }

  public boolean getNsaStatus(int index) {
    if (nsa[index] == null)
      return false;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
      return nsa[index].getNsa();
    return false;
  }
}
