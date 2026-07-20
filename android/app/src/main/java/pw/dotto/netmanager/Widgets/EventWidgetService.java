package pw.dotto.netmanager.Widgets;

import android.content.Intent;
import android.widget.RemoteViewsService;

/**
 * NetManager's EventWidgetService class is an essential component for the home
 * events widget.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class EventWidgetService extends RemoteViewsService {
    @Override
    public RemoteViewsFactory onGetViewFactory(Intent intent) {
        return new EventWidgetFactory(this.getApplicationContext());
    }
}