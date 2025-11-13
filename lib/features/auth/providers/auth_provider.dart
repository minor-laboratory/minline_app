import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import '../data/auth_repository.dart';

// 현재 사용자 Provider - minorlab_common의 것을 재사용
final currentUserProvider = common.currentUserProvider;

// 인증 상태 Provider - minorlab_common의 것을 재사용
final authStateProvider = common.authStateProvider;

// 로그인 상태 Provider - minorlab_common의 것을 재사용
final isAuthenticatedProvider = common.isAuthenticatedProvider;

// 일반 사용자 로그인 상태 Provider (익명 사용자 제외)
final isRegularUserProvider = common.isRegularUserProvider;

// Auth Controller - minorlab_common의 AuthNotifier를 재사용
final authControllerProvider = common.authNotifierProvider;

// 사용자 프로필 Provider
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return null;

  return await authRepo.getProfile();
});
