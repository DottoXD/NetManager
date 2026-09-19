package pw.dotto.netmanager.Core.Sources.Shizuku;

import static pw.dotto.netmanager.Core.Sources.Telephony.TelephonyCellDataSource.CELL_INFO_UNAVAILABLE;

import android.content.Context;
import android.os.IBinder;
import android.os.Parcel;
import android.os.ParcelFileDescriptor;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import pw.dotto.netmanager.Core.Base.SIMSlotState;
import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;
import pw.dotto.netmanager.Core.Mobile.SIMData;
import pw.dotto.netmanager.Core.NetManagerCore;
import pw.dotto.netmanager.Core.Sources.CellDataSource;
import pw.dotto.netmanager.Core.Sources.Telephony.TelephonyCellDataSource;
import pw.dotto.netmanager.Utils.DebugLogger;
import pw.dotto.netmanager.Utils.Permissions;
import rikka.shizuku.Shizuku;
import rikka.shizuku.ShizukuBinderWrapper;
import rikka.shizuku.SystemServiceHelper;

/**
 * NetManager's ShizukuCellDataSource is a mobile cell data source for
 * NetManager which enriches data fetched from Android's Telephony
 * API.
 * ShizukuCellDataSource dumps the telephony.registry system service and
 * manually parses data.
 * This component shall be considered a testing feature.
 *
 * @author DottoXD
 * @version 0.2.1
 */
public class ShizukuCellDataSource implements CellDataSource {
    private static final int TRANSACTION_dump = 0x5f444d50;
    private static final long DUMP_READ_TIMEOUT_MS = 1500;
    private static final String[] RELEVANT_MARKERS = {
            "mPhysicalChannelConfigs",
            "mCellIdentity",
            "mSignalStrength",
            "mServiceState"
    };

    private static final Pattern PCC_ENTRY_PATTERN = Pattern
            .compile("\\{([^{}]*)\\}");
    private static final Pattern CONNECTION_STATUS_PATTERN = Pattern
            .compile("mConnectionStatus=(\\w+)");
    private static final Pattern BANDWIDTH_PATTERN = Pattern
            .compile("mCellBandwidthDownlinkKhz=(\\d+)");
    private static final Pattern PCI_PATTERN = Pattern
            .compile("mPhysicalCellId=(\\d+)");
    private static final Pattern CHANNEL_PATTERN = Pattern
            .compile("mDownlinkChannelNumber=(\\d+)");
    private static final Pattern BAND_PATTERN = Pattern
            .compile("mBand=(\\d+)");

    private static final Pattern CELL_IDENTITY_BANDWIDTH_PATTERN = Pattern
            .compile("mCellIdentity=CellIdentityLte:\\{ mBandwidth=(\\d+)");

    private static final Pattern RSSI_PATTERN = Pattern.compile("rssi=(-?\\d+)");
    private static final Pattern RSRP_PATTERN = Pattern.compile("rsrp=(-?\\d+)");
    private static final Pattern RSRQ_PATTERN = Pattern.compile("rsrq=(-?\\d+)");
    private static final Pattern RSSNR_PATTERN = Pattern.compile("rssnr=(-?\\d+)");
    private static final Pattern TA_PATTERN = Pattern.compile("[^a-zA-Z]ta=(\\d+)");

    private static final Pattern SERVICE_STATE_CHANNEL_PATTERN = Pattern
            .compile("mChannelNumber=(\\d+)");
    private static final Pattern SERVICE_STATE_BANDWIDTHS_PATTERN = Pattern
            .compile("mCellBandwidths=\\[([^]]*)]");

    private final TelephonyCellDataSource baseSource;
    private volatile SIMData pendingSimData;
    private volatile int pendingSimId;

    private final Map<String, AtomicInteger> markerOccurrenceCounters = new HashMap<>();

    public ShizukuCellDataSource(TelephonyCellDataSource baseSource) {
        this.baseSource = baseSource;
    }

    @Override
    public boolean isAvailable(Context context) {
        return Permissions.checkShizuku();
    }

