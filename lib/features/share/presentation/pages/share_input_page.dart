import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minorlab_common/minorlab_common.dart' as common;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:share_handler/share_handler.dart' show SharedMedia;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/providers/shared_media_provider.dart';
import '../../../../core/services/media/media_service.dart';
import '../../../../core/services/share_activity_service.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/fragment.dart';
import '../../../auth/widgets/login_required_bottom_sheet.dart';

/// 공유 데이터 입력 페이지
///
/// 다른 앱에서 공유받은 텍스트/이미지를 Fragment로 저장
class ShareInputPage extends ConsumerStatefulWidget {
  /// ShareActivity에서 직접 전달받은 데이터 (Method Channel)
  final Map<String, dynamic>? directData;

  /// ShareActivity에서 시작되었는지 여부
  final bool isFromShareActivity;

  const ShareInputPage({
    super.key,
    this.directData,
    this.isFromShareActivity = false,
  });

  @override
  ConsumerState<ShareInputPage> createState() => _ShareInputPageState();
}

class _ShareInputPageState extends ConsumerState<ShareInputPage> {
  final _contentController = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  static const int _maxLength = 300;
  static const int _maxImages = 3;

  @override
  void initState() {
    super.initState();

    // Provider 초기 데이터 및 변경 감지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ShareActivity에서 직접 전달받은 데이터 처리
      if (widget.directData != null) {
        _loadDirectData(widget.directData!);
      } else {
        // SharedMediaProvider에서 데이터 로드 (기존 방식)
        final initialMedia = ref.read(sharedMediaProvider);
        if (initialMedia != null) {
          _loadProviderData(initialMedia);
        }
      }

      // ShareActivity에서 실행되면 항상 포커스 요청
      if (widget.isFromShareActivity || _contentController.text.isEmpty) {
        _focusNode.requestFocus();
      }
    });
  }

  /// ShareActivity에서 전달받은 데이터 로드
  void _loadDirectData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final content = data['content'] as String?;

    // 텍스트 처리
    if (type == 'text' && content != null && content.isNotEmpty) {
      _contentController.text = content;
      if (mounted) setState(() {});
    }

    // 이미지 처리
    if ((type == 'image' || type == 'images') && data['imagePaths'] != null) {
      final imagePaths = (data['imagePaths'] as List).cast<String?>();
      logger.i('[ShareInputPage] Received ${imagePaths.length} image(s) from ShareActivity');

      // ShareActivity.kt에서 content:// URI를 임시 파일로 복사한 경로를 받음
      for (final path in imagePaths) {
        if (path != null && path.isNotEmpty) {
          final file = File(path);
          if (file.existsSync()) {
            _selectedImages.add(file);
            logger.d('[ShareInputPage] Added image: $path');
          } else {
            logger.w('[ShareInputPage] Image file not found: $path');
          }
        }
      }

      // UI 업데이트
      if (mounted) setState(() {});
    }
  }

  /// SharedMediaProvider에서 데이터 로드
  void _loadProviderData(SharedMedia? media) {
    if (media == null) return;

    // 텍스트 로드
    if (media.content != null && media.content!.isNotEmpty) {
      _contentController.text = media.content!;
    }

    // 공유받은 이미지를 _selectedImages에 추가
    if (media.attachments?.isNotEmpty == true) {
      final sharedImageFiles = media.attachments!
          .where((attachment) => attachment?.path != null)
          .map((attachment) => File(attachment!.path))
          .toList();
      _selectedImages.addAll(sharedImageFiles);
    }

    // UI 업데이트
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 이미지가 있는지 확인
  bool get _hasImages => _selectedImages.isNotEmpty;

  /// 유효성 검증 (텍스트 또는 이미지 필수)
  bool get _isValid {
    final hasText = _contentController.text.trim().isNotEmpty;
    return hasText || _hasImages;
  }

  /// 갤러리에서 이미지 선택
  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      _showError(
        'media.max_files_exceeded'.tr(
          namedArgs: {'count': _maxImages.toString()},
        ),
      );
      return;
    }

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      final availableSlots = _maxImages - _selectedImages.length;
      final imagesToSelect = images.take(availableSlots).toList();

      if (images.length > availableSlots) {
        _showError(
          'media.max_files_exceeded'.tr(
            namedArgs: {'count': _maxImages.toString()},
          ),
        );
      }

      // 선택된 이미지들의 크기 검증
      final validImages = <File>[];
      final oversizedFiles = <String>[];

      for (final xfile in imagesToSelect) {
        final file = File(xfile.path);
        final sizeMB = file.lengthSync() / (1024 * 1024);

        if (sizeMB > MediaService.maxFileSizeMB) {
          oversizedFiles.add('${xfile.name} (${sizeMB.toStringAsFixed(1)}MB)');
        } else {
          validImages.add(file);
        }
      }

      // 크기 초과 파일이 있으면 경고
      if (oversizedFiles.isNotEmpty) {
        _showError(
          'media.file_size_exceeded'.tr(
            namedArgs: {
              'files': oversizedFiles.join(', '),
              'maxMB': MediaService.maxFileSizeMB.toString(),
            },
          ),
        );
      }

      // 유효한 이미지만 추가
      if (validImages.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(validImages);
        });
      }
    } catch (e, stack) {
      logger.e('Failed to pick images', e, stack);
      _showError('media.select_failed'.tr());
    }
  }

  /// 이미지 삭제
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Fragment 저장
  Future<void> _save() async {
    if (!_isValid) {
      _showError('snap.content_or_media_required'.tr());
      return;
    }

    // 로그인 체크
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser == null) {
      // 로그인 유도 bottom sheet 표시
      await showLoginRequiredBottomSheet(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fragment ID 생성 (이미지 업로드 경로용)
      final fragmentId = const Uuid().v4();

      // 이미지 업로드
      List<String> mediaUrls = [];
      if (_selectedImages.isNotEmpty) {
        final mediaService = MediaService(supabase);
        try {
          mediaUrls = await mediaService.uploadImages(
            _selectedImages,
            currentUser.id,
            fragmentId,
          );
        } on MediaException catch (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);

          // MediaException code를 다국어 키로 매핑
          String errorKey = 'media.${e.code}';
          if (e.details != null) {
            _showError(errorKey.tr(namedArgs: e.details!));
          } else {
            _showError(errorKey.tr());
          }
          return;
        }
      }

      final fragment = Fragment.fromNew(
        userId: currentUser.id,
        content: _contentController.text.trim(),
        mediaUrls: mediaUrls,
        synced: false,
      )..remoteID = fragmentId; // remoteID 설정

      final isar = DatabaseService.instance.isar;
      await isar.writeTxn(() async {
        await isar.fragments.put(fragment);
      });

      // 공유 데이터 초기화
      ref.read(sharedMediaProvider.notifier).clear();

      // 성공 메시지
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('common.saved'.tr()),
          backgroundColor: ShadTheme.of(context).colorScheme.primary,
        ),
      );

      // 이전 화면으로 이동 또는 ShareActivity 종료
      if (mounted) {
        if (widget.isFromShareActivity) {
          // ShareActivity 종료
          await ShareActivityService.closeShareActivity();
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (e, stack) {
      logger.e('Failed to save shared fragment', e, stack);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('snap.save_failed'.tr());
    }
  }

  /// 에러 메시지 표시 (SnackBar)
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ShadTheme.of(context).colorScheme.destructive,
      ),
    );
  }

  /// Bottom Sheet 스타일 콘텐츠 (ShareActivity용)
  Widget _buildBottomSheetContent(ShadThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.background.withValues(alpha: 0.5), // 반투명 배경
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: common.Spacing.sm, bottom: common.Spacing.xs),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted,
                  borderRadius: BorderRadius.circular(common.BorderRadii.xs),
                ),
              ),

              // 헤더
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: common.Spacing.md,
                  vertical: common.Spacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'share.title'.tr(),
                        style: theme.textTheme.large.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(AppIcons.close),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              ref.read(sharedMediaProvider.notifier).clear();
                              await ShareActivityService.closeShareActivity();
                            },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 콘텐츠
              Padding(
                padding: const EdgeInsets.all(common.Spacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      // 이미지 프리뷰
                      if (_hasImages) ...[
                        _buildImagePreview(theme, ref.watch(sharedMediaProvider)),
                        SizedBox(height: common.Spacing.sm + common.Spacing.xs),
                      ],

                      // 텍스트 입력
                      ShadInput(
                        controller: _contentController,
                        focusNode: _focusNode,
                        enabled: !_isLoading,
                        placeholder: Text('snap.input_placeholder'.tr()),
                        minLines: 3,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        onChanged: (value) {
                          if (value.length > _maxLength) {
                            _contentController.text =
                                value.substring(0, _maxLength);
                            _contentController.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: _maxLength),
                            );
                          }
                          setState(() {});
                        },
                      ),

                      SizedBox(height: common.Spacing.sm + common.Spacing.xs),

                      // 액션 영역
                      Row(
                        children: [
                          _buildImageButton(theme),
                          SizedBox(width: common.Spacing.sm),
                          _buildCharCounter(theme),
                          const Spacer(),
                          ShadButton(
                            enabled: _isValid && !_isLoading,
                            onPressed: _save,
                            child: _isLoading
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: common.Spacing.md,
                                        height: common.Spacing.md,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme
                                              .colorScheme.primaryForeground,
                                        ),
                                      ),
                                      SizedBox(width: common.Spacing.sm),
                                      Text('common.saving'.tr()),
                                    ],
                                  )
                                : Text('common.save'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final sharedMedia = ref.watch(sharedMediaProvider);

    // Provider 변경 감지 - 새로운 공유 데이터가 들어오면 텍스트 업데이트
    ref.listen(sharedMediaProvider, (previous, next) {
      if (next != null && next != previous) {
        if (next.content != null && next.content!.isNotEmpty) {
          _contentController.text = next.content!;
          setState(() {});
        }
      }
    });

    // ShareActivity에서 실행될 때는 Bottom Sheet 스타일
    if (widget.isFromShareActivity) {
      return _buildBottomSheetContent(theme);
    }

    // 일반 실행 시 Scaffold
    return Scaffold(
      appBar: AppBar(
        title: Text('share.title'.tr()),
        leading: IconButton(
          icon: Icon(AppIcons.close),
          onPressed: _isLoading ? null : () async {
            logger.d('[ShareInputPage] Close button pressed');

            // 공유 데이터 초기화 (Provider 사용 시)
            if (!widget.isFromShareActivity) {
              ref.read(sharedMediaProvider.notifier).clear();
            }

            // ShareActivity 종료 또는 이전 화면으로
            if (widget.isFromShareActivity) {
              await ShareActivityService.closeShareActivity();
            } else if (context.canPop()) {
              logger.d('[ShareInputPage] Popping to previous screen');
              context.pop();
            } else {
              logger.d('[ShareInputPage] No previous screen, going to home');
              context.go('/');
            }
          },
        ),
        actions: [
          ShadButton(
            enabled: _isValid && !_isLoading,
            onPressed: _save,
            child: _isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: common.Spacing.md,
                        height: common.Spacing.md,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primaryForeground,
                        ),
                      ),
                      SizedBox(width: common.Spacing.sm),
                      Text('common.saving'.tr()),
                    ],
                  )
                : Text('common.save'.tr()),
          ),
          const SizedBox(width: common.Spacing.sm),
        ],
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(common.Spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 이미지 프리뷰 (공유 받은 이미지 + 사용자 선택 이미지)
              if (_hasImages) ...[
                _buildImagePreview(theme, sharedMedia),
                SizedBox(height: common.Spacing.sm + common.Spacing.xs),
              ],

              // 텍스트 입력
              ShadInput(
                controller: _contentController,
                focusNode: _focusNode,
                enabled: !_isLoading,
                placeholder: Text('snap.input_placeholder'.tr()),
                minLines: 3,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                onChanged: (value) {
                  // 300자 제한
                  if (value.length > _maxLength) {
                    _contentController.text = value.substring(0, _maxLength);
                    _contentController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _maxLength),
                    );
                  }
                  setState(() {});
                },
              ),

              SizedBox(height: common.Spacing.sm + common.Spacing.xs),

              // 액션 영역
              Row(
                children: [
                  // 이미지 추가 버튼
                  _buildImageButton(theme),
                  SizedBox(width: common.Spacing.sm),

                  // 글자수 카운터
                  _buildCharCounter(theme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이미지 프리뷰 위젯
  Widget _buildImagePreview(ShadThemeData theme, sharedMedia) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: common.Spacing.sm),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(common.BorderRadii.md),
                  child: Image.file(
                    _selectedImages[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                // 삭제 버튼
                Positioned(
                  top: -common.Spacing.sm,
                  right: -common.Spacing.sm,
                  child: ShadButton.ghost(
                    width: 24,
                    height: 24,
                    padding: EdgeInsets.zero,
                    onPressed: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(common.Spacing.xs),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.destructive,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.close,
                        size: common.Spacing.sm + common.Spacing.xs,
                        color: theme.colorScheme.destructiveForeground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 이미지 추가 버튼
  Widget _buildImageButton(ShadThemeData theme) {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImages,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: common.Spacing.sm),
        decoration: BoxDecoration(
          color: _isLoading
              ? theme.colorScheme.muted
              : theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(common.BorderRadii.xl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.imagePlus,
              size: 16,
              color: _isLoading
                  ? theme.colorScheme.mutedForeground
                  : theme.colorScheme.secondaryForeground,
            ),
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(width: common.Spacing.sm - 2),
              Text(
                '${_selectedImages.length}/$_maxImages',
                style: TextStyle(
                  fontSize: common.Spacing.sm + common.Spacing.xs,
                  color: _isLoading
                      ? theme.colorScheme.mutedForeground
                      : theme.colorScheme.secondaryForeground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 글자수 카운터
  Widget _buildCharCounter(ShadThemeData theme) {
    final charCount = _contentController.text.length;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: common.Spacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(common.BorderRadii.xl),
        ),
        child: Center(
          child: Text(
            '$charCount / $_maxLength',
            style: TextStyle(
              fontSize: common.Spacing.md - 2,
              color: theme.colorScheme.mutedForeground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
