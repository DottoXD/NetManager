package pw.dotto.netmanager.utils;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import androidx.core.content.FileProvider;

import java.io.File;

/**
 * NetManager's FileManager class is a utility component which allows the user
 * to share debug logs, data images and more.
 *
 * @author DottoXD
 * @version 0.1.0
 */
public class FileManager {
    public static void shareFile(Context context, String path, String mimeType, String chooserTitle) {
        File file = new File(path);
        Uri uri = FileProvider.getUriForFile(context, context.getPackageName() + ".fileprovider", file);

        Intent intent = new Intent(Intent.ACTION_SEND)
                .setType(mimeType)
                .putExtra(Intent.EXTRA_STREAM, uri)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

        context.startActivity(Intent.createChooser(intent, chooserTitle));
    }
}
