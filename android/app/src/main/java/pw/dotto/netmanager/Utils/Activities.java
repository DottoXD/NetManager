package pw.dotto.netmanager.Utils;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;

import androidx.core.content.ContextCompat;

public class Activities {
    public static void openRadioInfo(Context context) {
        Intent intent = new Intent(Intent.ACTION_MAIN);
        intent.setComponent(new ComponentName("com.android.phone", "com.android.phone.settings.RadioInfo"));
        context.startActivity(intent);
    }
}
