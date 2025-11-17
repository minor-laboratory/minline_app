import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;

import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/data/auth_repository.dart';

/// # PasswordChange 화면 (비밀번호 변경)
///
/// ## 파일 정보
/// - 경로: `lib/features/profile/presentation/pages/password_change_page.dart`
/// - 라우트: `/settings/profile/password`
/// - 진입점: ProfileDetailPage → 비밀번호 변경
///
class PasswordChangePage extends ConsumerStatefulWidget {
  const PasswordChangePage({super.key});

  @override
  ConsumerState<PasswordChangePage> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends ConsumerState<PasswordChangePage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  bool? _isEmailUser;
  bool? _hasExistingPassword;
  bool _isCheckingPassword = true;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_updateFormValidity);
    _newPasswordController.addListener(_updateFormValidity);
    _confirmPasswordController.addListener(_updateFormValidity);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserPasswordStatus();
    });
  }

  void _updateFormValidity() {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final bool isValid;
    if (_hasExistingPassword == true) {
      // 기존 비밀번호가 있는 경우: 모든 필드 필수
      isValid =
          currentPassword.isNotEmpty &&
          newPassword.length >= 6 &&
          confirmPassword == newPassword;
    } else {
      // 새 비밀번호 설정: 현재 비밀번호 불필요
      isValid = newPassword.length >= 6 && confirmPassword == newPassword;
    }

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _checkUserPasswordStatus() async {
    final authRepo = ref.read(authRepositoryProvider);

    setState(() {
      _isEmailUser = authRepo.isEmailUser;
    });

    // 비밀번호 존재 여부 확인
    try {
      final hasPassword = await authRepo.hasExistingPassword();
      setState(() {
        _hasExistingPassword = hasPassword;
        _isCheckingPassword = false;
      });
    } catch (e, stackTrace) {
      logger.e('Failed to check password status', e, stackTrace);
      // 에러 발생 시 기본값으로 처리
      setState(() {
        _hasExistingPassword = _isEmailUser; // 이메일 사용자는 비밀번호 있다고 가정
        _isCheckingPassword = false;
      });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSessionExpired() async {
    if (!mounted) return;

    // 1. 사용자에게 재인증 필요 알림
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('auth.reauthentication_required'.tr()),
        backgroundColor: ShadTheme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );

    // 2. 현재 화면을 닫고 로그인 화면으로 이동
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      // 현재 화면 닫기
      if (Navigator.of(context).canPop()) {
        context.pop();
      }

      // 재인증을 위한 로그인 화면으로 이동
      context.push('/auth/login?reauthentication=true');
    }
  }

  Future<void> _handlePasswordChange() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);

      if (_hasExistingPassword == true) {
        // 기존 비밀번호가 있는 사용자: 현재 비밀번호 먼저 검증
        await authRepo.verifyCurrentPassword(_currentPasswordController.text);

        // 검증 통과 후 비밀번호 변경
        await authRepo.updatePassword(_newPasswordController.text);
      } else {
        // 비밀번호가 없는 사용자: 새 비밀번호 설정
        await authRepo.setPassword(_newPasswordController.text);
      }

      if (!mounted) return;

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasExistingPassword == true
                ? 'messages.password_changed_success'.tr()
                : 'messages.password_set_success'.tr(),
          ),
          backgroundColor: ShadTheme.of(context).colorScheme.primary,
        ),
      );

      // 이전 화면으로 돌아가기
      context.pop();
    } catch (e, stackTrace) {
      logger.e('Password change failed', e, stackTrace);

      if (!mounted) return;

      // 에러 메시지 세분화
      String errorMessage;
      final errorString = e.toString();

      if (errorString.contains('Current password is incorrect')) {
        errorMessage = 'auth.current_password_incorrect'.tr();
      } else if (errorString.contains('Session expired')) {
        // 세션 만료 시 자동 로그아웃 및 로그인 화면으로 이동
        await _handleSessionExpired();
        return; // 에러 메시지 표시하지 않고 바로 리턴
      } else if (errorString.contains('Password is too weak')) {
        errorMessage = 'auth.password_too_weak'.tr();
      } else if (errorString.contains(
        'Password must be at least 6 characters',
      )) {
        errorMessage = 'validation.passwordMin'.tr();
      } else if (errorString.contains('New password must be different')) {
        errorMessage = 'auth.password_must_be_different'.tr();
      } else if (errorString.contains('Authentication failed')) {
        errorMessage = 'auth.authentication_failed'.tr();
      } else {
        errorMessage = 'error.errorOccurred'.tr(args: [e.toString()]);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: ShadTheme.of(context).colorScheme.destructive,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPassword) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _hasExistingPassword == true
              ? 'settings.change_password'.tr()
              : 'settings.set_password'.tr(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(common.Spacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 설명 텍스트
                ShadCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        AppIcons.info,
                        color: ShadTheme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: common.Spacing.sm),
                      Text(
                        _hasExistingPassword == true
                            ? 'settings.change_password_description'.tr()
                            : 'settings.set_password_description'.tr(),
                        style: ShadTheme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: common.Spacing.lg),

                // 현재 비밀번호 (기존 비밀번호가 있는 사용자만)
                if (_hasExistingPassword == true) ...[
                  Builder(
                    builder: (context) {
                      String? errorText;
                      final value = _currentPasswordController.text;
                      if (value.isEmpty) {
                        errorText = 'validation.required'.tr();
                      }

                      return Column(
                        key: const Key('current_password_field'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShadInput(
                            controller: _currentPasswordController,
                            placeholder: Text('auth.currentPassword'.tr()),
                            obscureText: _obscureCurrentPassword,
                            enabled: !_isLoading,
                            leading: Padding(
                              padding: EdgeInsets.only(
                                left: common.Spacing.md,
                                right: common.Spacing.sm,
                              ),
                              child: Icon(AppIcons.password, size: 20),
                            ),
                            trailing: Padding(
                              padding: EdgeInsets.only(
                                right: common.Spacing.xs,
                              ),
                              child: ShadButton.ghost(
                                width: 40,
                                height: 40,
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    _obscureCurrentPassword =
                                        !_obscureCurrentPassword;
                                  });
                                },
                                child: Icon(
                                  _obscureCurrentPassword
                                      ? AppIcons.eye
                                      : AppIcons.eyeOff,
                                  size: 20,
                                ),
                              ),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                          if (errorText != null && value.isEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                top: common.Spacing.sm,
                                left: common.Spacing.sm + common.Spacing.xs,
                              ),
                              child: Text(
                                errorText,
                                style: TextStyle(
                                  color: ShadTheme.of(
                                    context,
                                  ).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: common.Spacing.md),
                ],

                // 새 비밀번호
                Builder(
                  builder: (context) {
                    String? errorText;
                    final value = _newPasswordController.text;
                    if (value.isEmpty) {
                      errorText = 'validation.required'.tr();
                    } else if (value.length < 6) {
                      errorText = 'validation.passwordMin'.tr();
                    }

                    return Column(
                      key: const Key('new_password_field'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShadInput(
                          controller: _newPasswordController,
                          placeholder: Text(
                            _hasExistingPassword == true
                                ? 'auth.newPassword'.tr()
                                : 'auth.password'.tr(),
                          ),
                          obscureText: _obscureNewPassword,
                          enabled: !_isLoading,
                          leading: Padding(
                            padding: EdgeInsets.only(
                              left: common.Spacing.sm + common.Spacing.xs,
                              right: common.Spacing.sm,
                            ),
                            child: Icon(AppIcons.passwordOutline, size: 20),
                          ),
                          trailing: Padding(
                            padding: const EdgeInsets.only(right: common.Spacing.xs),
                            child: ShadButton.ghost(
                              width: 40,
                              height: 40,
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                              child: Icon(
                                _obscureNewPassword
                                    ? AppIcons.eye
                                    : AppIcons.eyeOff,
                                size: 20,
                              ),
                            ),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                        if (errorText != null && value.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              top: common.Spacing.sm,
                              left: common.Spacing.sm + common.Spacing.xs,
                            ),
                            child: Text(
                              errorText,
                              style: TextStyle(
                                color: ShadTheme.of(context).colorScheme.destructive,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: common.Spacing.md),

                // 비밀번호 확인
                Builder(
                  builder: (context) {
                    String? errorText;
                    final value = _confirmPasswordController.text;
                    if (value.isEmpty) {
                      errorText = 'validation.required'.tr();
                    } else if (value != _newPasswordController.text) {
                      errorText = 'validation.passwordNotMatch'.tr();
                    }

                    return Column(
                      key: const Key('confirm_password_field'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShadInput(
                          controller: _confirmPasswordController,
                          placeholder: Text('auth.confirmPassword'.tr()),
                          obscureText: _obscureConfirmPassword,
                          enabled: !_isLoading,
                          leading: Padding(
                            padding: EdgeInsets.only(
                              left: common.Spacing.sm + common.Spacing.xs,
                              right: common.Spacing.sm,
                            ),
                            child: Icon(AppIcons.passwordOutline, size: 20),
                          ),
                          trailing: Padding(
                            padding: const EdgeInsets.only(right: common.Spacing.xs),
                            child: ShadButton.ghost(
                              width: 40,
                              height: 40,
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              child: Icon(
                                _obscureConfirmPassword
                                    ? AppIcons.eye
                                    : AppIcons.eyeOff,
                                size: 20,
                              ),
                            ),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                        if (errorText != null && value.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              top: common.Spacing.sm,
                              left: common.Spacing.sm + common.Spacing.xs,
                            ),
                            child: Text(
                              errorText,
                              style: TextStyle(
                                color: ShadTheme.of(context).colorScheme.destructive,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: common.Spacing.xl),

                // 확인 버튼
                ShadButton(
                  key: const Key('password_change_submit_button'),
                  enabled: _isFormValid && !_isLoading,
                  onPressed: _isLoading ? null : _handlePasswordChange,
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ShadTheme.of(context).colorScheme.primaryForeground,
                          ),
                        )
                      : Text(
                          _hasExistingPassword == true
                              ? 'common.change'.tr()
                              : 'common.set'.tr(),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
