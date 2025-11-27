package pw.dotto.netmanager.Core;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.os.Build;
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
import android.telephony.SubscriptionInfo;
import android.telephony.SubscriptionManager;
import android.telephony.TelephonyManager;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.Executor;

import pw.dotto.netmanager.Core.Events.EventManager;
import pw.dotto.netmanager.Core.Events.EventTypes;
import pw.dotto.netmanager.Core.Events.MobileNetmanagerEvent;
import pw.dotto.netmanager.Core.Listeners.DataStateListener;
import pw.dotto.netmanager.Core.Listeners.ServiceStateListener;
import pw.dotto.netmanager.Core.Listeners.SignalStrengthsListener;
import pw.dotto.netmanager.Core.Listeners.SubscriptionChangedListener;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.GsmCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.LteCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.NrCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.TdscdmaCellData;
import pw.dotto.netmanager.Core.Mobile.CellDatas.WcdmaCellData;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.CdmaExtractor;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.GsmExtractor;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.LteExtractor;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.NrExtractor;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.TdscdmaExtractor;
import pw.dotto.netmanager.Core.Mobile.Extractors.Cells.WcdmaExtractor;
import pw.dotto.netmanager.Core.Mobile.Extractors.BasicData.DataManager;
import pw.dotto.netmanager.Core.Listeners.DisplayInfoListener;
import pw.dotto.netmanager.Core.Mobile.PhysicalChannelDumper;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.Mobile.SimReceiverManager;
import pw.dotto.netmanager.Utils.DebugLogger;
import pw.dotto.netmanager.Utils.Mobile;
import pw.dotto.netmanager.Utils.Permissions;

public class Manager {
  private final Context context;

  private TelephonyManager firstManager;
  private TelephonyManager secondManager;
  private final SimReceiverManager simReceiverManager;
  private final EventManager eventManager;

  private final DisplayInfoListener[] nsa = { null, null };
  private final ServiceStateListener[] serviceStates = { null, null };
  private final DataStateListener[] dataStates = { null, null };
  private final SignalStrengthsListener[] signalStrengths = { null, null };
  private final PhysicalChannelDumper[] physicalChannelDumpers = { null, null };

  private SubscriptionChangedListener subscriptionChangedListener;

  private Date lastModemUpdate = null;
  private static final int updateInterval = 10;

