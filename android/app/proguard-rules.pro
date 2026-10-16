-keep class pw.dotto.netmanager.core.mobile.** { *; }
-keep class pw.dotto.netmanager.core.events.** { *; }
-keep class pw.dotto.netmanager.recording.** { *; }
-keep class pw.dotto.netmanager.utils.DeviceData { *; }

-keep class pw.dotto.netmanager.core.listeners.ExtendedPhoneStateListener { *; }
-keep class pw.dotto.netmanager.core.listeners.LegacyPhoneStateListener { *; }

-keep class pw.dotto.netmanager.core.processors.Preprocessors.** { *; }
-keep class pw.dotto.netmanager.core.processors.Postprocessors.** { *; }

-keep class pw.dotto.netmanager.core.sources.Diag.** { *; }
-keep class pw.dotto.netmanager.core.sources.Shizuku.** { *; }
-keep class pw.dotto.netmanager.core.diag.** { *; }
-keep class pw.dotto.netmanager.core.shizuku.** { *; }

-dontwarn pw.dotto.netmanager.core.listeners.**

-keepattributes Signature, *Annotation*, Exceptions, InnerClasses, EnclosingMethod
