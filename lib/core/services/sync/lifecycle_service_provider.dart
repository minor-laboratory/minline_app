import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'lifecycle_service.dart';

part 'lifecycle_service_provider.g.dart';

/// LifecycleService Provider (keepAlive: true)
///
/// 앱 전체 생명주기 동안 유지되는 singleton 서비스
/// main.dart에서 초기화 후 앱 전체에서 사용
@Riverpod(keepAlive: true)
LifecycleService lifecycleService(Ref ref) {
  // Ref를 생성자로 전달
  final service = LifecycleService(ref);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
