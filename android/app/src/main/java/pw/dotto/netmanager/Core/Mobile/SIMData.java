package pw.dotto.netmanager.Core.Mobile;

import java.util.ArrayList;
import java.util.Collections;

import pw.dotto.netmanager.Core.Mobile.CellDatas.CellData;

public class SIMData {
    private final String operator;
    private final String network;
    private final int networkGen;
    private final String homePlmn;
    private final String networkPlmn;
    private CellData primaryCell;
    private float activeBw = 0;
    private final ArrayList<CellData> activeCells = new ArrayList<>();
    private final ArrayList<CellData> neighborCells = new ArrayList<>();

    public SIMData(String operator, String network, int networkGen, String homePlmn, String networkPlmn) {
        this.operator = operator;
        this.network = network;
        this.networkGen = networkGen;
        this.homePlmn = homePlmn;
        this.networkPlmn = networkPlmn;
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

    public String getHomePlmn() {
        return homePlmn;
    }

    public String getNetworkPlmn() {
        return networkPlmn;
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
        if (!activeCells.contains(cellData))
            activeCells.add(cellData);
    }

    public void addNeighborCell(CellData cellData) {
        if (!neighborCells.contains(cellData))
            neighborCells.add(cellData);
    }

    public void removeActiveCell(CellData cellData) {
        if (activeCells.contains(cellData))
            activeCells.remove(cellData);
    }

    public void removeNeighborCell(CellData cellData) {
        if (neighborCells.contains(cellData))
            neighborCells.remove(cellData);
    }

    public void clearActiveCells() {
        activeCells.clear();
        activeCells.add(primaryCell);
    }

    public void clearNeighborCells() {
        neighborCells.clear();
    }

    public CellData[] getActiveCells() {
        return activeCells.toArray(new CellData[0]);
    }

    public void setActiveCells(CellData[] activeCells) {
        clearActiveCells();
        Collections.addAll(this.activeCells, activeCells);
    }

    public CellData[] getNeighborCells() {
        return neighborCells.toArray(new CellData[0]);
    }
}
