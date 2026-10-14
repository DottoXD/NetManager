package pw.dotto.netmanager.Core.Shizuku;

interface IReflectionUserService {
    int getHiddenIntField(in byte[] signalStrengthBytes, String className, String fieldName) = 1;
    String getAdvancedState(int subId) = 2;
    void destroy() = 16777114;
}
