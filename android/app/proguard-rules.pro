# Flutter / general
#
# Keeps all of io.flutter EXCEPT the Play Store machinery for "deferred
# components" (ADR-074): PlayStoreDeferredComponentManager and
# FlutterPlayStoreSplitApplication. Those two are the only classes in the
# embedding that reference Google Play Core, which F-Droid's scanner rejects —
# and it rejects references, not just bundled classes, because it reads every
# type name in the dexdump output. The app uses no deferred components (no
# pubspec entry, no `deferred as` import, the stock Application class), so R8
# strips them once nothing forces it to keep them. Removing these exclusions
# brings back exactly six classes and the six Play Core references with them.
-keep class !io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager**,!io.flutter.embedding.android.FlutterPlayStoreSplitApplication,io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Play Core — referenced by Flutter's own deferred-components classes
# above, not by ML Kit as this comment used to say (ADR-074). Those classes
# are stripped now; the -dontwarn lines stay so R8 never fails on the
# reference while tracing, whatever it later decides to keep.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# google_mlkit_text_recognition — optional script recognizers not bundled in base SDK
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
