package pw.dotto.netmanager.Speedtest;

import java.util.ArrayList;
import java.util.List;

/**
 * NetManager's StabilityTracker class is a an essential component for
 * NetManager's Speed test module which calculates how stable a certain value is
 * during a test.
 * It is used to calculate the stability of the download and upload speed and
 * used to eventually end the Speed test early if the calculated speed seems
 * correct (and therefore stable) enough.
 *
 * @author DottoXD
 * @version 0.0.4
 */
public class StabilityTracker {
    private final long windowMs;
    private final int minSamples;
    private final double threshold;
    private final List<double[]> samples = new ArrayList<>();

    StabilityTracker(long windowMs, int minSamples, double threshold) {
        this.windowMs = windowMs;
        this.minSamples = minSamples;
        this.threshold = threshold;
    }

    void record(long currentMs, double speed) {
        samples.add(new double[] { currentMs, speed });

        long diff = currentMs - windowMs;
        samples.removeIf(s -> s[0] < diff);
    }

    boolean isStable() {
        if (samples.size() < minSamples)
            return false;

        double sum = 0;
        for (double[] s : samples)
            sum += s[1];

        double mean = sum / samples.size();
        if (mean <= 0)
            return false;

        double variance = 0;
        for (double[] s : samples)
            variance += Math.pow(s[1] - mean, 2);

        double standardDeviation = Math.sqrt(variance / samples.size());

        return (standardDeviation / mean) < threshold;
    }
}