  public Manager(Context context) {
    this.context = context;

    simReceiverManager = SimReceiverManager.getInstance(context);
    simReceiverManager.registerStateReceiver(this::updateTelephonyManagers);

    eventManager = EventManager.getInstance(context);

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      SubscriptionManager subscriptionManager = getSubscriptionManager();
      if (subscriptionManager != null) {
        if (subscriptionChangedListener != null)
          subscriptionManager.removeOnSubscriptionsChangedListener(subscriptionChangedListener);

        subscriptionChangedListener = new SubscriptionChangedListener(this::updateTelephonyManagers);
        subscriptionManager.addOnSubscriptionsChangedListener(context.getMainExecutor(), subscriptionChangedListener);
      }
    }
  }

  private TelephonyManager getTelephony() {
    return (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
  }

  private SubscriptionManager getSubscriptionManager() {
    return (SubscriptionManager) context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE);
  }

  @SuppressLint("MissingPermission")
  public String getFullHeaderString() {
    if (!Permissions.check(context, Permissions.READ_PHONE_STATE))
      return "Unknown";

    StringBuilder str = new StringBuilder();

    SubscriptionManager manager = getSubscriptionManager();
    if (manager == null)
      return "No service";

    List<SubscriptionInfo> activeSubscriptionList = manager.getActiveSubscriptionInfoList();
    if (activeSubscriptionList != null && !activeSubscriptionList.isEmpty()) { // always at least 1
      if (firstManager == null) {
        SubscriptionInfo firstInfo = activeSubscriptionList.get(0);
        firstManager = getTelephony().createForSubscriptionId(firstInfo.getSubscriptionId());
      }

      int networkGen;
      boolean nrSa;

      if (firstManager != null) {
        networkGen = getSimNetworkGen(firstManager);
        nrSa = networkGen == 5;

        if (networkGen == 4 && getNsaStatus(0))
          networkGen = 5;

        if (firstManager.getNetworkOperatorName() != null
            && !firstManager.getNetworkOperatorName().trim().isEmpty())
          str.append(firstManager.getNetworkOperatorName()).append(" ").append(
              networkGen == 0 ? "Unknown"
                  : (networkGen < 0 ? "No service"
                      : networkGen + "G" + (networkGen == 5 ? (nrSa ? " SA" : " NSA") : "")));
        else
          str.append("Unknown");

      } else
        str.append("Unknown");

      if (activeSubscriptionList.size() > 1) {
        SubscriptionInfo secondInfo = activeSubscriptionList.get(1);
        if (secondManager == null)
          secondManager = getTelephony().createForSubscriptionId(secondInfo.getSubscriptionId());

        if (secondManager != null) {
          networkGen = getSimNetworkGen(secondManager);
          nrSa = networkGen == 5;

          if (networkGen == 4 && getNsaStatus(1))
            networkGen = 5;

          if (secondManager.getNetworkOperatorName() != null
              && !secondManager.getNetworkOperatorName().trim().isEmpty())
            str.append(" | ").append(secondManager.getNetworkOperatorName()).append(" ").append(
                networkGen == 0 ? "Unknown"
                    : (networkGen < 0 ? "No service"
                        : networkGen + "G" + (networkGen == 5 ? (nrSa ? " SA" : " NSA") : "")));
        } else
          str.append(" | Unknown");
      }
    } else
      str.append("No service");

    return str.toString().trim();
  }

  @SuppressLint("MissingPermission")
  public String getSimCarrier(TelephonyManager telephony) {
    if (telephony == null || !Permissions.check(context, Permissions.READ_PHONE_STATE))
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
    if (telephony == null || !Permissions.check(context, Permissions.READ_PHONE_STATE))
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
    if (!Permissions.check(context, Permissions.READ_PHONE_STATE))
      return null;

    if (telephony == null) {
      updateTelephonyManagers();
      return null;
    }

    SIMData data = new SIMData(getSimCarrier(telephony), getSimOperator(telephony), getSimNetworkGen(telephony),
        telephony.getSimOperator(), getPlmn(telephony));
    String simOperator = telephony.getNetworkOperator();
    if ((simOperator == null || simOperator.isEmpty()) && telephony.getPhoneType() == TelephonyManager.PHONE_TYPE_CDMA)
      simOperator = telephony.getSimOperator();

    if (simOperator == null || simOperator.isEmpty())
      simOperator = "00000";

    int subscriptionIndex = 0;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      if (secondManager != null && secondManager.getSubscriptionId() == telephony.getSubscriptionId())
        subscriptionIndex = 1;
    } else {
      if (secondManager != null && secondManager == telephony)
        subscriptionIndex = 1;
    }

    try {
      if (lastModemUpdate == null
          || (lastModemUpdate.toInstant().plusSeconds(updateInterval).isBefore(new Date().toInstant()))) {
        telephony.requestCellInfoUpdate(ContextCompat.getMainExecutor(context),
            new TelephonyManager.CellInfoCallback() {
              @Override
              public void onCellInfo(@NonNull List<CellInfo> cellInfo) {
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
        switch (baseCell.getCellConnectionStatus()) {
          case CellInfo.CONNECTION_PRIMARY_SERVING:
            if (baseCell instanceof CellInfoGsm) {
              GsmCellData gsmCellData = GsmExtractor.get((CellInfoGsm) baseCell);
              String mccMnc = ((CellInfoGsm) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoGsm) baseCell).getCellIdentity().getMncString();

              if (mccMnc.equals(simOperator))
                data.setPrimaryCell(gsmCellData);
            } else if (baseCell instanceof CellInfoCdma) {
              CdmaCellData cdmaCellData = CdmaExtractor.get((CellInfoCdma) baseCell);
              data.setPrimaryCell(cdmaCellData);
            } else if (baseCell instanceof CellInfoTdscdma) {
              TdscdmaCellData tdscdmaCellData = TdscdmaExtractor.get((CellInfoTdscdma) baseCell);
              String mccMnc = ((CellInfoTdscdma) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoTdscdma) baseCell).getCellIdentity().getMncString();

              if (mccMnc.equals(simOperator))
                data.setPrimaryCell(tdscdmaCellData);
            } else if (baseCell instanceof CellInfoWcdma) {
              WcdmaCellData wcdmaCellData = WcdmaExtractor.get((CellInfoWcdma) baseCell);
              String mccMnc = ((CellInfoWcdma) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoWcdma) baseCell).getCellIdentity().getMncString();

              if (mccMnc.equals(simOperator))
                data.setPrimaryCell(wcdmaCellData);
            } else if (baseCell instanceof CellInfoLte) {
              LteCellData lteCellData = LteExtractor.get((CellInfoLte) baseCell);
              String mccMnc = ((CellInfoLte) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoLte) baseCell).getCellIdentity().getMncString();

              if (mccMnc.equals(simOperator))
                data.setPrimaryCell(lteCellData);
            } else if (baseCell instanceof CellInfoNr) {
              NrCellData nrCellData = NrExtractor.get((CellInfoNr) baseCell);

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
              GsmCellData gsmCellData = GsmExtractor.get((CellInfoGsm) baseCell);
              String mccMnc = ((CellInfoGsm) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoGsm) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addActiveCell(gsmCellData);
              } else
                data.addActiveCell(gsmCellData);
            } else if (baseCell instanceof CellInfoCdma) {
              CdmaCellData cdmaCellData = CdmaExtractor.get((CellInfoCdma) baseCell);
              data.addActiveCell(cdmaCellData);
            } else if (baseCell instanceof CellInfoTdscdma) {
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
              String mccMnc = ((CellInfoWcdma) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoWcdma) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addActiveCell(wcdmaCellData);
              } else
                data.addActiveCell(wcdmaCellData);
            } else if (baseCell instanceof CellInfoLte) {
              LteCellData lteCellData = LteExtractor.get((CellInfoLte) baseCell);
              String mccMnc = ((CellInfoLte) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoLte) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addActiveCell(lteCellData);
              } else
                data.addActiveCell(lteCellData);
            } else if (baseCell instanceof CellInfoNr) {
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

            break;
          case CellInfo.CONNECTION_NONE:
          case CellInfo.CONNECTION_UNKNOWN:
            if (baseCell instanceof CellInfoGsm) {
              GsmCellData gsmCellData = GsmExtractor.get((CellInfoGsm) baseCell);
              String mccMnc = ((CellInfoGsm) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoGsm) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addNeighborCell(gsmCellData);
              } else
                data.addNeighborCell(gsmCellData);
              ;
            } else if (baseCell instanceof CellInfoCdma) {
              CdmaCellData cdmaCellData = CdmaExtractor.get((CellInfoCdma) baseCell);
              data.addNeighborCell(cdmaCellData);
            } else if (baseCell instanceof CellInfoTdscdma) {
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
              String mccMnc = ((CellInfoWcdma) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoWcdma) baseCell).getCellIdentity().getMncString();

              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addNeighborCell(wcdmaCellData);
              } else
                data.addNeighborCell(wcdmaCellData);
            } else if (baseCell instanceof CellInfoLte) {
              LteCellData lteCellData = LteExtractor.get((CellInfoLte) baseCell);
              String mccMnc = ((CellInfoLte) baseCell).getCellIdentity().getMccString()
                  + ((CellInfoLte) baseCell).getCellIdentity().getMncString();
              if (!mccMnc.contains("null")) {
                if (mccMnc.equals(simOperator))
                  data.addNeighborCell(lteCellData);
              } else
                data.addNeighborCell(lteCellData);
            } else if (baseCell instanceof CellInfoNr) {
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

            break;
        }
      }

    List<Integer> cellBandwidths = new ArrayList<>();
    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        ServiceStateListener serviceStateListener = serviceStates[subscriptionIndex];
        int[] bandwidths = null;

        if (serviceStateListener != null)
          bandwidths = serviceStateListener.getUpdatedCellBandwidths();
        if (context instanceof Activity)
          DebugLogger.add("Service state bandwidth: " + Arrays.toString(bandwidths));
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
    } catch (Exception e) {
      DebugLogger.add("Bandwidth calculator exception: " + e.getMessage());
    }

    int mcc = Integer.parseInt(getPlmn(telephony).substring(0, 3));

    if (data.getPrimaryCell() != null) {
      data.getPrimaryCell().setBasicCellData(DataManager.getBasicData(data.getPrimaryCell(), mcc));
      data.addActiveCell(data.getPrimaryCell());
    }

    for (CellData cellData : data.getActiveCells()) {
      cellData.setBasicCellData(DataManager.getBasicData(cellData, mcc));
    }

    for (CellData cellData : data.getNeighborCells()) {
      cellData.setBasicCellData(DataManager.getBasicData(cellData, mcc));
    }

    // attempt to filter out wrong bands
    if (data.getPrimaryCell() != null) {
      switch (data.getNetworkGen()) {
        case 2: // 2G cannot use multiple bands at the same time
          for (CellData cellData : data.getActiveCells()) {
            if (cellData != data.getPrimaryCell())
              data.removeActiveCell(cellData);
          }
          break;
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
          break;
        case 4:
          if (cellBandwidths.isEmpty())
            break; // might as well be the wrong amount of cell bandwidths

          boolean isNsa;
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            isNsa = getNsaStatus(subscriptionIndex);
          } else {
            isNsa = getNsaStatus(telephony);
          }

          if (!isNsa) {
            for (CellData cellData : data.getActiveCells()) {
              if (cellData instanceof NrCellData)
                data.removeActiveCell(cellData);
            }
          }

          boolean clearActiveCells = false; // possibly port this to 5G SA in future

          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            int status = getDataStatus(subscriptionIndex);

            switch (status) {
              case TelephonyManager.DATA_DISCONNECTED:
              case TelephonyManager.DATA_DISCONNECTING:
              case TelephonyManager.DATA_SUSPENDED:
              case TelephonyManager.DATA_UNKNOWN:
                clearActiveCells = true;
                break;
            }
          } else if (Build.VERSION.SDK_INT == Build.VERSION_CODES.R) {
            clearActiveCells = !(SubscriptionManager.getActiveDataSubscriptionId() == telephony.getSubscriptionId());
          }

          if (clearActiveCells)
            data.clearActiveCells(); // (idle sim = no CA)

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

    for (CellData cell : data.getActiveCells()) {
      int bw = cell.getBandwidth();
      if (bw <= 0) {
        if (cell instanceof NrCellData) {
          Optional<Integer> possibleBw = availableBandwidths.stream().filter(b -> b > 20).findFirst();

          if (possibleBw.isPresent()) {
            int nrBw = possibleBw.get();
            cell.setBandwidth(nrBw);
            availableBandwidths.remove(Integer.valueOf(nrBw));
          }
        } else {
          if (!availableBandwidths.isEmpty()) {
            int lteBw = availableBandwidths.remove(0);
            cell.setBandwidth(lteBw);
          }
        }
      }
    }

    if (data.getPrimaryCell() != null &&
        data.getPrimaryCell() instanceof LteCellData) {

      // to be moved out of here ---
      List<NrCellData> nrCells = new ArrayList<>();
      for (CellData cellData : data.getActiveCells()) {
        if (cellData instanceof NrCellData) {
          NrCellData nrCellData = (NrCellData) cellData;
          if (nrCellData.getProcessedSignal() == CellInfo.UNAVAILABLE
              || nrCellData.getRawSignal() == CellInfo.UNAVAILABLE
              || nrCellData.getSignalNoise() == CellInfo.UNAVAILABLE
              || nrCellData.getSignalQuality() == CellInfo.UNAVAILABLE)
            nrCells.add(nrCellData);
        }
      }
      nrCells.sort((a, b) -> Integer.compare(b.getBasicCellData().getFrequency(), a.getBasicCellData().getFrequency())); // n78
                                                                                                                         // ->
                                                                                                                         // n1
                                                                                                                         // ->
                                                                                                                         // n28

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

        if (nrCell.getProcessedSignal() == CellInfo.UNAVAILABLE && ssNr.getSsRsrp() != CellInfo.UNAVAILABLE) {
          nrCell.setProcessedSignal(ssNr.getSsRsrp());
        }

        if (nrCell.getRawSignal() == CellInfo.UNAVAILABLE && ssNr.getCsiRsrp() != CellInfo.UNAVAILABLE) {
          nrCell.setRawSignal(ssNr.getCsiRsrp());
        }

        if (nrCell.getSignalNoise() == CellInfo.UNAVAILABLE) {
          if (ssNr.getSsSinr() != CellInfo.UNAVAILABLE) {
            nrCell.setSignalNoise(ssNr.getSsSinr());
          } else if (ssNr.getCsiSinr() != CellInfo.UNAVAILABLE) {
            nrCell.setSignalNoise(ssNr.getCsiSinr());
            nrCell.setSignalNoiseString("CSI SINR");
          }
        }

        if (nrCell.getSignalQuality() == CellInfo.UNAVAILABLE) {
          if (ssNr.getSsRsrq() != CellInfo.UNAVAILABLE) {
            nrCell.setSignalQuality(ssNr.getSsRsrq());
          } else if (ssNr.getCsiRsrq() != CellInfo.UNAVAILABLE) {
            nrCell.setSignalQuality(ssNr.getCsiRsrq());
            nrCell.setSignalNoiseString("CSI RSRQ");
          }
        }

        if (nrCell.getTimingAdvance() == CellInfo.UNAVAILABLE) {
          nrCell.setTimingAdvance(
              Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE ? ssNr.getTimingAdvanceMicros() : CellInfo.UNAVAILABLE);
        }
      }
      // to be moved out of here ---

      // total bandwidth calculation
      if (!(data.getPrimaryCell().getBandwidth() < 0 || data.getPrimaryCell().getBandwidth() == CellInfo.UNAVAILABLE))
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

        if (simData != null && simData.getPrimaryCell() != null) {
          CellData primaryCell = simData.getPrimaryCell();

          saveEvent(EventTypes.MOBILE_BAND_CHANGED, 0,
              (primaryCell instanceof NrCellData ? "N" : "B")
                  + primaryCell.getBand());

          try {
            long node = Long.parseLong(primaryCell.getCellIdentifierString()) / Mobile.getFactor(primaryCell);
            saveEvent(EventTypes.MOBILE_NODE_CHANGED, 0, String.valueOf(node));
          } catch (Exception ignored) {
            saveEvent(EventTypes.MOBILE_NODE_CHANGED, 0, "N/A");
          }
        }
        return simData;
      case 1:
        simData = getSimNetworkData(secondManager);
        if (simData != null && simData.getPrimaryCell() != null) {
          CellData primaryCell = simData.getPrimaryCell();

          saveEvent(EventTypes.MOBILE_BAND_CHANGED, 1,
              (primaryCell instanceof NrCellData ? "N" : "B")
                  + primaryCell.getBand());

          try {
            long node = Long.parseLong(primaryCell.getCellIdentifierString()) / Mobile.getFactor(primaryCell);
            saveEvent(EventTypes.MOBILE_NODE_CHANGED, 1, String.valueOf(node));
          } catch (Exception ignored) {
            saveEvent(EventTypes.MOBILE_NODE_CHANGED, 1, "N/A");
          }
        }
        return simData;
      default:
        return null;
    }
  }

  @SuppressLint("MissingPermission")
  public int getSimNetworkGen(TelephonyManager telephony) {
    if (telephony == null || !Permissions.check(context, Permissions.READ_PHONE_STATE))
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
    if (telephony == null || !Permissions.check(context, Permissions.READ_PHONE_STATE))
      return "00000";

    String plmn = null;
    try {
      plmn = telephony.getNetworkOperator();
    } catch (Exception ignored) {
      // super error, catch it
    }

    if (plmn == null || plmn.length() < 3)
      plmn = "00000";

    return plmn;
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
    if (telephony == null || !Permissions.check(context, Permissions.READ_PHONE_STATE))
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
    if (!Permissions.check(context, Permissions.READ_PHONE_STATE))
      return;

    SubscriptionManager manager = getSubscriptionManager();
    if (manager == null) {
      firstManager = null;
      secondManager = null;

      return;
    }

    List<SubscriptionInfo> subscriptions = manager.getActiveSubscriptionInfoList();

    if (subscriptions == null || subscriptions.isEmpty()) {
      firstManager = null;
      secondManager = null;

      return;
    }

    TelephonyManager oldFirstManager = this.firstManager;
    TelephonyManager oldSecondManager = this.secondManager;

    try {
      int firstId = subscriptions.get(0).getSubscriptionId();
      firstManager = ((TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE))
          .createForSubscriptionId(firstId);
    } catch (Exception ignored) {
      firstManager = null;
    }

    if (subscriptions.size() >= 2) {
      try {
        int secondId = subscriptions.get(1).getSubscriptionId();
        secondManager = ((TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE))
            .createForSubscriptionId(secondId);
      } catch (Exception ignored) {
        secondManager = null;
      }
    } else
      secondManager = null;

    Executor executor = ContextCompat.getMainExecutor(context);
    if (executor == null)
      return;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (oldFirstManager != null) {
        try {
          if (nsa[0] != null)
            oldFirstManager.unregisterTelephonyCallback(nsa[0]);
          if (serviceStates[0] != null)
            oldFirstManager.unregisterTelephonyCallback(serviceStates[0]);
          if (dataStates[0] != null)
            oldFirstManager.unregisterTelephonyCallback(dataStates[0]);
          if (signalStrengths[0] != null)
            oldFirstManager.unregisterTelephonyCallback(signalStrengths[0]);
        } catch (Exception e) {
          DebugLogger.add("firstManager utils unregistration exception: " + e.getMessage());
        }
      }

      if (firstManager != null) {
        try {
          nsa[0] = new DisplayInfoListener();
          serviceStates[0] = new ServiceStateListener();
          dataStates[0] = new DataStateListener();
          signalStrengths[0] = new SignalStrengthsListener();

          if (nsa[0] != null)
            firstManager.registerTelephonyCallback(executor, nsa[0]);
          if (serviceStates[0] != null)
            firstManager.registerTelephonyCallback(executor, serviceStates[0]);
          if (dataStates[0] != null)
            firstManager.registerTelephonyCallback(executor, dataStates[0]);
          if (signalStrengths[0] != null)
            firstManager.registerTelephonyCallback(executor, signalStrengths[0]);
        } catch (Exception e) {
          DebugLogger.add("firstManager utils registration exception: " + e.getMessage());
        }
      } else {
        nsa[0] = null;
        serviceStates[0] = null;
        dataStates[0] = null;
        signalStrengths[0] = null;
      }

      if (oldSecondManager != null) {
        try {
          if (nsa[1] != null)
            oldSecondManager.unregisterTelephonyCallback(nsa[1]);
          if (serviceStates[1] != null)
            oldSecondManager.unregisterTelephonyCallback(serviceStates[1]);
          if (dataStates[1] != null)
            oldSecondManager.unregisterTelephonyCallback(dataStates[1]);
          if (signalStrengths[1] != null)
            oldSecondManager.unregisterTelephonyCallback(signalStrengths[1]);
        } catch (Exception e) {
          DebugLogger.add("secondManager utils unregistration exception: " + e.getMessage());
        }
      }

      if (secondManager != null && subscriptions.size() >= 2) {
        try {
          nsa[1] = new DisplayInfoListener();
          serviceStates[1] = new ServiceStateListener();
          dataStates[1] = new DataStateListener();
          signalStrengths[1] = new SignalStrengthsListener();

          if (nsa[1] != null)
            secondManager.registerTelephonyCallback(executor, nsa[1]);
          if (serviceStates[1] != null)
            secondManager.registerTelephonyCallback(executor, serviceStates[1]);
          if (dataStates[1] != null)
            secondManager.registerTelephonyCallback(executor, dataStates[1]);
          if (signalStrengths[1] != null)
            secondManager.registerTelephonyCallback(executor, signalStrengths[1]);
        } catch (Exception e) {
          DebugLogger.add("secondManager utils registration exception: " + e.getMessage());
        }
      } else {
        nsa[1] = null;
        serviceStates[1] = null;
        dataStates[1] = null;
        signalStrengths[1] = null;
      }
    }

    if (context instanceof Activity) { // to be improved
      try { // currently unstable
        if (firstManager != null) {
          if (physicalChannelDumpers[0] != null)
            physicalChannelDumpers[0].dispose();
          physicalChannelDumpers[0] = new PhysicalChannelDumper(firstManager, context);
        } else {
          if (physicalChannelDumpers[0] != null) {
            physicalChannelDumpers[0].dispose();
          }

          physicalChannelDumpers[0] = null;
        }

        if (secondManager != null) {
          if (physicalChannelDumpers[1] != null)
            physicalChannelDumpers[1].dispose();
          physicalChannelDumpers[1] = new PhysicalChannelDumper(secondManager, context);
        } else {
          if (physicalChannelDumpers[1] != null) {
            physicalChannelDumpers[1].dispose();
          }

          physicalChannelDumpers[1] = null;
        }
      } catch (Exception e) {
        DebugLogger.add("PhysicalChannelDumper registration exception: " + e.getMessage());
      }
    }
  }

  @SuppressLint("MissingPermission")
  public int getSimCount() {
    if (!Permissions.check(context, Permissions.READ_PHONE_STATE))
      return 0;

    SubscriptionManager manager = getSubscriptionManager();
    if (manager == null)
      return 0;

    List<SubscriptionInfo> subscriptions = manager.getActiveSubscriptionInfoList();
    return subscriptions == null ? 0 : subscriptions.size();
  }

  @SuppressLint("MissingPermission")
  public boolean getNsaStatus(TelephonyManager telephony) { // fallback
    if (telephony == null || !Permissions.check(context, Permissions.READ_PHONE_STATE))
      return false;

    ServiceState state = telephony.getServiceState(); // no serviceStates[] since if nsa[] is null it will be null too

    if (state != null) {
      String s = state.toString();

      return s.contains("nrState=CONNECTED") || s.contains("nsaState=5") || s.contains("EnDc=true");
    }

    return false;
  }

  @SuppressLint("MissingPermission")
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

  @SuppressLint("MissingPermission")
  public int getDataStatus(TelephonyManager telephony) {
    if (telephony == null || !Permissions.check(context, Permissions.READ_PHONE_STATE))
      return -1;

    return telephony.getDataState();
  }

  @SuppressLint("MissingPermission")
  public int getDataStatus(int index) {
    int status = -1;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      DataStateListener dataStateListener = dataStates[index];
      if (dataStateListener != null)
        status = dataStateListener.getState();
    }

    if (status == -1) {
      switch (index) {
        case 0:
          status = getDataStatus(firstManager);
          break;
        case 1:
          status = getDataStatus(secondManager);
          break;
      }
    }

    return status;
  }

  @SuppressLint("MissingPermission")
  public CellSignalStrength[] getSignalStrengths(TelephonyManager telephony) {
    if (telephony == null || !Permissions.check(context, Permissions.READ_PHONE_STATE))
      return null;

    SignalStrength signalStrength = telephony.getSignalStrength();
    if (signalStrength == null)
      return null;

    return signalStrength.getCellSignalStrengths().toArray(new CellSignalStrength[0]);
  }

  @SuppressLint("MissingPermission")
  public CellSignalStrength[] getSignalStrengths(int index) {
    CellSignalStrength[] cellSignalStrength = null;

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      SignalStrengthsListener signalStrengthsListener = signalStrengths[index];
      if (signalStrengthsListener != null)
        cellSignalStrength = signalStrengthsListener.getLatestSignalStrengths();
    }

    if (cellSignalStrength == null) {
      switch (index) {
        case 0:
          cellSignalStrength = getSignalStrengths(firstManager);
          break;
        case 1:
          cellSignalStrength = getSignalStrengths(secondManager);
          break;
      }
    }

    return cellSignalStrength;
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
