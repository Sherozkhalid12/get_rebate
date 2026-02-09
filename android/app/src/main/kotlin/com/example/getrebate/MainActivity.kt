package com.example.getrebate

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Set window background to primary blue IMMEDIATELY to prevent white flash
        // This must be done before super.onCreate() to ensure no white screen appears
        val primaryBlue = Color.parseColor("#2563EB")
        
        // Set status bar and navigation bar colors
        window?.statusBarColor = primaryBlue
        window?.navigationBarColor = primaryBlue
        
        // Set window background color directly (not transparent)
        window?.decorView?.setBackgroundColor(primaryBlue)
        
        // Make sure system bars are drawn
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window?.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        }
        
        super.onCreate(savedInstanceState)
    }
}
