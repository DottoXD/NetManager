package pw.dotto.netmanager.Widgets;

import android.content.Intent;
import android.widget.RemoteViewsService;

public class EventWidgetService extends RemoteViewsService {
    @Override
    public RemoteViewsFactory onGetViewFactory(Intent intent) {
        return new EventWidgetFactory(this.getApplicationContext());
    }
}