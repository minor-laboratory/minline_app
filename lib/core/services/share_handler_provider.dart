import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'share_handler_service.dart';

part 'share_handler_provider.g.dart';

/// ShareHandlerService Provider
@riverpod
ShareHandlerService shareHandlerService(Ref ref) {
  return ShareHandlerService();
}
