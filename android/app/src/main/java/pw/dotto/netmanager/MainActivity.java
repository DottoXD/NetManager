package pw.dotto.netmanager;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import java.util.ArrayList;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import pw.dotto.netmanager.Core.Manager;
import pw.dotto.netmanager.Core.Notification;

public class MainActivity extends FlutterActivity {
  private final String CHANNEL = "pw.dotto.netmanager/telephony";

  private final Manager manager = new Manager(this);
  private final Notification notification = new Notification(this);

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);

    notification.setupNotifications();

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

            case "sendNotification":
              notification.send();
              result.success(true); //eventually return false when it fails due to perms issues
              break;

            case "cancelNotification":
              result.success(true);
              notification.cancel();
              break;

            default:
              result.notImplemented();
              break;
          }
        });

    notification.send();
  }

  public boolean checkPermissions() {
    boolean basePerms = ActivityCompat.checkSelfPermission(
               this, Manifest.permission.ACCESS_FINE_LOCATION)
        == PackageManager.PERMISSION_GRANTED
        && ActivityCompat.checkSelfPermission(
               this, Manifest.permission.READ_PHONE_STATE)
        == PackageManager.PERMISSION_GRANTED;

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
          return basePerms && ActivityCompat.checkSelfPermission(
                  this,
                  Manifest.permission.POST_NOTIFICATIONS)
                  == PackageManager.PERMISSION_GRANTED;
      } else return basePerms;
  }

  private void requestPermissions() {
    ArrayList<String> permissions = new ArrayList<>();
    permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
    permissions.add(Manifest.permission.READ_PHONE_STATE);

    if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) permissions.add(Manifest.permission.POST_NOTIFICATIONS);

    ActivityCompat.requestPermissions(this,
        permissions.toArray(new String[0]),
        1);
  }

  public Manager getManager() {
    return manager;
  }
}
