import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'share_handler_service.dart';

part 'share_handler_provider.g.dart';

/// ShareHandlerService Provider (keepAlive: true)
///
/// 앱 전체 생명주기 동안 유지되는 singleton 서비스
@Riverpod(keepAlive: true)
ShareHandlerService shareHandlerService(Ref ref) {
  final service = ShareHandlerService(ref);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
