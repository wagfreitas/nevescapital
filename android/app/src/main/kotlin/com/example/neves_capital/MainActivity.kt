package com.example.neves_capital

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.nevescapital.pagpag.SecurityPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Registrar plugin de segurança
        flutterEngine.plugins.add(SecurityPlugin())
    }
}
