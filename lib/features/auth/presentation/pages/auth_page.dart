import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';

/// 인증 페이지 (shadcn_ui 완전 기반)
///
/// 디자인 컨셉:
/// - 상단 정렬
/// - shadcn_ui 컴포넌트만 사용
/// - 소셜 로그인 ↔ 이메일 탭 토글
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

enum AuthMethod { social, email }

class _AuthPageState extends ConsumerState<AuthPage> {
  // UI state
  AuthMethod _authMethod = AuthMethod.social;
  bool _isSignUpMode = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // UI state
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Validation
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.+]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
  }

  void _validateForm() {
    setState(() {
      // Name validation (signup only)
      if (_isSignUpMode) {
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

      // Confirm password validation (signup only)
      if (_isSignUpMode) {
        if (_confirmPasswordController.text.isEmpty) {
          _confirmPasswordError = null;
        } else if (_passwordController.text !=
            _confirmPasswordController.text) {
          _confirmPasswordError = 'validation.passwordNotMatch'.tr();
        } else {
          _confirmPasswordError = null;
        }
      }

      // Form valid check
      final emailValid =
          _emailController.text.isNotEmpty &&
          _emailError == null &&
          _isValidEmail(_emailController.text);
      final passwordValid =
          _passwordController.text.isNotEmpty &&
          _passwordError == null &&
          _passwordController.text.length >= 6;
      final nameValid =
          !_isSignUpMode ||
          (_nameController.text.trim().isNotEmpty && _nameError == null);
      final confirmValid =
          !_isSignUpMode ||
          (_confirmPasswordController.text.isNotEmpty &&
              _confirmPasswordError == null);

      _isFormValid = emailValid && passwordValid && nameValid && confirmValid;
    });
  }

  Future<void> _handleEmailAuth() async {
    if (!_isFormValid) {
      _validateForm();
      if (!_isFormValid) {
        _showToast('validation.check_inputs'.tr(), isError: true);
        return;
      }
    }

    logger.i(
      '📧 [AuthPage] 이메일 ${_isSignUpMode ? "회원가입" : "로그인"} 시도: ${_emailController.text}',
    );
    setState(() => _isLoading = true);

    try {
      if (_isSignUpMode) {
        await ref
            .read(common.authNotifierProvider.notifier)
            .signUpWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              name: _nameController.text.trim().isEmpty
                  ? null
                  : _nameController.text.trim(),
            );

        logger.i('✅ [AuthPage] 이메일 회원가입 성공');
        if (!mounted) return;
        _showToast('auth.signup_success'.tr(), isSuccess: true);
        context.go('/');
      } else {
        await ref
            .read(common.authNotifierProvider.notifier)
            .signInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        logger.i('✅ [AuthPage] 이메일 로그인 성공');
        if (!mounted) return;
        _showToast('auth.login_success'.tr(), isSuccess: true);
        context.go('/');
      }
    } catch (e, st) {
      logger.e('❌ [AuthPage] 이메일 ${_isSignUpMode ? "회원가입" : "로그인"} 실패', e, st);
      if (!mounted) return;
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    logger.i('🔐 [AuthPage] Google 로그인 시도');
    setState(() => _isLoading = true);

    try {
      await ref.read(common.authNotifierProvider.notifier).signInWithGoogle();

      logger.i('✅ [AuthPage] Google 로그인 성공');
      if (!mounted) return;
      _showToast('auth.login_success'.tr(), isSuccess: true);
      context.go('/');
    } catch (e, st) {
      logger.e('❌ [AuthPage] Google 로그인 실패', e, st);
      if (!mounted) return;
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    logger.i('🍎 [AuthPage] Apple 로그인 시도');
    setState(() => _isLoading = true);

    try {
      await ref.read(common.authNotifierProvider.notifier).signInWithApple();

      logger.i('✅ [AuthPage] Apple 로그인 성공');
      if (!mounted) return;
      _showToast('auth.login_success'.tr(), isSuccess: true);
      context.go('/');
    } catch (e, st) {
      logger.e('❌ [AuthPage] Apple 로그인 실패', e, st);
      if (!mounted) return;
      _showToast(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showToast('error.cannot_open_url'.tr(), isError: true);
      }
    }
  }

  void _showToast(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
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

  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _nameController.clear();
      _confirmPasswordController.clear();
      _nameError = null;
      _confirmPasswordError = null;
      _validateForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(common.Spacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(theme),
                    const SizedBox(height: common.Spacing.xxl),

                    // Main Card
                    ShadCard(
                      child: Padding(
                        padding: const EdgeInsets.all(common.Spacing.xl),
                        child: _authMethod == AuthMethod.social
                            ? _buildSocialLoginContent(theme)
                            : _buildEmailLoginContent(theme),
                      ),
                    ),
                    const SizedBox(height: common.Spacing.xl),

                    // Terms
                    _buildTerms(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    // 이전 페이지가 있는 경우만 AppBar 표시
    if (Navigator.of(context).canPop()) {
      return AppBar(
        leading: IconButton(
          icon: Icon(AppIcons.arrowBack),
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    }
    return null;
  }

  void _clearEmailForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
  }

  Widget _buildSocialLoginContent(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Social Login Buttons
        _buildSocialButtons(),
        const SizedBox(height: common.Spacing.xl),

        // Divider
        Row(
          children: [
            const Expanded(child: ShadSeparator.horizontal()),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: common.Spacing.md,
              ),
              child: Text('auth.or'.tr(), style: theme.textTheme.muted),
            ),
            const Expanded(child: ShadSeparator.horizontal()),
          ],
        ),
        const SizedBox(height: common.Spacing.xl),

        // Email Login Button
        ShadButton.ghost(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() => _authMethod = AuthMethod.email);
                },
          child: Text('auth.continue_with_email'.tr()),
        ),
      ],
    );
  }

  Widget _buildEmailLoginContent(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Form
        _buildEmailForm(theme),
        const SizedBox(height: common.Spacing.xl),

        // Submit Button
        _buildSubmitButton(),
        const SizedBox(height: common.Spacing.md),

        // Mode Toggle
        _buildModeToggle(theme),
        const SizedBox(height: common.Spacing.xl),

        // Divider
        Row(
          children: [
            const Expanded(child: ShadSeparator.horizontal()),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: common.Spacing.md,
              ),
              child: Text('auth.or'.tr(), style: theme.textTheme.muted),
            ),
            const Expanded(child: ShadSeparator.horizontal()),
          ],
        ),
        const SizedBox(height: common.Spacing.xl),

        // Social Login Button
        ShadButton.ghost(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _authMethod = AuthMethod.social;
                    _clearEmailForm();
                  });
                },
          child: Text('auth.continue_with_social'.tr()),
        ),
      ],
    );
  }

  Widget _buildHeader(ShadThemeData theme) {
    return Column(
      children: [
        Icon(AppIcons.sparkles, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: common.Spacing.md),
        Text(
          AppConstants.appName,
          style: theme.textTheme.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: common.Spacing.sm),
        Text(
          'auth.welcome_message'.tr(),
          style: theme.textTheme.muted,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadButton.outline(
          onPressed: _isLoading ? null : _handleGoogleSignIn,
          size: ShadButtonSize.lg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.google, size: 18),
              const SizedBox(width: common.Spacing.md),
              Text('auth.sign_in_with_google'.tr()),
            ],
          ),
        ),
        const SizedBox(height: common.Spacing.md),
        ShadButton.outline(
          onPressed: _isLoading ? null : _handleAppleSignIn,
          size: ShadButtonSize.lg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.apple, size: 18),
              const SizedBox(width: common.Spacing.md),
              Text('auth.sign_in_with_apple'.tr()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name field (signup only)
        if (_isSignUpMode) ...[
          _buildInputField(
            controller: _nameController,
            placeholder: 'auth.name_hint'.tr(),
            icon: AppIcons.user,
            error: _nameError,
            enabled: !_isLoading,
          ),
          const SizedBox(height: common.Spacing.md),
        ],

        // Email field
        _buildInputField(
          controller: _emailController,
          placeholder: 'auth.email_hint'.tr(),
          icon: AppIcons.email,
          error: _emailError,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
        ),
        const SizedBox(height: common.Spacing.md),

        // Password field
        _buildPasswordField(
          controller: _passwordController,
          placeholder: 'auth.password_hint'.tr(),
          obscure: _obscurePassword,
          error: _passwordError,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          enabled: !_isLoading,
          onSubmitted: !_isSignUpMode && _isFormValid ? _handleEmailAuth : null,
        ),

        // Confirm password (signup only)
        if (_isSignUpMode) ...[
          const SizedBox(height: common.Spacing.md),
          _buildPasswordField(
            controller: _confirmPasswordController,
            placeholder: 'auth.confirmPassword'.tr(),
            obscure: _obscureConfirmPassword,
            error: _confirmPasswordError,
            onToggleObscure: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            enabled: !_isLoading,
            onSubmitted: _isFormValid ? _handleEmailAuth : null,
          ),
        ],

        // Forgot password (login only)
        if (!_isSignUpMode) ...[
          const SizedBox(height: common.Spacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: ShadButton.ghost(
              onPressed: _isLoading
                  ? null
                  : () => context.push('/auth/reset-password'),
              child: Text('auth.forgot_password'.tr()),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    String? error,
    TextInputType? keyboardType,
    bool enabled = true,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShadInput(
          controller: controller,
          placeholder: Text(placeholder),
          leading: Icon(icon, size: 20),
          keyboardType: keyboardType,
          enabled: enabled,
          onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
        ),
        if (controller.text.isNotEmpty && error != null) ...[
          const SizedBox(height: common.Spacing.xs),
          Text(
            error,
            style: ShadTheme.of(context).textTheme.small.copyWith(
              color: ShadTheme.of(context).colorScheme.destructive,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String placeholder,
    required bool obscure,
    String? error,
    required VoidCallback onToggleObscure,
    bool enabled = true,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShadInput(
          controller: controller,
          placeholder: Text(placeholder),
          leading: Icon(AppIcons.passwordOutline, size: 20),
          trailing: ShadButton.ghost(
            width: 24,
            height: 24,
            padding: EdgeInsets.zero,
            onPressed: onToggleObscure,
            child: Icon(obscure ? AppIcons.eyeOff : AppIcons.eye, size: 16),
          ),
          obscureText: obscure,
          enabled: enabled,
          onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
        ),
        if (controller.text.isNotEmpty && error != null) ...[
          const SizedBox(height: common.Spacing.xs),
          Text(
            error,
            style: ShadTheme.of(context).textTheme.small.copyWith(
              color: ShadTheme.of(context).colorScheme.destructive,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ShadButton(
      onPressed: (_isLoading || !_isFormValid) ? null : _handleEmailAuth,
      size: ShadButtonSize.lg,
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(_isSignUpMode ? 'auth.sign_up'.tr() : 'auth.login'.tr()),
    );
  }

  Widget _buildModeToggle(ShadThemeData theme) {
    return Center(
      child: ShadButton.ghost(
        onPressed: _isLoading ? null : _toggleMode,
        child: Text(
          _isSignUpMode
              ? 'auth.already_have_account'.tr()
              : 'auth.dont_have_account'.tr(),
        ),
      ),
    );
  }

  Widget _buildTerms(ShadThemeData theme) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: theme.textTheme.muted,
        children: [
          TextSpan(text: '${'auth.by_continuing'.tr()} '),
          TextSpan(
            text: 'auth.terms_of_service'.tr(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(AppConstants.termsOfServiceUrl),
          ),
          TextSpan(text: ' ${'auth.and'.tr()} '),
          TextSpan(
            text: 'auth.privacy_policy'.tr(),
            style: TextStyle(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(AppConstants.privacyPolicyUrl),
          ),
          TextSpan(text: ' ${'auth.agree_to_terms'.tr()}'),
        ],
      ),
    );
  }
}
