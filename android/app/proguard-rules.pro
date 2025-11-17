## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

## Dart 엔진
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.embedding.android.FlutterActivity { *; }

## Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

## Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

## Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

## Gson (Firebase 사용)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

## 모델 클래스 유지 (Isar, Supabase JSON 직렬화)
-keep class com.minorlab.miniline.models.** { *; }

## Play Core (Flutter deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
