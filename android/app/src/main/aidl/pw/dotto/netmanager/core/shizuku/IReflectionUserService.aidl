package pw.dotto.netmanager.core.shizuku;

interface IReflectionUserService {
    int getHiddenIntField(in byte[] signalStrengthBytes, String className, String fieldName) = 1;
    String getAdvancedState(int subId) = 2;
    String setCarrierConfig(int subId, String feature, String value, String packageName) = 3;
    int getExecutionUid() = 4;
    String executeNetworkLockCommand(String requestJson) = 5;
    void destroy() = 16777114;
}
