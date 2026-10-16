package pw.dotto.netmanager.speedtest;

/**
 * NetManager's LatencyResult class is a tiny class which contains a few
 * attributes that represent the calculated latency-correlated data in a Speed
 * test.
 *
 * @author DottoXD
 * @version 0.0.4
 */
public class LatencyResult {
    int avgPing;
    int jitter;
    double packetLoss;
}