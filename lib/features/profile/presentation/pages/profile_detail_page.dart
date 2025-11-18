import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/brand_colors.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/storage_utils.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../widgets/logout_confirmation_bottom_sheet.dart';

/// # ProfileDetail 화면 (프로필 상세)
///
/// ## 파일 정보
/// - 경로: `lib/features/profile/presentation/pages/profile_detail_page.dart`
/// - 라우트: `/profile`
/// - 진입점: Settings → UserProfileSection 클릭
///
/// ## 주요 기능
/// - 프로필 편집 (이름, 프로필 이미지)
/// - 로그인 provider 정보 표시
/// - 비밀번호 설정/변경
/// - 로그아웃
/// - 회원 탈퇴
///
class ProfileDetailPage extends ConsumerStatefulWidget {
  const ProfileDetailPage({super.key});

  @override
  ConsumerState<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends ConsumerState<ProfileDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isDeletingImage = false;
  bool _isImageUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      _nameController.text = profile['name'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        // 이미지 선택 즉시 자동 저장
        await _saveProfileImage();
      }
    } catch (e, stackTrace) {
      logger.e('Failed to pick image', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.image_selection_failed'.tr())),
        );
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    setState(() {
      _isDeletingImage = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      // 프로필에서 photo_url 제거
      await supabase
          .from('profiles')
          .update({'photo_url': null})
          .eq('id', userId);

      // Storage에서 이미지 삭제
      final profile = ref.read(userProfileProvider).value;
      if (profile?['photo_url'] != null) {
        final photoUrl = profile!['photo_url'] as String;
        final fileName = photoUrl.split('/').last;
        await supabase.storage.from('users').remove(['$userId/$fileName']);
      }

      // 프로필 새로고침
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('profile_image_deleted'.tr())));
      }
    } catch (e, stackTrace) {
      logger.e('Failed to delete profile image', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_image_delete_failed'.tr()),
            backgroundColor: ShadTheme.of(context).colorScheme.destructive,
          ),
        );
      }
    } finally {
      setState(() {
        _isDeletingImage = false;
      });
    }
  }

  /// 프로필 이미지만 저장
  Future<void> _saveProfileImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isImageUploading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User is not logged in');
      }

      // 이미지 업로드
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'users/$userId/$fileName';

      logger.i('Uploading image to: users/$filePath');

      final bytes = await _selectedImage!.readAsBytes();
      logger.i('Image size: ${bytes.length} bytes');

      await supabase.storage
          .from('users')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // 프로필에서 이미지 URL 업데이트
      await supabase
          .from('profiles')
          .update({'photo_url': fileName})
          .eq('id', userId);

      // 프로필 새로고침
      ref.invalidate(userProfileProvider);

      // 선택된 이미지 초기화 (업로드 완료)
      setState(() {
        _selectedImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('profile_image_updated'.tr())));
      }
    } catch (e, stackTrace) {
      logger.e('Failed to save profile image', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_image_save_failed'.tr()),
            backgroundColor: ShadTheme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isImageUploading = false;
      });
    }
  }

  /// 프로필 이름만 저장
  Future<void> _saveProfileName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length < 2) return;

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) return;

      await supabase.from('profiles').update({'name': name}).eq('id', userId);

      // 프로필 새로고침
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('profile_name_updated'.tr())));
      }
    } catch (e, stackTrace) {
      logger.e('Failed to save profile name', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_name_save_failed'.tr()),
            backgroundColor: ShadTheme.of(context).colorScheme.destructive,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final profile = ref.watch(userProfileProvider).value;
    final currentPhotoUrl = profile?['photo_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text('profile.title'.tr()),
        actions: [
          PopupMenuButton<String>(
            padding: const EdgeInsets.all(common.Spacing.xs),
            iconSize: 18,
            icon: Icon(
              AppIcons.moreVert,
              color: theme.colorScheme.mutedForeground,
            ),
            tooltip: 'settings.advanced_settings'.tr(),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'withdrawal',
                child: Row(
                  children: [
                    Icon(
                      AppIcons.delete,
                      color: theme.colorScheme.destructive,
                      size: 16,
                    ),
                    SizedBox(width: common.Spacing.sm),
                    Text(
                      'withdrawal_title'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.destructive,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              if (value == 'withdrawal') {
                context.push('/settings/account/withdrawal');
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(common.Spacing.md),
          children: [
            // 프로필 이미지
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.muted,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : currentPhotoUrl != null
                        ? CachedNetworkImageProvider(
                                StorageUtils.getUserPhotoUrl(
                                  ref.read(currentUserProvider)?.id ?? '',
                                  currentPhotoUrl,
                                ),
                              )
                              as ImageProvider
                        : null,
                    child: (_selectedImage == null && currentPhotoUrl == null)
                        ? Icon(
                            AppIcons.user,
                            size: 60,
                            color: theme.colorScheme.mutedForeground,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isImageUploading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primaryForeground,
                                  ),
                                ),
                              )
                            : Icon(AppIcons.camera),
                        color: theme.colorScheme.onPrimary,
                        onPressed: _isImageUploading ? null : _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (currentPhotoUrl != null || _selectedImage != null)
              Center(
                child: ShadButton.ghost(
                  onPressed: _isDeletingImage
                      ? null
                      : () {
                          if (_selectedImage != null) {
                            setState(() {
                              _selectedImage = null;
                            });
                          } else {
                            _deleteProfileImage();
                          }
                        },
                  leading: _isDeletingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(AppIcons.delete, size: 16),
                  foregroundColor: theme.colorScheme.destructive,
                  child: Text(
                    _selectedImage != null
                        ? 'common.cancel'.tr()
                        : 'profile_image_delete'.tr(),
                  ),
                ),
              ),

            SizedBox(height: common.Spacing.xl),

            // 이름 입력 (자동 저장)
            ShadInputFormField(
              controller: _nameController,
              label: Text('profile_name'.tr()),
              placeholder: Text('profile_name_hint'.tr()),
              validator: (value) {
                if (value.trim().isEmpty) {
                  return 'profile_name_required'.tr();
                }
                if (value.trim().length < 2) {
                  return 'profile_name_too_short'.tr();
                }
                return null;
              },
              onSubmitted: (_) {
                // Enter 키 또는 완료 버튼 눌렀을 때 자동 저장
                if (_formKey.currentState?.validate() == true) {
                  _saveProfileName();
                  FocusScope.of(context).unfocus(); // 키보드 닫기
                }
              },
              onChanged: (value) {
                setState(() {}); // 재렌더링용
              },
              textInputAction: TextInputAction.done,
            ),

            SizedBox(height: common.Spacing.md),

            // 로그인 Provider 정보 표시
            _buildProviderInfoSection(theme),

            SizedBox(height: common.Spacing.lg),
            const ShadSeparator.horizontal(),
            SizedBox(height: common.Spacing.lg),

            // 계정 관리 섹션
            _buildAccountManagementSection(theme),
          ],
        ),
      ),
    );
  }

  /// 로그인 Provider 정보 섹션
  Widget _buildProviderInfoSection(ShadThemeData theme) {
    final currentUser = ref.read(currentUserProvider);
    final authRepo = ref.watch(authRepositoryProvider);

    String providerType = 'unknown';
    Color providerColor = theme.colorScheme.primary;

    // Provider 타입 판단 - 현재 User의 app_metadata를 확인
    final supabaseUser = Supabase.instance.client.auth.currentUser;
    final providers = supabaseUser?.appMetadata['providers'] as List?;

    if (providers != null && providers.isNotEmpty) {
      final provider = providers.first.toString();
      if (provider == 'google') {
        providerType = 'google';
        providerColor = BrandColors.googleBlue;
      } else if (provider == 'apple') {
        providerType = 'apple';
        providerColor = theme.colorScheme.onSurface;
      } else {
        providerType = 'email';
        providerColor = theme.colorScheme.primary;
      }
    } else if (authRepo.isEmailUser) {
      providerType = 'email';
      providerColor = theme.colorScheme.primary;
    }

    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.account_info'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: common.Spacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(common.Spacing.sm),
                decoration: BoxDecoration(
                  color: providerColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  providerType == 'email'
                      ? AppIcons.email
                      : providerType == 'google'
                      ? AppIcons
                            .email // 구글 아이콘 대체
                      : AppIcons.userCircle, // 애플 아이콘 대체
                  size: 24,
                  color: providerColor,
                ),
              ),
              SizedBox(width: common.Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser?.email ?? 'unknown_email'.tr(),
                      style: theme.textTheme.bodyLarge,
                    ),
                    SizedBox(height: common.Spacing.xs),
                    Text(
                      'settings.${providerType}_login'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 계정 관리 섹션
  Widget _buildAccountManagementSection(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings.account_management'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: common.Spacing.md),

        // 비밀번호 설정/변경
        _buildPasswordManagementTile(theme),

        SizedBox(height: common.Spacing.sm),

        // 로그아웃
        _buildLogoutTile(theme),
      ],
    );
  }

  /// 비밀번호 관리 타일
  Widget _buildPasswordManagementTile(ShadThemeData theme) {
    final authRepo = ref.watch(authRepositoryProvider);
    final isEmailUser = authRepo.isEmailUser;
    final isOAuthUser = authRepo.isOAuthUser;

    if (!isEmailUser && !isOAuthUser) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: Icon(AppIcons.password),
      title: Text(
        isEmailUser
            ? 'settings.change_password'.tr()
            : 'settings.set_password'.tr(),
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        isEmailUser
            ? 'settings.change_password_description'.tr()
            : 'settings.set_password_description'.tr(),
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Icon(AppIcons.chevronRight),
      onTap: () => context.push('/settings/profile/password'),
    );
  }

  /// 로그아웃 타일
  Widget _buildLogoutTile(ShadThemeData theme) {
    return ListTile(
      leading: Icon(AppIcons.logout),
      title: Text('auth.logout'.tr(), style: theme.textTheme.bodyLarge),
      subtitle: Text(
        'settings.logout_description'.tr(),
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Icon(AppIcons.chevronRight),
      onTap: () => _handleLogout(),
    );
  }

  /// 로그아웃 처리
  Future<void> _handleLogout() async {
    final shouldLogout = await showLogoutConfirmationBottomSheet(context);

    if (shouldLogout == true) {
      try {
        // AuthRepository를 통해 로그아웃
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('messages.logout_success'.tr())),
          );
          // 타임라인으로 이동 (로컬 퍼스트: 로그아웃 후에도 사용 가능)
          context.go('/');
        }
      } catch (e, stackTrace) {
        logger.e('Logout failed', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('messages.logout_failed'.tr()),
              backgroundColor: ShadTheme.of(context).colorScheme.destructive,
            ),
          );
        }
      }
    }
  }
}
