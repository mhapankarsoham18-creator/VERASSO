# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Services & Nearby Connections
-keep class com.google.android.gms.nearby.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Supabase (PostgREST & Realtime models via JSON reflection)
-keep class io.supabase.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Hive
-keep class io.hive.** { *; }

# Firebase App Check & Core
-keep class com.google.firebase.** { *; }
-keep class com.google.firebase.appcheck.** { *; }

# Freezed/JsonSerializable
-keep class * implements java.io.Serializable {
    *;
}
