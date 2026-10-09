package com.njerahouse.tafsiri

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Text recognition (ADR-075). Registered by hand rather than as a
        // plugin: it is one method, and a plugin package would be another
        // place for Tesseract's build to live.
        TesseractChannel.register(flutterEngine)
    }
}
