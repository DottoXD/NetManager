package pw.dotto.netmanager;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import com.google.errorprone.annotations.FormatString;
import com.google.errorprone.annotations.ImmutableTypeParameter;
import com.google.errorprone.annotations.NoAllocation;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import pw.dotto.netmanager.Core.Manager;

public class MainActivity extends FlutterActivity {
  private final String CHANNEL = "pw.dotto.netmanager/telephony";

  private final Manager manager = new Manager(this);

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    new MethodChannel(
        flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
        .setMethodCallHandler((call, result) -> {
          switch (call.method) {
            case "checkPermissions":
              boolean perms = checkPermissions();
              if (!perms) {
                requestPermissions();
              }
              result.success(perms);
              break;

            case "requestPermissions":
              requestPermissions();
              result.success(true);
              break;

            case "getCarrier":
              String carrier = manager.getCarrier();
              if (!"NetManager".equals(carrier)) {
                result.success(carrier);
              } else {
                result.error(
                    "Unknown", "Unknown", null); // add proper error handling
              }
              break;

            case "getNetworkData":
              String data = manager.getNetworkData();
              result.success(data);
              break;

            case "getNetworkGen":
              int gen = manager.getNetworkGen();
              result.success(gen);
              break;

            default:
              result.notImplemented();
              break;
          }
        });
  }

  public boolean checkPermissions() {
    return ActivityCompat.checkSelfPermission(
               this, Manifest.permission.ACCESS_FINE_LOCATION)
        == PackageManager.PERMISSION_GRANTED
        && ActivityCompat.checkSelfPermission(
               this, Manifest.permission.READ_PHONE_STATE)
        == PackageManager.PERMISSION_GRANTED
        && ActivityCompat.checkSelfPermission(
               this, Manifest.permission.POST_NOTIFICATIONS)
        == PackageManager.PERMISSION_GRANTED;
  }

  private void requestPermissions() {
    ActivityCompat.requestPermissions(this,
        new String[] {Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.POST_NOTIFICATIONS},
        1);
  }
}
