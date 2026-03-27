package pw.dotto.netmanager.Utils;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import androidx.core.content.FileProvider;

import java.io.File;

/**
 * NetManager's FileManager class is a utility component which allows the user
 * to share debug logs and band images.
 *
 * @author DottoXD
 * @version 0.0.4
 */
public class FileManager {
    public static void shareLog(Context context, String path) {
        File file = new File(path);
        Uri uri = FileProvider.getUriForFile(context, context.getPackageName() + ".fileprovider", file);
        Intent intent = new Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_STREAM, uri)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

        context.startActivity(Intent.createChooser(intent, "Share logs"));
    }

    public static void shareImage(Context context, String path) {
        File file = new File(path);
        Uri uri = FileProvider.getUriForFile(context, context.getPackageName() + ".fileprovider", file);
        Intent intent = new Intent(Intent.ACTION_SEND).setType("img/png").putExtra(Intent.EXTRA_STREAM, uri)
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

        context.startActivity(Intent.createChooser(intent, "Share image"));
    }
}
