package pw.dotto.netmanager.Fetchers;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;

public class Sensors implements SensorEventListener {
    private static Sensors instance;
    private final SensorManager sensorManager;
    private Sensor accelerometer;

    private final float[] lastAccelerometerData = new float[3];

    public Sensors(Context context) {
        sensorManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);

        if (sensorManager != null) {
            accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
            sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL);
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
        return lastAccelerometerData;
    }

    public void destroy() {
        sensorManager.unregisterListener(this);
        instance = null;
    }
}
