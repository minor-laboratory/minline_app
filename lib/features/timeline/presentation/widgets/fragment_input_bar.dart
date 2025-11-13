import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_service.dart';
import '../../../../core/services/media/media_service.dart';
import '../../../../core/utils/app_icons.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/fragment.dart';
import '../../../auth/widgets/login_required_bottom_sheet.dart';

/// Fragment 입력바 위젯
///
/// Timeline 화면 하단 고정 입력바 (채팅 앱 스타일)
class FragmentInputBar extends ConsumerStatefulWidget {
  const FragmentInputBar({super.key});

  @override
  ConsumerState<FragmentInputBar> createState() => _FragmentInputBarState();
}

class _FragmentInputBarState extends ConsumerState<FragmentInputBar> {
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  static const int _maxLength = 300;
  static const int _maxImages = 3;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 유효성 검증 (텍스트 또는 이미지 필수)
  bool get _isValid =>
      _contentController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;

  /// 갤러리에서 이미지 선택
  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      _showError('media.max_files_limit'.tr(args: [_maxImages.toString()]));
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
        _showError('media.max_files_limit'.tr(args: [_maxImages.toString()]));
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

      // 이미지 업로드 (있을 경우)
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

      // 입력 초기화
      if (!mounted) return;
      setState(() {
        _contentController.clear();
        _selectedImages.clear();
        _isLoading = false;
      });

      // 키보드 내리기
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e, stack) {
      logger.e('Failed to save fragment', e, stack);
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
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이미지 프리뷰
          if (_selectedImages.isNotEmpty) ...[
            _buildImagePreview(colorScheme),
            const SizedBox(height: 12),
          ],

          // 텍스트 입력
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 80,
              maxHeight: 200,
            ),
            child: ShadTextarea(
              controller: _contentController,
              enabled: !_isLoading,
              placeholder: Text('snap.input_placeholder'.tr()),
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
          ),

          const SizedBox(height: 12),

          // 액션 영역
          Row(
            children: [
              // 이미지 추가 버튼
              _buildImageButton(colorScheme),
              const SizedBox(width: 8),

              // 글자수 표시
              _buildCharCounter(colorScheme),

              const Spacer(),

              // 저장 버튼
              _buildSaveButton(colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  /// 이미지 프리뷰 위젯
  Widget _buildImagePreview(ColorScheme colorScheme) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                // 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImages[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                // 삭제 버튼
                Positioned(
                  top: -8,
                  right: -8,
                  child: ShadButton.ghost(
                    width: 24,
                    height: 24,
                    padding: EdgeInsets.zero,
                    onPressed: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.close,
                        size: 12,
                        color: colorScheme.onError,
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
  Widget _buildImageButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImages,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _isLoading
              ? colorScheme.surfaceContainerHighest
              : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.imagePlus,
              size: 16,
              color: _isLoading
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSecondaryContainer,
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '${ _selectedImages.length}/$_maxImages',
                style: TextStyle(
                  fontSize: 12,
                  color: _isLoading
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 글자수 카운터
  Widget _buildCharCounter(ColorScheme colorScheme) {
    final charCount = _contentController.text.length;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          '$charCount / $_maxLength',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  /// 저장 버튼
  Widget _buildSaveButton(ColorScheme colorScheme) {
    return ShadButton(
      onPressed: _isValid && !_isLoading ? _save : null,
      child: _isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text('common.saving'.tr()),
              ],
            )
          : Text('common.save'.tr()),
    );
  }
}
