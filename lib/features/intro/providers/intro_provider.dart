import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../router/app_router.dart' as router;

part 'intro_provider.g.dart';

const _introCompletedKey = 'intro_completed';

/// 인트로 완료 여부를 관리하는 Provider
@Riverpod(keepAlive: true)
class IntroCompleted extends _$IntroCompleted {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_introCompletedKey) ?? false;
  }

  /// 인트로 완료 처리
  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introCompletedKey, true);
    router.setIntroCompleted(); // 라우터 캐시 업데이트
    state = const AsyncValue.data(true);
  }

  /// 인트로 리셋 (테스트/설정용)
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_introCompletedKey);
    state = const AsyncValue.data(false);
  }
}
