# flutter_local_notifications uses Gson with generic types.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
# Firebase
-keep class io.flutter.plugins.firebase.** { *; }
-dontwarn com.google.android.play.core.**
