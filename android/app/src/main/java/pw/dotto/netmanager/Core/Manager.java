package pw.dotto.netmanager.Core;

import static android.content.Context.MODE_PRIVATE;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.telephony.CellIdentityNr;
import android.telephony.CellInfo;
import android.telephony.CellInfoCdma;
import android.telephony.CellInfoGsm;
import android.telephony.CellInfoLte;
import android.telephony.CellInfoNr;
import android.telephony.CellInfoTdscdma;
import android.telephony.CellInfoWcdma;
import android.telephony.ServiceState;
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.Executor;

import pw.dotto.netmanager.Core.Events.EventManager;
import pw.dotto.netmanager.Core.Events.EventTypes;
import pw.dotto.netmanager.Core.Events.MobileNetmanagerEvent;
import pw.dotto.netmanager.Core.Listeners.ServiceStateListener;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.CellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.GsmCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.LteCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.TdscdmaCellData;
import pw.dotto.netmanager.Core.MobileInfo.CellDatas.WcdmaCellData;
import pw.dotto.netmanager.Core.MobileInfo.Extractors.CellExtractor;
import pw.dotto.netmanager.Core.MobileInfo.Extractors.DataExtractor;
import pw.dotto.netmanager.Core.Listeners.DisplayInfoListener;
import pw.dotto.netmanager.Core.MobileInfo.SIMData;
import pw.dotto.netmanager.Core.MobileInfo.SimReceiverManager;

public class Manager {
  private final Context context;

  private TelephonyManager firstManager;
  private TelephonyManager secondManager;
  private final SimReceiverManager simReceiverManager;
  private final EventManager eventManager;

  private DisplayInfoListener[] nsa = { null, null };
  private ServiceStateListener[] serviceStates = { null, null };

  private Date lastModemUpdate = null;
  private static final int updateInterval = 10;

  public Manager(Context context) {
    this.context = context;

    simReceiverManager = SimReceiverManager.getInstance(context);
    simReceiverManager.registerStateReceiver(this::updateTelephonyManagers);

    eventManager = EventManager.getInstance(context);
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
      return "Unknown";

    StringBuilder str = new StringBuilder();

    SubscriptionManager manager = getSubscriptionManager();
    if (manager == null)
      return "No service";

    List<SubscriptionInfo> activeSubscriptionList = manager.getActiveSubscriptionInfoList();
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
        str.append("No service");

      str.append(firstManager.getNetworkOperatorName()).append(" ").append(
          networkGen == 0 ? "Unknown" : (networkGen < 0 ? "No service" : networkGen + "G" + (networkGen == 5 ? (nrSa ? " SA" : " NSA") : "")));

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
                  networkGen == 0 ? "Unknown" : (networkGen < 0 ? "No service" : networkGen + "G" + (networkGen == 5 ? (nrSa ? " SA" : " NSA") : "")));
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
    String simOperator = telephony.getNetworkOperator();
    if ((simOperator == null || simOperator.isEmpty()) && telephony.getPhoneType() == TelephonyManager.PHONE_TYPE_CDMA)
      simOperator = telephony.getSimOperator();

    if (simOperator == null || simOperator.isEmpty())
      simOperator = "00000";

