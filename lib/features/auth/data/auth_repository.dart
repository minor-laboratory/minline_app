import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/database_service.dart';
import '../../../core/services/sync/sync_metadata_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/network_error_handler.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(Supabase.instance.client);
}

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // 현재 사용자 정보
  User? get currentUser => _supabase.auth.currentUser;

  // 인증 상태 스트림
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // 이메일 로그인
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    logger.i('Sign in attempt with email: $email');
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        logger.i('Login successful for user: ${response.user!.id}');
        await _reinitializeDatabase();
      }
      return response;
    } catch (e, stackTrace) {
      logger.e('Sign in failed', e, stackTrace);
      NetworkErrorHandler.logError(e, 'Email sign in', stackTrace);
      throw Exception(NetworkErrorHandler.getErrorMessage(e));
    }
  }

  // 이메일 회원가입
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    logger.i('Sign up attempt with email: $email');
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );

      // 프로필 생성
      if (response.user != null) {
        logger.i('Sign up successful for user: ${response.user!.id}');
        await _createUserProfile(response.user!.id, email, name);
      }

      return response;
    } catch (e, stackTrace) {
      logger.e('Sign up failed', e, stackTrace);
      NetworkErrorHandler.logError(e, 'Email sign up', stackTrace);
      throw Exception(NetworkErrorHandler.getErrorMessage(e));
    }
  }

  // Google 로그인
  Future<AuthResponse> signInWithGoogle() async {
    logger.i('Google sign in attempt');
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.minorlab.miniline://login-callback',
      );

      if (currentUser != null) {
        logger.i('Google login successful for user: ${currentUser!.id}');
        await _reinitializeDatabase();
      }

      return AuthResponse(user: currentUser);
    } catch (e, stackTrace) {
      logger.e('Google sign in failed', e, stackTrace);
      NetworkErrorHandler.logError(e, 'Google sign in', stackTrace);
      throw Exception(NetworkErrorHandler.getErrorMessage(e));
    }
  }

  // Apple 로그인
  Future<AuthResponse> signInWithApple() async {
    logger.i('Apple sign in attempt');
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'com.minorlab.miniline://login-callback',
      );

      if (currentUser != null) {
        logger.i('Apple login successful for user: ${currentUser!.id}');
        await _reinitializeDatabase();
      }

      return AuthResponse(user: currentUser);
    } catch (e, stackTrace) {
      logger.e('Apple sign in failed', e, stackTrace);
      NetworkErrorHandler.logError(e, 'Apple sign in', stackTrace);
      throw Exception(NetworkErrorHandler.getErrorMessage(e));
    }
  }

  // 로그아웃 (미니라인: 익명 전환 없음)
  Future<void> signOut() async {
    logger.i('Sign out initiated');

    try {
      // 1. Supabase 로그아웃
      await _supabase.auth.signOut();

      // 2. DatabaseService 초기화 확인
      await DatabaseService.instance.init();

      // 3. Isar 데이터베이스 정리
      await DatabaseService.instance.reset();
      logger.i('Local database cleared successfully');

      // 4. 동기화 메타데이터 초기화
      await SyncMetadataService.resetAllSyncMetadata();
      logger.i('Sync metadata cleared');

      logger.i('Sign out completed successfully');
    } catch (e) {
      logger.e('Error during sign out cleanup', e);
      // 로그아웃은 성공했으므로 에러는 로깅만 하고 throw하지 않음
    }
  }

  // 세션 갱신 시도
  Future<bool> tryRefreshSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session?.refreshToken != null) {
        final response = await _supabase.auth.refreshSession();
        return response.session != null;
      }
      return false;
    } catch (e) {
      logger.e('Session refresh failed', e);
      return false;
    }
  }

  // 현재 사용자가 비밀번호를 가지고 있는지 확인
  Future<bool> hasExistingPassword() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final identities = await _supabase.auth.getUserIdentities();
      final hasEmailProvider = identities.any((identity) =>
        identity.provider == 'email'
      );

      logger.i('User identities check: hasEmailProvider=$hasEmailProvider, '
        'providers=${identities.map((i) => i.provider).join(", ")}');

      return hasEmailProvider;
    } catch (e, stackTrace) {
      logger.e('Failed to check user identities', e, stackTrace);
      return isEmailUser;
    }
  }

  // 현재 비밀번호 검증
  Future<void> verifyCurrentPassword(String currentPassword) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    if (user.email == null) {
      throw Exception('Email not available');
    }

    try {
      await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );
      logger.i('Current password verified for user: ${user.id}');
    } catch (e, stackTrace) {
      logger.e('Current password verification failed', e, stackTrace);
      NetworkErrorHandler.logError(e, 'Password verification', stackTrace);

      if (e is AuthException) {
        switch (e.code) {
          case 'invalid_credentials':
            throw Exception('Current password is incorrect');
          case 'bad_jwt':
            throw Exception('Session expired. Please login again');
          default:
            if (e.message.contains('Invalid login credentials')) {
              throw Exception('Current password is incorrect');
            }
        }
      }

      throw Exception(NetworkErrorHandler.getErrorMessage(e));
    }
  }

  // 비밀번호 변경
  Future<void> updatePassword(String newPassword) async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      logger.i('Password updated successfully for user: $userId');
    } catch (e, stackTrace) {
      logger.e('Password update failed', e, stackTrace);
      NetworkErrorHandler.logError(e, 'Password update', stackTrace);

      if (e is AuthException) {
        switch (e.code) {
          case 'weak_password':
            throw Exception('Password is too weak. Please choose a stronger password');
          case 'bad_jwt':
            throw Exception('Session expired. Please login again');
          case 'invalid_credentials':
            throw Exception('Authentication failed. Please try again');
          default:
            if (e.message.contains('Password is too weak')) {
              throw Exception('Password is too weak. Please choose a stronger password');
            }
            if (e.message.contains('Password should be at least')) {
              throw Exception('Password must be at least 6 characters long');
            }
            if (e.message.contains('New password should be different')) {
              throw Exception('New password must be different from current password');
            }
            throw Exception(e.message);
        }
      }

      throw Exception(NetworkErrorHandler.getErrorMessage(e));
    }
  }

  // OAuth 사용자 비밀번호 설정
  Future<void> setPassword(String password) async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: password),
      );
      logger.i('Password set successfully for OAuth user: $userId');
    } catch (e, stackTrace) {
      logger.e('Password setting failed', e, stackTrace);
      NetworkErrorHandler.logError(e, 'Password setting', stackTrace);
      throw Exception(NetworkErrorHandler.getErrorMessage(e));
    }
  }

  // 비밀번호 재설정 이메일 전송
  Future<void> resetPassword(String email) async {
    logger.i('Password reset email requested for: $email');

    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.minorlab.miniline://reset-password',
      );
      logger.i('Password reset email sent successfully to: $email');
    } catch (e, stackTrace) {
      logger.e('Password reset email failed', e, stackTrace);
      NetworkErrorHandler.logError(e, 'Password reset', stackTrace);

      if (e is AuthException) {
        switch (e.code) {
          case 'invalid_email':
            throw Exception('Invalid email address');
          case 'user_not_found':
            throw Exception('No account found with this email');
          default:
            throw Exception(e.message);
        }
      }

      throw Exception(NetworkErrorHandler.getErrorMessage(e));
    }
  }

  // 사용자 로그인 방법 확인
  bool get isEmailUser {
    final user = currentUser;
    if (user == null) return false;

    final providers = user.appMetadata['providers'] as List?;
    return providers == null ||
           providers.isEmpty ||
           providers.contains('email');
  }

  // OAuth 사용자인지 확인
  bool get isOAuthUser {
    final user = currentUser;
    if (user == null) return false;

    final providers = user.appMetadata['providers'] as List?;
    return providers != null &&
           providers.isNotEmpty &&
           (providers.contains('google') || providers.contains('apple'));
  }

  // 사용자 프로필 생성
  Future<void> _createUserProfile(
    String userId,
    String email,
    String? name,
  ) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'email': email,
        'name': name ?? email.split('@')[0],
      });
    } catch (e) {
      logger.w('Profile creation failed', e);
    }
  }

  // 사용자 프로필 업데이트
  Future<void> updateProfile({String? name, String? photoUrl}) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photo_url'] = photoUrl;

    try {
      await _supabase.from('profiles').update(updates).eq('id', userId);
    } catch (e, stackTrace) {
      NetworkErrorHandler.logError(e, 'Profile update', stackTrace);
      throw Exception(NetworkErrorHandler.getErrorMessage(e));
    }
  }

  // 사용자 프로필 조회
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e, stackTrace) {
      NetworkErrorHandler.logError(e, 'Profile fetch', stackTrace);
      throw Exception(NetworkErrorHandler.getErrorMessage(e));
    }
  }

  // 회원 탈퇴 (미니라인: 익명 전환 없음)
  Future<void> requestWithdrawal() async {
    final userId = currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    logger.i('Starting withdrawal for user: $userId');

    try {
      // 1. profiles 테이블 deleted 플래그 설정
      await _supabase.from('profiles').update({
        'deleted': true,
      }).eq('id', userId);

      // 2. Edge Function을 통한 auth 계정 삭제
      try {
        await _supabase.functions.invoke('delete-user', body: {'user_id': userId});
        logger.i('User account deleted successfully via Edge Function');
      } catch (e) {
        logger.e('Failed to delete user account via Edge Function', e);
      }

      // 3. 로컬 정리
      await DatabaseService.instance.init();
      await DatabaseService.instance.reset();
      logger.i('Local database cleared successfully');

      await SyncMetadataService.resetAllSyncMetadata();
      logger.i('Sync metadata cleared');

      logger.i('User withdrawal completed successfully');
    } catch (e, stackTrace) {
      logger.e('User withdrawal failed', e, stackTrace);
      NetworkErrorHandler.logError(e, 'User withdrawal', stackTrace);
      throw Exception(NetworkErrorHandler.getErrorMessage(e));
    }
  }

  // Isar 데이터베이스 초기화 (로그인 후)
  Future<void> _reinitializeDatabase() async {
    try {
      logger.i('Initializing Isar database for new user...');
      await DatabaseService.instance.init();
      logger.i('Database initialized. Initial sync will be handled by auth state listener');
    } catch (e) {
      logger.e('Error initializing database', e);
    }
  }
}
