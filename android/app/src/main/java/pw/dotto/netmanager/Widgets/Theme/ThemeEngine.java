package pw.dotto.netmanager.Widgets.Theme;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Build;
import android.widget.RemoteViews;
import pw.dotto.netmanager.R;

/**
 * NetManager's ThemeEngine class is the essential component for NetManager's
 * home screen widgets.
 * This class handles all choices about the widgets aesthetics.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class ThemeEngine {
    private static Palette load(Context context) {
        SharedPreferences prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);

        boolean isDark = prefs.getBoolean("flutter.darkTheme", true);
        boolean isDynamic = prefs.getBoolean("flutter.dynamicTheme", true);
        int primary = ((Long) prefs.getLong("flutter.themeColor", Color.parseColor("#E6F0F2"))).intValue();

        int secondary, tertiary;
        boolean dynamicSupported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S;
        if (isDynamic && dynamicSupported) {
            primary = context
                    .getColor(isDark ? android.R.color.system_accent1_200 : android.R.color.system_accent1_600);
            secondary = context
                    .getColor(isDark ? android.R.color.system_accent2_200 : android.R.color.system_accent2_600);
            tertiary = context
                    .getColor(isDark ? android.R.color.system_accent3_200 : android.R.color.system_accent3_600);
        } else {
            secondary = rotateHue(primary, 30f);
            tertiary = rotateHue(primary, -30f);
        }

        float hue = hueOf(primary);
        Palette p = new Palette();

        // might be inaccurate, found off the internet...still...it's acceptable
        p.surface = hsv(hue, 0.06f, isDark ? 0.11f : 0.98f);
        p.surfaceHigh = hsv(hue, 0.10f, isDark ? 0.18f : 0.93f);
        p.onSurface = hsv(hue, 0.04f, isDark ? 0.96f : 0.10f);
        p.onSurfaceVariant = hsv(hue, 0.10f, isDark ? 0.76f : 0.34f);

        p.primary = tone(primary, isDark, 0.75f, 0.45f);
        p.onPrimary = tone(primary, isDark, 0.10f, 0.98f);
        p.primaryContainer = tone(primary, isDark, 0.30f, 0.85f);
        p.onPrimaryContainer = tone(primary, isDark, 0.90f, 0.15f);

        p.secondary = tone(secondary, isDark, 0.70f, 0.42f);
        p.onSecondary = tone(secondary, isDark, 0.10f, 0.98f);
        p.secondaryContainer = tone(secondary, isDark, 0.28f, 0.82f);
        p.onSecondaryContainer = tone(secondary, isDark, 0.88f, 0.16f);

        p.tertiary = tone(tertiary, isDark, 0.68f, 0.44f);
        p.onTertiary = tone(tertiary, isDark, 0.10f, 0.98f);
        p.tertiaryContainer = tone(tertiary, isDark, 0.28f, 0.82f);
        p.onTertiaryContainer = tone(tertiary, isDark, 0.88f, 0.16f);

        return p;
    }

    private static int tone(int base, boolean isDark, float darkV, float lightV) {
        float[] hsv = new float[3];
        Color.colorToHSV(base, hsv);
        hsv[1] = Math.min(1f, Math.max(hsv[1], 0.35f));
        hsv[2] = isDark ? darkV : lightV;
        return Color.HSVToColor(hsv);
    }

    private static int hsv(float hue, float sat, float value) {
        return Color.HSVToColor(new float[] { hue, sat, value });
    }

    private static float hueOf(int color) {
        float[] hsv = new float[3];
        Color.colorToHSV(color, hsv);
        return hsv[0];
    }

    private static int rotateHue(int color, float degrees) {
        float[] hsv = new float[3];
        Color.colorToHSV(color, hsv);
        hsv[0] = (hsv[0] + degrees + 360f) % 360f;
        return Color.HSVToColor(hsv);
    }

    public static void applyTheme(Context context, RemoteViews views) {
        Palette p = load(context);

        views.setInt(R.id.widget_bg, "setColorFilter", p.surface);

        int layoutId = views.getLayoutId();
        if (layoutId == R.layout.widget_dualsim) {
            views.setInt(R.id.bg_sim1, "setColorFilter", p.surfaceHigh);
            views.setInt(R.id.bg_sim2, "setColorFilter", p.surfaceHigh);

            views.setInt(R.id.bg_icon_sim1, "setColorFilter", p.primary);
            views.setInt(R.id.bg_icon_sim2, "setColorFilter", p.primary);
            views.setTextColor(R.id.txt_icon_sim1, p.onPrimary);
            views.setTextColor(R.id.txt_icon_sim2, p.onPrimary);

            views.setTextColor(R.id.txt_sim1_title, p.onSurface);
            views.setTextColor(R.id.txt_sim2_title, p.onSurface);

            views.setTextColor(R.id.txt_sim1_signal, p.primary);
            views.setTextColor(R.id.txt_sim2_signal, p.primary);
            views.setTextColor(R.id.txt_sim1_band, p.onSurfaceVariant);
            views.setTextColor(R.id.txt_sim2_band, p.onSurfaceVariant);

            views.setInt(R.id.bg_chip_sim1_tech, "setColorFilter", p.secondaryContainer);
            views.setInt(R.id.bg_chip_sim2_tech, "setColorFilter", p.secondaryContainer);
            views.setTextColor(R.id.txt_sim1_tech, p.onSecondaryContainer);
            views.setTextColor(R.id.txt_sim2_tech, p.onSecondaryContainer);

            views.setInt(R.id.bg_btn_refresh_dualsim, "setColorFilter", p.primaryContainer);
            views.setInt(R.id.img_refresh_dualsim, "setColorFilter", p.onPrimaryContainer);
        } else if (layoutId == R.layout.widget_events) {
            views.setTextColor(R.id.txt_event_empty_title, p.onSurface);
            views.setTextColor(R.id.txt_event_empty_desc, p.onSurfaceVariant);

            views.setInt(R.id.bg_btn_refresh_events, "setColorFilter", p.primaryContainer);
            views.setInt(R.id.img_refresh_events, "setColorFilter", p.onPrimaryContainer);
        }
    }

    public static void applyRowTheme(Context context, RemoteViews row) {
        Palette p = load(context);

        row.setInt(R.id.bg_item, "setColorFilter", p.surfaceHigh);

        row.setInt(R.id.bg_icon_item, "setColorFilter", p.primary);
        row.setTextColor(R.id.txt_icon_item, p.onPrimary);

        row.setTextColor(R.id.txt_item_title, p.onSurface);
        row.setTextColor(R.id.txt_item_time, p.onSurfaceVariant);

        row.setInt(R.id.bg_chip_item_badge, "setColorFilter", p.secondaryContainer);
        row.setTextColor(R.id.txt_item_badge, p.onSecondaryContainer);

        row.setTextColor(R.id.txt_item_desc, p.onSurfaceVariant);
    }

    public static int resolveAccent(Context context) {
        return load(context).primary;
    }

    public static int resolveOnSurfaceVariant(Context context) {
        return load(context).onSurfaceVariant;
    }
}