    @Override
    public SIMData fetch(Context context, SIMSlotState simSlotState) {
        SIMData baseData = baseSource.fetch(context, simSlotState);
        NetManagerCore core = NetManagerCore.getInstance(context);

        if (baseData != null && core.isForegroundActive() && core.getAdvancedMode()) {
            pendingSimData = baseData;
            pendingSimId = simSlotState.simId;
            markerOccurrenceCounters.clear();

            try {
                if (dumpTelephonyViaBinder(simSlotState) <= 0) {
                    DebugLogger.add("Shizuku binder dump failed.");

                    dumpTelephonyViaProcess(simSlotState);
                }
            } finally {
                pendingSimData = null;
            }
        }

        return baseData;
    }

    private int dumpTelephonyViaBinder(SIMSlotState simSlotState) {
        ParcelFileDescriptor[] pipe = null;
        Thread readerThread = null;
        AtomicInteger count = new AtomicInteger(0);

        final SIMData targetSimData = pendingSimData;
        final int targetSimId = pendingSimId;

        try {
            IBinder rawBinder = SystemServiceHelper.getSystemService("telephony.registry");
            if (rawBinder == null) {
                DebugLogger.add("Shizuku: telephony.registry binder not found.");
                return -1;
            }

            IBinder binder = new ShizukuBinderWrapper(rawBinder);
            pipe = ParcelFileDescriptor.createPipe();

            ParcelFileDescriptor readSide = pipe[0];
            ParcelFileDescriptor writeSide = pipe[1];

            readerThread = new Thread(() -> {
                try (ParcelFileDescriptor autoCloseRead = readSide;
                        FileInputStream fis = new FileInputStream(autoCloseRead.getFileDescriptor());
                        BufferedReader reader = new BufferedReader(new InputStreamReader(fis))) {

                    String line;
                    while (!Thread.currentThread().isInterrupted() && (line = reader.readLine()) != null) {
                        logRelevantLine(line);
                        count.incrementAndGet();
                    }
                } catch (Exception e) {
                    DebugLogger.add("Shizuku dump reader terminated: " + e.getMessage() + ".");
                }
            }, "ShizukuDumpReader");

            readerThread.setDaemon(true);
            readerThread.start();

            Parcel data = Parcel.obtain();
            Parcel reply = Parcel.obtain();

            try {
                data.writeFileDescriptor(writeSide.getFileDescriptor());
                data.writeStringArray(new String[0]);
                binder.transact(TRANSACTION_dump, data, reply, 0);
            } finally {
                data.recycle();
                reply.recycle();
                closeQuietly(writeSide);
            }

            readerThread.join(DUMP_READ_TIMEOUT_MS);

            if (readerThread.isAlive()) {
                DebugLogger.add("Shizuku dump reader timed out after " + DUMP_READ_TIMEOUT_MS + "ms.");
                readerThread.interrupt();
                closeQuietly(readSide);
            }

            int linesRead = count.get();
            DebugLogger.add("Shizuku binder dump: " + linesRead + " relevant lines found.");
            return linesRead;

        } catch (Exception e) {
            DebugLogger.add("Shizuku binder dump failed for SIM " + simSlotState.simId + ": " + e.getMessage());
            return -1;
        } finally {
            if (pipe != null) {
                closeQuietly(pipe[0]);
                closeQuietly(pipe[1]);
            }
        }
    }

