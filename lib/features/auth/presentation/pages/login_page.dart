import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart' hide ShadTheme;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_icons.dart';

/// 로그인 페이지
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Email form state
  bool _showEmailForm = false;
  bool _isLoginMode = true;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  String? _nameError;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.removeListener(_validateForm);
    _emailController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 이메일 유효성 검사
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.+]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
  }

  // 폼 유효성 검사
  void _validateForm() {
    setState(() {
      // Name validation (signup only)
      if (!_isLoginMode) {
        if (_nameController.text.isEmpty) {
          _nameError = null;
        } else if (_nameController.text.trim().length < 2) {
          _nameError = 'validation.name_too_short'.tr();
        } else {
          _nameError = null;
        }
      }

      // Email validation
      if (_emailController.text.isEmpty) {
        _emailError = null;
      } else if (!_isValidEmail(_emailController.text)) {
        _emailError = 'validation.email_invalid'.tr();
      } else {
        _emailError = null;
      }

      // Password validation
      if (_passwordController.text.isEmpty) {
        _passwordError = null;
      } else if (_passwordController.text.length < 6) {
        _passwordError = 'validation.password_too_short'.tr();
      } else {
        _passwordError = null;
      }

      // Form valid check
      final emailValid = _emailController.text.isNotEmpty &&
          _emailError == null &&
          _isValidEmail(_emailController.text);
      final passwordValid = _passwordController.text.isNotEmpty &&
          _passwordError == null &&
          _passwordController.text.length >= 6;
      final nameValid = _isLoginMode ||
          (_nameController.text.trim().isNotEmpty && _nameError == null);

      _isFormValid = emailValid && passwordValid && nameValid;
    });
  }

  // 이메일 로그인/회원가입
  Future<void> _handleEmailAuth() async {
    if (!_isFormValid) {
      _validateForm();
      if (!_isFormValid) {
        _showSnackBar('validation.check_inputs'.tr(), isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await ref.read(common.authNotifierProvider.notifier).signInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        if (!mounted) return;
        _showSnackBar('auth.login_success'.tr(), isSuccess: true);
        context.go('/');
      } else {
        await ref.read(common.authNotifierProvider.notifier).signUpWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              name: _nameController.text.trim().isEmpty
                  ? null
                  : _nameController.text.trim(),
            );

        if (!mounted) return;
        _showSnackBar('auth.signup_success'.tr(), isSuccess: true);
        context.go('/');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          'error.errorOccurred'.tr(args: [e.toString()]), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Google 로그인
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(common.authNotifierProvider.notifier).signInWithGoogle();

      if (!mounted) return;
      _showSnackBar('auth.login_success'.tr(), isSuccess: true);
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          'error.errorOccurred'.tr(args: [e.toString()]), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Apple 로그인
  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(common.authNotifierProvider.notifier).signInWithApple();

      if (!mounted) return;
      _showSnackBar('auth.login_success'.tr(), isSuccess: true);
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          'error.errorOccurred'.tr(args: [e.toString()]), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // URL 열기
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showSnackBar('error.cannot_open_url'.tr(), isError: true);
      }
    }
  }

  void _showSnackBar(String message,
      {bool isError = false, bool isSuccess = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? theme.colorScheme.error
            : isSuccess
                ? theme.extension<common.MinorLabCustomColors>()?.success
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo & Title
                    Icon(
                      AppIcons.sparkles,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'auth.welcome_message'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // 소셜 로그인 or 이메일 폼
                    if (!_showEmailForm) ...[
                      // Social login buttons
                      ShadButton.outline(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        width: double.infinity,
                        size: ShadButtonSize.lg,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.google, size: 20),
                            const SizedBox(width: 12),
                            Text('auth.sign_in_with_google'.tr()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ShadButton.outline(
                        onPressed: _isLoading ? null : _handleAppleSignIn,
                        width: double.infinity,
                        size: ShadButtonSize.lg,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.apple, size: 20),
                            const SizedBox(width: 12),
                            Text('auth.sign_in_with_apple'.tr()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.2))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'auth.or'.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.2))),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 이메일로 계속하기 버튼
                      ShadButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() => _showEmailForm = true);
                              },
                        width: double.infinity,
                        size: ShadButtonSize.lg,
                        child: Text('auth.continue_with_email'.tr()),
                      ),
                    ] else ...[
                      // 이메일 로그인/회원가입 폼
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 뒤로가기 버튼
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _showEmailForm = false;
                                            _isLoginMode = true;
                                            _nameController.clear();
                                            _emailController.clear();
                                            _passwordController.clear();
                                            _emailError = null;
                                            _passwordError = null;
                                            _nameError = null;
                                          });
                                        },
                                  icon: Icon(AppIcons.arrowBack, size: 20),
                                  label: Text('common.cancel'.tr()),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Mode Toggle
                              Row(
                                children: [
                                  Expanded(
                                    child: ShadButton(
                                      onPressed: () {
                                        setState(() => _isLoginMode = true);
                                        _validateForm();
                                      },
                                      backgroundColor: _isLoginMode
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      foregroundColor: _isLoginMode
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      child: Text('auth.login'.tr()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ShadButton(
                                      onPressed: () {
                                        setState(() => _isLoginMode = false);
                                        _validateForm();
                                      },
                                      backgroundColor: !_isLoginMode
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      foregroundColor: !_isLoginMode
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                      child: Text('auth.sign_up'.tr()),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Name field (signup only)
                              if (!_isLoginMode) ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ShadInput(
                                      controller: _nameController,
                                      placeholder: Text('auth.name_hint'.tr()),
                                      leading: Icon(AppIcons.user, size: 20),
                                      enabled: !_isLoading,
                                    ),
                                    if (_nameController.text.isNotEmpty &&
                                        _nameError != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _nameError!,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShadInput(
                                    controller: _emailController,
                                    placeholder: Text('auth.email_hint'.tr()),
                                    leading: Icon(AppIcons.email, size: 20),
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !_isLoading,
                                  ),
                                  if (_emailController.text.isNotEmpty &&
                                      _emailError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _emailError!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShadInput(
                                    controller: _passwordController,
                                    placeholder:
                                        Text('auth.password_hint'.tr()),
                                    leading: Icon(AppIcons.passwordOutline,
                                        size: 20),
                                    trailing: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? AppIcons.eyeOff
                                            : AppIcons.eye,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword =
                                            !_obscurePassword);
                                      },
                                    ),
                                    obscureText: _obscurePassword,
                                    enabled: !_isLoading,
                                    onSubmitted: (_) {
                                      if (_isFormValid) _handleEmailAuth();
                                    },
                                  ),
                                  if (_passwordController.text.isNotEmpty &&
                                      _passwordError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _passwordError!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // Forgot password (login mode only)
                              if (_isLoginMode) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => context
                                            .push('/auth/reset-password'),
                                    child: Text(
                                      'auth.forgot_password'.tr(),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),

                              // Submit button
                              ShadButton(
                                onPressed:
                                    (_isLoading || !_isFormValid) ? null : _handleEmailAuth,
                                width: double.infinity,
                                size: ShadButtonSize.lg,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isLoginMode
                                            ? 'auth.login'.tr()
                                            : 'auth.sign_up'.tr(),
                                        style: theme.textTheme.labelLarge,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Terms & Privacy
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        children: [
                          TextSpan(text: 'auth.by_continuing'.tr()),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: 'auth.terms_of_service'.tr(),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  _launchUrl(AppConstants.termsOfServiceUrl),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: 'auth.and'.tr()),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: 'auth.privacy_policy'.tr(),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () =>
                                  _launchUrl(AppConstants.privacyPolicyUrl),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
