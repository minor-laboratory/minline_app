import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'device_info_service.dart';

part 'device_info_provider.g.dart';

/// DeviceInfoService Provider
@riverpod
DeviceInfoService deviceInfoService(Ref ref) {
  return DeviceInfoService();
}
