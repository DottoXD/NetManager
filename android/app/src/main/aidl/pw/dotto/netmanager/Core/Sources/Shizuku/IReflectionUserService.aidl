package pw.dotto.netmanager.Core.Sources.Shizuku;

interface IReflectionUserService {
    int getHiddenIntField(in byte[] signalStrengthBytes, String className, String fieldName) = 0;

    void destroy() = 16777114;
}
