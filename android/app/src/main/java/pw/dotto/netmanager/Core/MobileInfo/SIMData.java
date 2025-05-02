package pw.dotto.netmanager.Core.MobileInfo;

import androidx.annotation.NonNull;

import java.util.ArrayList;

public class SIMData {
    private final String operator;
    private final String network;
    private final int networkGen;
    private final String mccMnc;
    private CellData primaryCell;
    private float activeBw = 0;
    private final ArrayList<CellData> activeCells = new ArrayList<>();
    private final ArrayList<CellData> neighborCells = new ArrayList<>();

    public SIMData(String operator, String network, int networkGen, String mccMnc) {
        this.operator = operator;
        this.network = network;
        this.networkGen = networkGen;
        this.mccMnc = mccMnc;
    }

    public String getOperator() {
        return operator;
    }

    public String getNetwork() {
        return network;
    }

    public int getNetworkGen() {
        return networkGen;
    }

    public float getActiveBw() {
        return activeBw;
    }

    public String getMccMnc() {
        return mccMnc;
    }

    public void setPrimaryCell(CellData primaryCell) {
        this.primaryCell = primaryCell;
    }

    public void setActiveBw(float activeBw) {
        this.activeBw = activeBw;
    }

    public CellData getPrimaryCell() {
        return primaryCell;
    }

    public void addActiveCell(CellData cellData) {
        if(!activeCells.contains(cellData)) activeCells.add(cellData);
    }

    public void addNeighborCell(CellData cellData) {
        if(!neighborCells.contains(cellData)) neighborCells.add(cellData);
    }

    public void removeActiveCell(CellData cellData) {
        if(activeCells.contains(cellData)) activeCells.remove(cellData);
    }

    public void removeNeighborCell(CellData cellData) {
        if(neighborCells.contains(cellData)) neighborCells.remove(cellData);
    }

    public void clearNeighborCells() {
        neighborCells.clear();
    }

    public CellData[] getActiveCells() {
        return activeCells.toArray(new CellData[0]);
    }

    public CellData[] getNeighborCells() {
        return neighborCells.toArray(new CellData[0]);
    }
}