    try {
      if (lastModemUpdate == null
          || (lastModemUpdate.toInstant().plusSeconds(updateInterval).isBefore(new Date().toInstant()))) {
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

    List<CellInfo> cellInfo = telephony.getAllCellInfo();
    if (cellInfo != null)
      for (CellInfo baseCell : cellInfo) {
        Log.w("pw.dotto.netmanager", "Detected cell: " + baseCell.toString());

        switch (baseCell.getCellConnectionStatus()) {
          case CellInfo.CONNECTION_PRIMARY_SERVING:
            if (baseCell instanceof CellInfoGsm) {
              GsmCellData gsmCellData = CellExtractor.getGsmCellData((CellInfoGsm) baseCell);
              String mccMnc = ((CellInfoGsm) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoGsm) baseCell).getCellIdentity().getMncString();

              if (mccMnc.equals(simOperator))
                data.setPrimaryCell(gsmCellData);
            } else if (baseCell instanceof CellInfoCdma) {
              CdmaCellData cdmaCellData = CellExtractor.getCdmaCellData((CellInfoCdma) baseCell);
              data.setPrimaryCell(cdmaCellData);
            } else if (baseCell instanceof CellInfoTdscdma) {
              TdscdmaCellData tdscdmaCellData = CellExtractor.getTdscdmaCellData((CellInfoTdscdma) baseCell);
              String mccMnc = ((CellInfoTdscdma) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoTdscdma) baseCell).getCellIdentity().getMncString();

              if (mccMnc.equals(simOperator))
                data.setPrimaryCell(tdscdmaCellData);
            } else if (baseCell instanceof CellInfoWcdma) {
              WcdmaCellData wcdmaCellData = CellExtractor.getWcdmaCellData((CellInfoWcdma) baseCell);
              String mccMnc = ((CellInfoWcdma) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoWcdma) baseCell).getCellIdentity().getMncString();

              if (mccMnc.equals(simOperator))
                data.setPrimaryCell(wcdmaCellData);
            } else if (baseCell instanceof CellInfoLte) {
              LteCellData lteCellData = CellExtractor.getLteCellData((CellInfoLte) baseCell);
              String mccMnc = ((CellInfoLte) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoLte) baseCell).getCellIdentity().getMncString();

              if (mccMnc.equals(simOperator))
                data.setPrimaryCell(lteCellData);
            } else if (baseCell instanceof CellInfoNr) {
              NrCellData nrCellData = CellExtractor.getNrCellData((CellInfoNr) baseCell);

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
              GsmCellData gsmCellData = CellExtractor.getGsmCellData((CellInfoGsm) baseCell);
              String mccMnc = ((CellInfoGsm) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoGsm) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addActiveCell(gsmCellData);
              } else
                data.addActiveCell(gsmCellData);
            } else if (baseCell instanceof CellInfoCdma) {
              CdmaCellData cdmaCellData = CellExtractor.getCdmaCellData((CellInfoCdma) baseCell);
              data.addActiveCell(cdmaCellData);
            } else if (baseCell instanceof CellInfoTdscdma) {
              TdscdmaCellData tdscdmaCellData = CellExtractor.getTdscdmaCellData((CellInfoTdscdma) baseCell);
              String mccMnc = ((CellInfoTdscdma) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoTdscdma) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addActiveCell(tdscdmaCellData);
              } else
                data.addActiveCell(tdscdmaCellData);
            } else if (baseCell instanceof CellInfoWcdma) {
              WcdmaCellData wcdmaCellData = CellExtractor.getWcdmaCellData((CellInfoWcdma) baseCell);
              String mccMnc = ((CellInfoWcdma) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoWcdma) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addActiveCell(wcdmaCellData);
              } else
                data.addActiveCell(wcdmaCellData);
            } else if (baseCell instanceof CellInfoLte) {
              LteCellData lteCellData = CellExtractor.getLteCellData((CellInfoLte) baseCell);
              String mccMnc = ((CellInfoLte) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoLte) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addActiveCell(lteCellData);
              } else
                data.addActiveCell(lteCellData);
            } else if (baseCell instanceof CellInfoNr) {
              NrCellData nrCellData = CellExtractor.getNrCellData((CellInfoNr) baseCell);

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

            break;
          case CellInfo.CONNECTION_NONE:
          case CellInfo.CONNECTION_UNKNOWN:
            if (baseCell instanceof CellInfoGsm) {
              GsmCellData gsmCellData = CellExtractor.getGsmCellData((CellInfoGsm) baseCell);
              String mccMnc = ((CellInfoGsm) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoGsm) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addNeighborCell(gsmCellData);
              } else
                data.addNeighborCell(gsmCellData);
              ;
            } else if (baseCell instanceof CellInfoCdma) {
              CdmaCellData cdmaCellData = CellExtractor.getCdmaCellData((CellInfoCdma) baseCell);
              data.addNeighborCell(cdmaCellData);
            } else if (baseCell instanceof CellInfoTdscdma) {
              TdscdmaCellData tdscdmaCellData = CellExtractor.getTdscdmaCellData((CellInfoTdscdma) baseCell);
              String mccMnc = ((CellInfoTdscdma) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoTdscdma) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addNeighborCell(tdscdmaCellData);
              } else
                data.addNeighborCell(tdscdmaCellData);
            } else if (baseCell instanceof CellInfoWcdma) {
              WcdmaCellData wcdmaCellData = CellExtractor.getWcdmaCellData((CellInfoWcdma) baseCell);
              String mccMnc = ((CellInfoWcdma) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoWcdma) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addNeighborCell(wcdmaCellData);
              } else
                data.addNeighborCell(wcdmaCellData);
            } else if (baseCell instanceof CellInfoLte) {
              LteCellData lteCellData = CellExtractor.getLteCellData((CellInfoLte) baseCell);
              String mccMnc = ((CellInfoLte) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoLte) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addNeighborCell(lteCellData);
              } else
                data.addNeighborCell(lteCellData);
            } else if (baseCell instanceof CellInfoNr) {
              NrCellData nrCellData = CellExtractor.getNrCellData((CellInfoNr) baseCell);

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

            break;
        }
      }

    List<Integer> cellBandwidths = new ArrayList<>();
    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        ServiceStateListener serviceStateListener = serviceStates[telephony.getSubscriptionId()];
        int[] bandwidths = null;

        if (serviceStateListener != null)
          bandwidths = serviceStateListener.getUpdatedCellBandwidths();
        else {
          ServiceState state = telephony.getServiceState();
          if (state != null)
            bandwidths = state.getCellBandwidths();
        }

        if (bandwidths != null)
          for (int bw : bandwidths) {
            cellBandwidths.add(bw / 1000);
          }
      } else {
        ServiceState state = telephony.getServiceState();

        if (state != null) {
          for (int bw : state.getCellBandwidths()) {
            cellBandwidths.add(bw / 1000);
          }
        }

      }

      SharedPreferences sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
      boolean debug = sharedPreferences.getBoolean("flutter.debug", false);
      if(debug && context instanceof Activity) {
        StringBuilder sb = new StringBuilder("BW: ");
        for(int i : cellBandwidths) {
          sb.append(i).append(",");
        }

        sb.deleteCharAt(sb.length() - 1);

        Toast toast = Toast.makeText(context, sb.toString(), Toast.LENGTH_SHORT);
        toast.show();
      }
    } catch (Exception e) {
      // todo add sentry
    }

    if (data.getPrimaryCell() != null) {
      Log.w("pw.dotto.netmanager", data.getPrimaryCell().toString());
      data.getPrimaryCell().setBasicCellData(DataExtractor.getBasicData(data.getPrimaryCell()));
      data.addActiveCell(data.getPrimaryCell());
    }

    for (CellData cellData : data.getActiveCells()) {
      Log.w("pw.dotto.netmanager", cellData.toString());

      cellData.setBasicCellData(DataExtractor.getBasicData(cellData));
    }

    for (CellData cellData : data.getNeighborCells()) {
      Log.w("pw.dotto.netmanager", cellData.toString());
      cellData.setBasicCellData(DataExtractor.getBasicData(cellData));
    }

    boolean inactiveData = true;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      inactiveData = !(SubscriptionManager.getActiveDataSubscriptionId() == telephony.getSubscriptionId());
    }

    // attempt to filter out wrong bands
    if (inactiveData && data.getPrimaryCell() != null) {
      switch (data.getNetworkGen()) {
        case 2: // 2G cannot use multiple bands at the same time
          for (CellData cellData : data.getActiveCells()) {
            if (cellData != data.getPrimaryCell())
              data.removeActiveCell(cellData);
          }
        case 3: // filter out bands
          if (data.getPrimaryCell() instanceof CdmaCellData || data.getPrimaryCell() instanceof TdscdmaCellData) {
            for (CellData cellData : data.getActiveCells()) {
              if (cellData != data.getPrimaryCell())
                data.removeActiveCell(cellData);
            }
          } else if (data.getPrimaryCell() instanceof WcdmaCellData) { // remove all active cells from other
                                                                       // technologies
            for (CellData cellData : data.getActiveCells()) {
              if (!(cellData instanceof WcdmaCellData))
                data.removeActiveCell(cellData);
            }
          }
        case 4:
          if (cellBandwidths.isEmpty())
            break; // might as well be the wrong amount of cell bandwidths

          boolean isNsa;
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            isNsa = getNsaStatus(telephony.getSubscriptionId());
          } else {
            isNsa = getNsaStatus(telephony);
          }

          if (!isNsa) {
            for (CellData cellData : data.getActiveCells()) {
              if (cellData instanceof NrCellData)
                data.removeActiveCell(cellData);
            }
          }

          data.clearActiveCells(); //test (idle sim = no CA)

          break;
      }
    }

    // after pretty much everything, just before setting general bandwidth. might
    // confuse between multiple NR bands...
    CellData[] activeCells = data.getActiveCells();
    Arrays.sort(activeCells, (a, b) -> {
      int bwA = a.getBandwidth();
      int bwB = b.getBandwidth();

      boolean invalidA = bwA <= 0;
      boolean invalidB = bwB <= 0;
      return Boolean.compare(invalidA, invalidB);
    });

    data.setActiveCells(activeCells);

    List<Integer> availableBandwidths = new ArrayList<>(cellBandwidths);

    for (CellData cell : data.getActiveCells()) {
      int bw = cell.getBandwidth();
      if (bw > 0) {
        availableBandwidths.remove(Integer.valueOf(bw));
      }
    }

    for(CellData cell : data.getActiveCells()) {
      int bw = cell.getBandwidth();
      if(bw <= 0) {
        if(cell instanceof NrCellData) {
          Optional<Integer> possibleBw = availableBandwidths.stream().filter(b -> b > 20).findFirst();

          if(possibleBw.isPresent()) {
            int nrBw = possibleBw.get();
            cell.setBandwidth(nrBw);
            availableBandwidths.remove(Integer.valueOf(nrBw));
          }
        } else {
          if(!availableBandwidths.isEmpty()) {
            int lteBw = availableBandwidths.remove(0);
            cell.setBandwidth(lteBw);
          }
        }
      }
    }

    if (data.getPrimaryCell() != null &&
        data.getPrimaryCell() instanceof LteCellData) {

      data.setActiveBw(data.getPrimaryCell().getBandwidth());
      for (CellData cellData : data.getActiveCells()) {
        if (!(cellData.getBandwidth() < 0 || cellData.getBandwidth() == CellInfo.UNAVAILABLE)
            && !data.getPrimaryCell().equals(cellData))
          data.setActiveBw(data.getActiveBw() + cellData.getBandwidth());
      }
    }

    return data;
  }

  @SuppressLint("MissingPermission")
  public SIMData getSimNetworkData(int simId) {
    SIMData simData;

    switch (simId) {
      case 0:
        simData = getSimNetworkData(firstManager);
        if (simData != null && simData.getPrimaryCell() != null)
          saveEvent(EventTypes.MOBILE_BAND_CHANGED, 0,
              (simData.getPrimaryCell().getChannelNumberString().equals("ARFCN") ? "N" : "B")
                  + simData.getPrimaryCell().getBand());
        return simData;
      case 1:
        simData = getSimNetworkData(secondManager);
        if (simData != null && simData.getPrimaryCell() != null)
          saveEvent(EventTypes.MOBILE_BAND_CHANGED, 1,
              (simData.getPrimaryCell().getChannelNumberString().equals("ARFCN") ? "N" : "B")
                  + simData.getPrimaryCell().getBand());
        return simData;
      default:
        return null;
    }
  }

  @SuppressLint("MissingPermission")
  public int getSimNetworkGen(TelephonyManager telephony) {
    if (telephony == null || !Utils.checkPermissions(context))
      return -1;

    int networkType = 0;

    try {
      networkType = telephony.getDataNetworkType();
    } catch (Exception e) {
      // todo: add sentry
    }

    switch (networkType) {
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
    int gen;

    switch (simId) {
      case 0:
        gen = getSimNetworkGen(firstManager);
        saveEvent(EventTypes.MOBILE_TECHNOLOGY_CHANGED, 0,
            (getNsaStatus(simId) ? "5G" : (gen > 0 ? gen + "G" : "Unknown")));
        return gen;
      case 1:
        gen = getSimNetworkGen(secondManager);
        saveEvent(EventTypes.MOBILE_TECHNOLOGY_CHANGED, 1,
            (getNsaStatus(simId) ? "5G" : (gen > 0 ? gen + "G" : "Unknown")));
        return gen;
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
    String plmn;

    switch (simId) {
      case 0:
        plmn = getPlmn(firstManager);
        saveEvent(EventTypes.MOBILE_PLMN_CHANGED, 0, plmn);
        return plmn;
      case 1:
        plmn = getPlmn(secondManager);
        saveEvent(EventTypes.MOBILE_PLMN_CHANGED, 1, plmn);
        return plmn;
      default:
        return "00000";
    }
  }

  @SuppressLint("MissingPermission")
  public String getNetwork(TelephonyManager telephony) {
    if (telephony == null || !Utils.checkPermissions(context))
      return "NetManager";

    return telephony.getNetworkOperatorName();
  }

  @SuppressLint("MissingPermission")
  public String getNetwork(int simId) {
    switch (simId) {
      case 0:
        return getNetwork(firstManager);
      case 1:
        return getNetwork(secondManager);
      default:
        return "NetManager";
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
    if (executor == null)
      return;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (firstManager != null) {
        if (nsa[0] != null)
          firstManager.unregisterTelephonyCallback(nsa[0]);
        if (serviceStates[0] != null)
          firstManager.unregisterTelephonyCallback(serviceStates[0]);

        nsa[0] = new DisplayInfoListener();
        serviceStates[0] = new ServiceStateListener();

        if (nsa[0] != null)
          firstManager.registerTelephonyCallback(executor, nsa[0]);
        if (serviceStates[0] != null)
          firstManager.registerTelephonyCallback(executor, serviceStates[0]);
      }

      if (secondManager != null && getSimCount() > 1) {
        if (nsa[1] != null)
          secondManager.unregisterTelephonyCallback(nsa[1]);
        if (serviceStates[1] != null)
          secondManager.unregisterTelephonyCallback(serviceStates[1]);

        nsa[1] = new DisplayInfoListener();
        serviceStates[1] = new ServiceStateListener();

        if (nsa[1] != null)
          secondManager.registerTelephonyCallback(executor, nsa[1]);
        if (serviceStates[1] != null)
          secondManager.registerTelephonyCallback(executor, serviceStates[1]);
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

  @SuppressLint("MissingPermission")
  public boolean getNsaStatus(TelephonyManager telephony) { // fallback
    if (telephony == null || !Utils.checkPermissions(context))
      return false;

    ServiceState state = telephony.getServiceState(); // no serviceStates[] since if nsa[] is null it will be null too

    if (state != null) {
      String s = state.toString();

      return s.contains("nrState=CONNECTED") || s.contains("nsaState=5") || s.contains("EnDc=true");
    }

    return false;
  }

  public boolean getNsaStatus(int index) {
    boolean result = false;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      DisplayInfoListener infoListener = nsa[index];
      if (infoListener != null)
        result = infoListener.getNsa();
    }

    if (!result) {
      switch (index) {
        case 0:
          result = getNsaStatus(firstManager);
          break;
        case 1:
          result = getNsaStatus(secondManager);
          break;
      }
    }

    return result;
  }

  private void saveEvent(EventTypes type, int simId, String value) {
    if (eventManager == null || value == null)
      return;

    if (type.toString().startsWith("MOBILE")) {
      eventManager.addEvent(new MobileNetmanagerEvent(type, value, simId, getNetwork(simId)));
    }
  }

  public SimReceiverManager getSimReceiverManager() {
    return simReceiverManager;
  }

  public EventManager getEventManager() {
    return eventManager;
  }
}
