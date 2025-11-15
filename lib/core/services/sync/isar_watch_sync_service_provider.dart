import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'isar_watch_sync_service.dart';

part 'isar_watch_sync_service_provider.g.dart';

/// IsarWatchSyncService Provider (keepAlive: true)
///
/// 앱 전체 생명주기 동안 유지되는 singleton 서비스
/// LifecycleService에서 로그인 시 시작, 로그아웃 시 중지
@Riverpod(keepAlive: true)
IsarWatchSyncService isarWatchSyncService(Ref ref) {
  final service = IsarWatchSyncService();

  // 서비스 정리는 LifecycleService에서 관리 (로그아웃 시)
  ref.onDispose(() {
    service.stop();
  });

  return service;
}
