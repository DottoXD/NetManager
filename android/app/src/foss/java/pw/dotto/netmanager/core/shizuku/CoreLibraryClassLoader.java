
/*
 * Copyright (C) 2021-2025 LSPosed.
 *
 * Derived from the CoreOjClassLoader fallback in
 * LSPosed/AndroidHiddenApiBypass (Apache License 2.0):
 * https://github.com/LSPosed/AndroidHiddenApiBypass
 *
 * Adapted for NetManager.
 */
package pw.dotto.netmanager.core.shizuku;

import dalvik.system.PathClassLoader;

import java.lang.invoke.MethodHandle;
import java.lang.reflect.Executable;

/**
 * NetManager's CoreLibraryClassLoader loads core classes and falls back to ART
 * layout mirrors when the original definitions are unavailable.
 *
 * @author DottoXD
 * @version 0.2.5
 */
class CoreLibraryClassLoader extends PathClassLoader {
    static String getCoreOjPath() {
        String bootClassPath = System.getProperty("java.boot.class.path", "");

        if (bootClassPath == null) {
            bootClassPath = "";
        }

        return bootClassPath.split(":", 2)[0];
    }

    public CoreLibraryClassLoader() {
        super(getCoreOjPath(), null);
    }

    @Override
    public Class<?> loadClass(String name) throws ClassNotFoundException {
        if (Object.class.getName().equals(name)) {
            return Object.class;
        }

        try {
            return findClass(name);
        } catch (ClassNotFoundException ignored) {
        }

        if (Executable.class.getName().equals(name)) {
            return TelephonyHiddenApiBypass.ArtExecutableMirror.class;
        }

        if (MethodHandle.class.getName().equals(name)) {
            return TelephonyHiddenApiBypass.ArtMethodHandleMirror.class;
        }

        if (Class.class.getName().equals(name)) {
            return TelephonyHiddenApiBypass.ArtClassMirror.class;
        }

        return super.loadClass(name);
    }
}
