import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'device_info_service.dart';

part 'device_info_provider.g.dart';

/// DeviceInfoService Provider (keepAlive: true)
///
/// 앱 전체 생명주기 동안 유지되는 singleton 서비스
@Riverpod(keepAlive: true)
DeviceInfoService deviceInfoService(Ref ref) {
  final service = DeviceInfoService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
