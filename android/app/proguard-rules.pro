# Flutter specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep the entry points of the app
-keep class com.mohammad_alameri_soft.manage_malaebna.MainActivity { *; }

# Supabase specific rules
-keep class io.github.jan.supabase.** { *; }
-keep class com.supabase.** { *; }

# Keep Serializable classes and their fields
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# GoogleMaps related rules
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Geolocator rules
-keep class com.baseflow.geolocator.** { *; }

# Image Picker rules
-keep class io.flutter.plugins.imagepicker.** { *; }

# SQLite related rules
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Keep all native methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Don't warn about missing classes from these packages
-dontwarn org.codehaus.**
-dontwarn java.nio.**
-dontwarn java.lang.invoke.**
-dontwarn rx.**
-dontwarn io.netty.**
-dontwarn com.squareup.okhttp.**
-dontwarn okio.**

# Common Android optimizations
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Keep JavaScript interface methods
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Preserve the special static methods that are required in all enumeration classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Preserve all native method names and the names of their classes
-keepclasseswithmembernames class * {
    native <methods>;
}

# Remove debugging logs in release build
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
} 