package pw.dotto.netmanager.Core;

public class CellInfoData { // temp - soon to be remade
  private boolean registered;
  private String cellId;
  private String type;

  // GSM
  private String arfcn;
  private String bsic;
  private String lac;

  // WCDMA
  private String uarfcn;
  private String psc;
  private String ecno;

  // LTE
  private String earfcn;
  private String pci;
  private String tac;
  private String bw;
  private String bands;
  private String rsrp;
  private String rsrq;
  private String snr;
  private String ta;
  private String rssi;

  public CellInfoData(boolean registered, String cellId, String type,
      String arfcn, String bsic, String lac) {
    this.registered = registered;
    this.cellId = cellId;
    this.type = type;
    this.arfcn = arfcn;
    this.bsic = bsic;
    this.lac = lac;
  }

  public CellInfoData(boolean registered, String cellId, String type,
      String uarfcn, String psc, String lac, String ecno) {
    this.registered = registered;
    this.cellId = cellId;
    this.type = type;
    this.uarfcn = uarfcn;
    this.psc = psc;
    this.lac = lac;
    this.ecno = ecno;
  }

  public CellInfoData(boolean registered, String cellId, String type,
      String earfcn, String pci, String tac, String bw, String bands,
      String rsrp, String rsrq, String snr, String ta, String rssi) {
    this.registered = registered;
    this.cellId = cellId;
    this.type = type;
    this.earfcn = earfcn;
    this.pci = pci;
    this.tac = tac;
    this.bw = bw;
    this.bands = bands;
    this.rsrp = rsrp;
    this.rsrq = rsrq;
    this.snr = snr;
    this.ta = ta;
    this.rssi = rssi;
  }
}