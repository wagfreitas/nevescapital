package com.pagpag.app

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import com.pagpag.app.SecurityPlugin

// Use FlutterFragmentActivity so plugins that require a FragmentActivity (like local_auth)
// work correctly on Android.
class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Permitir desenho atrás da status bar e navigation bar (transparência real)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                splashScreenView.remove()
            }
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Registrar plugin de segurança
        flutterEngine.plugins.add(SecurityPlugin())
    }
}

