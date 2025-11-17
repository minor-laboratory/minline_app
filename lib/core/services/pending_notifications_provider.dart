import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'pending_notifications_service.dart';

part 'pending_notifications_provider.g.dart';

/// PendingNotificationsService Provider (keepAlive)
@Riverpod(keepAlive: true)
PendingNotificationsService pendingNotificationsService(Ref ref) {
  final service = PendingNotificationsService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
