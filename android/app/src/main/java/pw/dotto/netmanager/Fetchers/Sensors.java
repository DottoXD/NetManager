package pw.dotto.netmanager.Fetchers;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Handler;
import android.os.Looper;

/**
 * NetManager's Sensors class is a component which is used to detect sensors
 * data.
 *
 * @author DottoXD
 * @version 0.0.3
 */
public class Sensors implements SensorEventListener {
    private static final int DESTROY_TIMEOUT = 5000;

    private static Sensors instance;
    private final SensorManager sensorManager;
    private Sensor accelerometer;
    private final float[] lastAccelerometerData = new float[3];

    private final Handler handler = new Handler(Looper.getMainLooper());
    private long lastAccess;

    public Sensors(Context context) {
        sensorManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);

        if (sensorManager != null) {
            accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
            sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL);
            updateAccess();
        }
    }

    public static synchronized Sensors getInstance(Context context) {
        if (context == null)
            return null;

        if (instance == null) {
            instance = new Sensors(context.getApplicationContext());
        }

        return instance;
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int i) {
    }

    @Override
    public void onSensorChanged(SensorEvent sensorEvent) {
        if (sensorEvent.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
            System.arraycopy(sensorEvent.values, 0, lastAccelerometerData, 0, sensorEvent.values.length);
        }
    }

    public float[] getAccelerometerData() {
        updateAccess();
        return lastAccelerometerData;
    }

    /**
     * Updates the latest access to sensor data.
     */
    public void updateAccess() {
        lastAccess = System.currentTimeMillis();
        handler.removeCallbacks(selfDestruct);
        handler.postDelayed(selfDestruct, DESTROY_TIMEOUT);
    }

    private final Runnable selfDestruct = this::destroy;

    /**
     * Disposes the Sensors object.
     */
    public void destroy() {
        sensorManager.unregisterListener(this);
        instance = null;
    }
}
