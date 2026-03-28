package com.example.smoothssh // KEEP YOUR PACKAGE NAME HERE

import android.view.KeyEvent
// CHANGED: We need FragmentActivity for local_auth to work!
import io.flutter.embedding.android.FlutterFragmentActivity 
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() { // CHANGED HERE
    private val CHANNEL = "smoothssh/volume"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "moveToBackground") {
                moveTaskToBack(true) 
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
            methodChannel?.invokeMethod("volumeUp", null)
            return true 
        }
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            methodChannel?.invokeMethod("volumeDown", null)
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}