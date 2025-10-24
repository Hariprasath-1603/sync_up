package com.example.sync_up

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Allow screenshots by clearing the FLAG_SECURE flag
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}
