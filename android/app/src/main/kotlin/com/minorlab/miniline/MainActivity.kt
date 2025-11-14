package com.minorlab.miniline

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.os.Build
import android.view.WindowManager
import androidx.core.view.WindowCompat

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Edge-to-edge 설정 (시스템 바 투명화)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // 추가 시스템 바 설정
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            @Suppress("DEPRECATION")
            window.setFlags(
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            )
        }

        // 상태바와 내비게이션바 완전 투명화
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.TRANSPARENT
    }
}
