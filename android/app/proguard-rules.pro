-keep class pw.dotto.netmanager.Core.Mobile.** { *; }
-keep class pw.dotto.netmanager.Core.Events.** { *; }
-keep class pw.dotto.netmanager.Recording.** { *; }
-keep class pw.dotto.netmanager.Utils.DeviceData { *; }

-keep class pw.dotto.netmanager.Core.Listeners.ExtendedPhoneStateListener { *; }
-keep class pw.dotto.netmanager.Core.Listeners.LegacyPhoneStateListener { *; }

-keep class pw.dotto.netmanager.Core.Processors.Preprocessors.** { *; }
-keep class pw.dotto.netmanager.Core.Processors.Postprocessors.** { *; }

-dontwarn pw.dotto.netmanager.Core.Listeners.**

-keepattributes Signature, *Annotation*, Exceptions, InnerClasses, EnclosingMethod