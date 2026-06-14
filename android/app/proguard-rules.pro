# Flutter / general
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core — referenced by Flutter's PlayStoreDeferredComponentManager.
# This app has no Play Core dependency, so suppress R8 missing-class warnings.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
