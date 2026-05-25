# Flutter ProGuard Rules

# Keep WorkManager classes (prevents WorkDatabase instantiation crash in release mode)
-keep class androidx.work** { *; }
-keep class androidx.work.impl** { *; }
-dontwarn androidx.work**

# Keep Room Database implementation classes (WorkManager uses Room)
-keep class * extends androidx.room.RoomDatabase
-dontwarn androidx.room**

# Keep Google Mobile Ads classes
-keep class com.google.android.gms.ads** { *; }
-dontwarn com.google.android.gms.ads**