    private void dumpTelephonyViaProcess(SIMSlotState simSlotState) {
        try {
            Method newProcessMethod = Shizuku.class.getDeclaredMethod("newProcess", String[].class, String[].class,
                    String.class);
            newProcessMethod.setAccessible(true);

            Process process = (Process) newProcessMethod.invoke(null,
                    new String[] { "dumpsys", "telephony.registry" }, null, null);

            if (process != null) {
                int count = 0;

                try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        logRelevantLine(line);
                        count++;
                    }
                }
                process.waitFor();

                DebugLogger.add("Shizuku process dump: " + count + " lines found.");
            } else {
                DebugLogger.add("Shizuku process dump: newProcess returned null.");
            }
        } catch (Exception e) {
            DebugLogger
                    .add("Shizuku process dump fallback failed for SIM " + simSlotState.simId + ": " + e.getMessage()
                            + ".");
        }
    }

    private void logRelevantLine(String line) {
        String trimmed = line.trim();

        for (String prefix : RELEVANT_MARKERS) {
            if (trimmed.startsWith(prefix)) {
                DebugLogger.add("Shizuku dump: " + trimmed);

                int occurrenceIndex = markerOccurrenceCounters
                        .computeIfAbsent(prefix, k -> new AtomicInteger(0))
                        .getAndIncrement();

                if (occurrenceIndex == pendingSimId) {
                    parseAndMergeLine(prefix, trimmed);
                }
                return;
            }
        }
    }

    private void parseAndMergeLine(String prefix, String line) {
        try {
            switch (prefix) {
                case "mPhysicalChannelConfigs" -> mergePhysicalChannelConfigs(line);
                case "mCellIdentity" -> mergeCellIdentity(line);
                case "mSignalStrength" -> mergeSignalStrength(line);
                case "mServiceState" -> mergeServiceState(line);
            }
        } catch (Exception e) {
            DebugLogger.add("Shizuku dump line parser failed (" + prefix + "): " + e.getMessage() + ".");
        }
    }

    private void mergePhysicalChannelConfigs(String line) {
        SIMData current = pendingSimData;

        if (current == null)
            return;

        Matcher entryMatcher = PCC_ENTRY_PATTERN.matcher(line);
        while (entryMatcher.find()) {
            String entry = entryMatcher.group(1);

            Integer bandwidthKhz = extractInt(BANDWIDTH_PATTERN, entry);
            Integer pci = extractInt(PCI_PATTERN, entry);
            Integer channelNumber = extractInt(CHANNEL_PATTERN, entry);
            Integer band = extractInt(BAND_PATTERN, entry);
            String status = extractString(CONNECTION_STATUS_PATTERN, entry);

            boolean isServing = status != null
                    && (status.contains("Primary") || status.contains("Secondary"));

            if (channelNumber != null && channelNumber == CELL_INFO_UNAVAILABLE)
                channelNumber = null;
            if (band != null && band == 0)
                band = null;
            if (pci != null && pci == 0)
                pci = null;
            if (bandwidthKhz != null && bandwidthKhz == 0)
                bandwidthKhz = null;

            if (pci == null && channelNumber == null)
                continue;

            CellData match = findMatchingCell(current, pci, channelNumber);
            if (match == null)
                continue;

            if (bandwidthKhz != null && match.getBandwidth() == CELL_INFO_UNAVAILABLE) {
                match.setBandwidth(bandwidthKhz / 1000);
                DebugLogger.add("Shizuku dump: filled bandwidth (" + (bandwidthKhz / 1000) + "MHz) for cell "
                        + match.getCellIdentifier());
            }

            if (band != null && match.getBand() == CELL_INFO_UNAVAILABLE) {
                match.setBand(band);
                DebugLogger.add("Shizuku dump: filled band (" + band + ") for cell " + match.getCellIdentifier());
            }

            if (isServing) {
                promoteToActiveIfNeeded(current, match);
            }
        }
    }

    private void mergeCellIdentity(String line) {
        SIMData current = pendingSimData;
        if (current == null || current.getPrimaryCell() == null)
            return;

        Integer bandwidthKhz = extractInt(CELL_IDENTITY_BANDWIDTH_PATTERN, line);
        if (bandwidthKhz == null || bandwidthKhz == CELL_INFO_UNAVAILABLE)
            return;

        CellData primary = current.getPrimaryCell();
        if (primary.getBandwidth() == CELL_INFO_UNAVAILABLE) {
            primary.setBandwidth(bandwidthKhz / 1000);
            DebugLogger.add("Shizuku dump: filled primary cell bandwidth (" + (bandwidthKhz / 1000)
                    + "MHz) from mCellIdentity.");
        }
    }

    private void mergeSignalStrength(String line) {
        SIMData current = pendingSimData;
        if (current == null || current.getPrimaryCell() == null)
            return;

        CellData primary = current.getPrimaryCell();

        Integer rawSignal = extractInt(RSSI_PATTERN, line);
        Integer processedSignal = extractInt(RSRP_PATTERN, line);
        Integer signalQuality = extractInt(RSRQ_PATTERN, line);
        Integer signalNoise = extractInt(RSSNR_PATTERN, line);
        Integer timingAdvance = extractInt(TA_PATTERN, line);

        if (rawSignal != null && rawSignal != CELL_INFO_UNAVAILABLE
                && primary.getRawSignal() == CELL_INFO_UNAVAILABLE) {
            primary.setRawSignal(rawSignal);
        }
        if (processedSignal != null && processedSignal != CELL_INFO_UNAVAILABLE
                && primary.getProcessedSignal() == CELL_INFO_UNAVAILABLE) {
            primary.setProcessedSignal(processedSignal);
        }
        if (signalQuality != null && signalQuality != CELL_INFO_UNAVAILABLE
                && primary.getSignalQuality() == CELL_INFO_UNAVAILABLE) {
            primary.setSignalQuality(signalQuality);
        }
        if (signalNoise != null && signalNoise != CELL_INFO_UNAVAILABLE
                && primary.getSignalNoise() == CELL_INFO_UNAVAILABLE) {
            primary.setSignalNoise(signalNoise);
        }
        if (timingAdvance != null && timingAdvance != CELL_INFO_UNAVAILABLE
                && primary.getTimingAdvance() == CELL_INFO_UNAVAILABLE) {
            primary.setTimingAdvance(timingAdvance);
        }

        DebugLogger.add("Shizuku dump: merged available mSignalStrength fields into primary cell.");
    }

    private void mergeServiceState(String line) {
        SIMData current = pendingSimData;
        if (current == null || current.getPrimaryCell() == null)
            return;

        CellData primary = current.getPrimaryCell();

        Integer channelNumber = extractInt(SERVICE_STATE_CHANNEL_PATTERN, line);
        if (channelNumber != null && channelNumber != CELL_INFO_UNAVAILABLE
                && primary.getChannelNumber() == CELL_INFO_UNAVAILABLE) {
            primary.setChannelNumber(channelNumber);
            DebugLogger.add("Shizuku dump: filled primary cell channel (" + channelNumber
                    + ") from mServiceState.");
        }

        Matcher bandwidthsMatcher = SERVICE_STATE_BANDWIDTHS_PATTERN.matcher(line);
        if (bandwidthsMatcher.find() && primary.getBandwidth() == CELL_INFO_UNAVAILABLE) {
            String firstValue = bandwidthsMatcher.group(1).split(",")[0].trim();

            if (!firstValue.isEmpty()) {
                int bandwidthKhz = Integer.parseInt(firstValue);
                primary.setBandwidth(bandwidthKhz / 1000);
                DebugLogger.add("Shizuku dump: filled primary cell bandwidth (" + (bandwidthKhz / 1000)
                        + "MHz) from mServiceState.");
            }
        }
    }

    private CellData findMatchingCell(SIMData simData, Integer pci, Integer channelNumber) {
        for (CellData candidate : allKnownCells(simData)) {
            boolean pciMatches = pci != null && candidate.getStationIdentity() == pci;
            boolean channelMatches = channelNumber != null && candidate.getChannelNumber() == channelNumber;

            if (pciMatches || channelMatches)
                return candidate;
        }

        return null;
    }

    private List<CellData> allKnownCells(SIMData simData) {
        List<CellData> all = new ArrayList<>();
        if (simData.getPrimaryCell() != null)
            all.add(simData.getPrimaryCell());

        Collections.addAll(all, simData.getActiveCells());
        Collections.addAll(all, simData.getLikelyCells());
        Collections.addAll(all, simData.getNeighborCells());

        return all;
    }

    private void promoteToActiveIfNeeded(SIMData simData, CellData match) {
        for (CellData active : simData.getActiveCells()) {
            if (active == match)
                return;
        }

        match.setIsRegistered(true);
        simData.removeLikelyCell(match);
        simData.removeNeighborCell(match);
        simData.addActiveCell(match);
        DebugLogger.add("Shizuku dump: promoted cell " + match.getCellIdentifier() + " to active.");
    }

    private Integer extractInt(Pattern pattern, String text) {
        Matcher m = pattern.matcher(text);
        return m.find() ? Integer.parseInt(m.group(1)) : null;
    }

    private String extractString(Pattern pattern, String text) {
        Matcher m = pattern.matcher(text);
        return m.find() ? m.group(1) : null;
    }

    private void closeQuietly(ParcelFileDescriptor pfd) {
        try {
            pfd.close();
        } catch (Exception ignored) {
        }
    }
}