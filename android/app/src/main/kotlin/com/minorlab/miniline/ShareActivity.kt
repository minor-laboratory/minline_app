package com.minorlab.miniline

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * 공유 수신 전용 투명 Activity
 *
 * 다른 앱에서 공유를 받으면 이 Activity가 실행되며,
 * 투명한 배경 위에 Flutter의 Bottom Sheet로 공유 입력 화면을 표시합니다.
 */
class ShareActivity : FlutterActivity() {
    private val CHANNEL = "com.minorlab.miniline/share"
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 투명 배경 설정
        window.setBackgroundDrawableResource(android.R.color.transparent)
    }

    /**
     * Flutter view를 투명하게 설정
     */
    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel 설정
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "closeShareActivity" -> {
                    finish()
                    result.success(null)
                }
                "getSharedData" -> {
                    val sharedData = extractSharedData()
                    result.success(sharedData)
                }
                "isShareActivity" -> {
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.onDestroy()
    }

    /**
     * Intent에서 공유된 데이터 추출
     */
    private fun extractSharedData(): Map<String, Any?> {
        val intent = intent ?: return emptyMap()
        val action = intent.action
        val type = intent.type

        val data = mutableMapOf<String, Any?>()

        when (action) {
            Intent.ACTION_SEND -> {
                // 텍스트 공유
                if (type == "text/plain") {
                    val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                    data["type"] = "text"
                    data["content"] = text
                }
                // 이미지 공유 (단일)
                else if (type?.startsWith("image/") == true) {
                    val imageUri = intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)
                    data["type"] = "image"
                    data["images"] = listOf(imageUri?.toString())
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                // 이미지 공유 (다중)
                if (type?.startsWith("image/") == true) {
                    val imageUris = intent.getParcelableArrayListExtra<android.net.Uri>(Intent.EXTRA_STREAM)
                    data["type"] = "images"
                    data["images"] = imageUris?.map { it.toString() }
                }
            }
        }

        return data
    }
}
