-keep class pw.dotto.netmanager.Core.Mobile.** { *; }
-keep class pw.dotto.netmanager.Core.Events.** { *; }
-keepclassmembers class pw.dotto.netmanager.Core.Listeners.ExtendedPhoneStateListener {
    public void onPhysicalChannelConfigurationChanged(java.util.List);
}
-keep class pw.dotto.netmanager.Core.Listeners.ExtendedPhoneStateListener { *; }


-keepattributes Signature
-keepattributes *Annotation*
