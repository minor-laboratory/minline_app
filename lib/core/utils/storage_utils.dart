import '../../env/app_env.dart';

/// 스토리지 관련 유틸리티
class StorageUtils {
  /// 사용자 프로필 이미지 URL 생성
  ///
  /// [userId]: 사용자 ID
  /// [photoPath]: 이미지 경로 (상대 경로 또는 절대 URL)
  ///
  /// Returns: 전체 URL (이미 http로 시작하면 그대로 반환)
  static String getUserPhotoUrl(String userId, String photoPath) {
    // 이미 전체 URL인 경우 그대로 반환
    if (photoPath.startsWith('http')) {
      return photoPath;
    }

    // Supabase URL 가져오기
    final supabaseUrl = AppEnv.supabaseUrl;

    // 상대 경로를 전체 URL로 변환
    return '$supabaseUrl/storage/v1/object/public/users/$userId/$photoPath';
  }
}
