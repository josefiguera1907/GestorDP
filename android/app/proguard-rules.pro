# Optimizaciones para dispositivos de 2GB RAM (Zebra TC26)
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

# Remover logs en producción para reducir memoria
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
}

# Optimizar strings no utilizados
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    static void checkParameterIsNotNull(java.lang.Object, java.lang.String);
}

# Preservar clases necesarias
-keep class com.paqueteria.paqueteria_app.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Mobile Scanner
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# SQLite
-keep class androidx.sqlite.** { *; }
-keep class org.sqlite.** { *; }

# Provider
-keepclassmembers class * extends androidx.lifecycle.ViewModel {
    <init>(...);
}

# Preservar anotaciones
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Optimizaciones específicas para dispositivos móviles
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
