package pw.dotto.netmanager.Widgets;

import android.content.Context;
import android.content.Intent;
import android.graphics.Typeface;
import android.text.Spannable;
import android.text.SpannableString;
import android.text.style.ForegroundColorSpan;
import android.text.style.StyleSpan;
import android.view.View;
import android.widget.RemoteViews;
import android.widget.RemoteViewsService;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

import pw.dotto.netmanager.Core.Events.EventManager;
import pw.dotto.netmanager.Core.Events.MobileNetManagerEvent;
import pw.dotto.netmanager.Core.Events.NetManagerEvent;
import pw.dotto.netmanager.R;
import pw.dotto.netmanager.Widgets.Theme.ThemeEngine;

public class EventWidgetFactory implements RemoteViewsService.RemoteViewsFactory {
    private static final int MAX_ITEMS = 25;
    private static final DateTimeFormatter DISPLAY_FORMAT = DateTimeFormatter.ofPattern("MMM d, HH:mm");

    private final Context context;
    private NetManagerEvent[] events = new NetManagerEvent[0];

    public EventWidgetFactory(Context context) {
        this.context = context;
    }

    @Override
    public void onDataSetChanged() {
        EventManager em = EventManager.getInstance(context);

        if (em != null) {
            events = em.getEvents();
        }
    }

    @Override
    public int getCount() {
        return Math.min(events.length, MAX_ITEMS);
    }

    @Override
    public RemoteViews getViewAt(int pos) {
        if (pos >= events.length)
            return null;

        RemoteViews row = new RemoteViews(context.getPackageName(), R.layout.item_widget_event);
        NetManagerEvent event = events[events.length - 1 - pos];

        row.setTextViewText(R.id.txt_icon_item, formatIconInitial(event));
        row.setTextViewText(R.id.txt_item_title, formatEventType(event));
        row.setTextViewText(R.id.txt_item_desc, formatOldNew(event));
        row.setTextViewText(R.id.txt_item_time, formatDateTime(event.getDateTime()));

        String badge = formatBadge(event);
        if (badge == null) {
            row.setViewVisibility(R.id.chip_item_badge, View.GONE);
        } else {
            row.setTextViewText(R.id.txt_item_badge, badge);
            row.setViewVisibility(R.id.chip_item_badge, View.VISIBLE);
        }

        ThemeEngine.applyRowTheme(context, row);

        row.setOnClickFillInIntent(R.id.item_root, new Intent());

        return row;
    }

    private String formatEventType(NetManagerEvent event) {
        String raw = event.getEventType().toString();
        if (raw.startsWith("MOBILE_"))
            raw = raw.substring("MOBILE_".length());

        String[] parts = raw.split("_");
        StringBuilder sb = new StringBuilder();
        for (String part : parts) {
            if (part.isEmpty())
                continue;
            if (sb.length() > 0)
                sb.append(' ');
            sb.append(part.charAt(0)).append(part.substring(1).toLowerCase());
        }
        return sb.toString();
    }

    private String formatIconInitial(NetManagerEvent event) {
        String formatted = formatEventType(event);
        return formatted.isEmpty() ? "?" : formatted.substring(0, 1).toUpperCase();
    }

    private CharSequence formatOldNew(NetManagerEvent event) {
        String oldValue = event.getOldValue();
        String newValue = event.getNewValue();

        int accent = ThemeEngine.resolveAccent(context);
        int dim = ThemeEngine.resolveOnSurfaceVariant(context);

        if (oldValue == null || oldValue.isEmpty() || "N/A".equals(oldValue)) {
            SpannableString spannable = new SpannableString(newValue);
            spannable.setSpan(new ForegroundColorSpan(accent), 0, newValue.length(),
                    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            spannable.setSpan(new StyleSpan(Typeface.BOLD), 0, newValue.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
            return spannable;
        }

        String arrowAndNew = " → " + newValue;
        String full = oldValue + arrowAndNew;
        SpannableString spannable = new SpannableString(full);
        spannable.setSpan(new ForegroundColorSpan(dim), 0, oldValue.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
        spannable.setSpan(new ForegroundColorSpan(accent), oldValue.length(), full.length(),
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
        spannable.setSpan(new StyleSpan(Typeface.BOLD), oldValue.length(), full.length(),
                Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
        return spannable;
    }

    private String formatBadge(NetManagerEvent event) {
        if (!(event instanceof MobileNetManagerEvent))
            return null;

        MobileNetManagerEvent mobileEvent = (MobileNetManagerEvent) event;
        String network = mobileEvent.getNetwork();
        String simLabel = "SIM " + (mobileEvent.getSimSlot() + 1);
        if (network == null || network.trim().isEmpty())
            return simLabel;
        return simLabel + " - " + network;
    }

    private String formatDateTime(String rawDateTime) {
        if (rawDateTime == null || rawDateTime.isEmpty())
            return "";
        try {
            return LocalDateTime.parse(rawDateTime).format(DISPLAY_FORMAT);
        } catch (DateTimeParseException e) {
            return rawDateTime;
        }
    }

    @Override
    public void onCreate() {
    }

    @Override
    public void onDestroy() {
    }

    @Override
    public RemoteViews getLoadingView() {
        return null;
    }

    @Override
    public int getViewTypeCount() {
        return 1;
    }

    @Override
    public long getItemId(int pos) {
        return pos;
    }

    @Override
    public boolean hasStableIds() {
        return true;
    }
}