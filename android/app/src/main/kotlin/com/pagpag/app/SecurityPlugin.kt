package com.pagpag.app

import android.app.Activity
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Plugin de Segurança
 * 
 * Implementa MASVS-PLATFORM standards no Android:
 * - MASVS-PLATFORM-1: FLAG_SECURE para prevenir screenshots
 * - MASVS-RESILIENCE-1: Detecção de root
 * - MASVS-RESILIENCE-2: Detecção de debugger
 */
class SecurityPlugin: FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.pagpag.app/security")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enableScreenshotProtection" -> {
                enableScreenshotProtection()
                result.success(true)
            }
            "disableScreenshotProtection" -> {
                disableScreenshotProtection()
                result.success(true)
            }
            "setWindowSecure" -> {
                val secure = call.argument<Boolean>("secure") ?: true
                setWindowSecure(secure)
                result.success(true)
            }
            "isDeviceCompromised" -> {
                result.success(isDeviceRooted())
            }
            "isDebuggerConnected" -> {
                result.success(isDebuggerConnected())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Habilitar FLAG_SECURE para prevenir screenshots
     * MASVS-PLATFORM-1: Protege dados sensíveis
     */
    private fun enableScreenshotProtection() {
        activity?.window?.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    /**
     * Desabilitar FLAG_SECURE
     */
    private fun disableScreenshotProtection() {
        activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    /**
     * Configurar janela como segura ou não
     */
    private fun setWindowSecure(secure: Boolean) {
        if (secure) {
            enableScreenshotProtection()
        } else {
            disableScreenshotProtection()
        }
    }

    /**
     * Detectar se dispositivo está com root
     * MASVS-RESILIENCE-1: Detecção de ambiente comprometido
     */
    private fun isDeviceRooted(): Boolean {
        return checkRootMethod1() || checkRootMethod2() || checkRootMethod3()
    }

    // Método 1: Verificar arquivos su
    private fun checkRootMethod1(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        
        for (path in paths) {
            if (File(path).exists()) {
                return true
            }
        }
        return false
    }

    // Método 2: Verificar build tags
    private fun checkRootMethod2(): Boolean {
        val buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    // Método 3: Verificar apps de root comuns
    private fun checkRootMethod3(): Boolean {
        val packages = arrayOf(
            "com.noshufou.android.su",
            "com.noshufou.android.su.elite",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.thirdparty.superuser",
            "com.yellowes.su",
            "com.topjohnwu.magisk"
        )
        
        val pm = activity?.packageManager
        for (packageName in packages) {
            try {
                pm?.getPackageInfo(packageName, 0)
                return true
            } catch (e: Exception) {
                // Package não encontrado, continuar
            }
        }
        return false
    }

    /**
     * Detectar se debugger está conectado
     * MASVS-RESILIENCE-2: Detecção de debugging
     */
    private fun isDebuggerConnected(): Boolean {
        return android.os.Debug.isDebuggerConnected() || 
               android.os.Debug.waitingForDebugger()
    }
}

