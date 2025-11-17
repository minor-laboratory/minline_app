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
                    if (imageUri != null) {
                        val imagePath = copyUriToTempFile(imageUri)
                        data["type"] = "image"
                        data["imagePaths"] = if (imagePath != null) listOf(imagePath) else emptyList()
                    }
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                // 이미지 공유 (다중)
                if (type?.startsWith("image/") == true) {
                    val imageUris = intent.getParcelableArrayListExtra<android.net.Uri>(Intent.EXTRA_STREAM)
                    if (imageUris != null) {
                        val imagePaths = imageUris.mapNotNull { copyUriToTempFile(it) }
                        data["type"] = "images"
                        data["imagePaths"] = imagePaths
                    }
                }
            }
        }

        return data
    }

    /**
     * content:// URI를 임시 파일로 복사
     */
    private fun copyUriToTempFile(uri: android.net.Uri): String? {
        try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null

            // 파일 확장자 추출 (MIME type 기반)
            val mimeType = contentResolver.getType(uri)
            val extension = when {
                mimeType?.startsWith("image/jpeg") == true -> "jpg"
                mimeType?.startsWith("image/jpg") == true -> "jpg"
                mimeType?.startsWith("image/png") == true -> "png"
                mimeType?.startsWith("image/gif") == true -> "gif"
                mimeType?.startsWith("image/webp") == true -> "webp"
                else -> "jpg" // 기본값
            }

            // 임시 파일 생성
            val tempDir = cacheDir
            val fileName = "shared_image_${System.currentTimeMillis()}.$extension"
            val tempFile = java.io.File(tempDir, fileName)

            // 파일 복사
            tempFile.outputStream().use { output ->
                inputStream.copyTo(output)
            }
            inputStream.close()

            return tempFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }
}
