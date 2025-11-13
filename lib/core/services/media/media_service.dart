import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/logger.dart';

/// 미디어 업로드 서비스
///
/// Storage: users 버킷 (북랩과 공유)
/// 경로: fragments/{user_id}/{fragment_id}/{filename}
class MediaService {
  static const int maxFilesPerFragment = 3;
  static const int maxFileSizeMB = 10;

  final SupabaseClient _supabase;

  MediaService(this._supabase);

  /// 파일 크기 검증
  void _validateFileSize(File file) {
    final sizeMB = file.lengthSync() / (1024 * 1024);
    if (sizeMB > maxFileSizeMB) {
      throw MediaException(
        'file_size_exceeded',
        details: {
          'sizeMB': sizeMB.toStringAsFixed(1),
          'maxMB': maxFileSizeMB.toString(),
        },
      );
    }
  }

  /// 이미지 파일 타입 검증 (확장자 기반)
  void _validateImageType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

    if (!allowedExtensions.contains(extension)) {
      throw MediaException(
        'unsupported_file_type',
        details: {'type': extension},
      );
    }
  }

  /// 이미지 업로드 (단일 파일)
  ///
  /// Returns: 업로드된 파일의 public URL
  Future<String> uploadImage(
    File file,
    String userId,
    String fragmentId,
  ) async {
    // 유효성 검증
    _validateImageType(file);
    _validateFileSize(file);

    // 파일명 생성 (timestamp + 원본 파일명)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final originalName = file.path.split('/').last;
    final sanitizedName = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9.-]'), '_');
    final fileName = '${timestamp}_$sanitizedName';

    // Storage 경로: fragments/{user_id}/{fragment_id}/{filename}
    final filePath = 'fragments/$userId/$fragmentId/$fileName';

    try {
      // Supabase Storage 업로드
      await _supabase.storage.from('users').upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Public URL 생성
      final publicUrl = _supabase.storage.from('users').getPublicUrl(filePath);

      return publicUrl;
    } catch (e, stack) {
      logger.e('Storage upload failed', e, stack);
      throw MediaException(
        'upload_failed',
        details: {'message': e.toString()},
      );
    }
  }

  /// 여러 이미지 업로드
  ///
  /// Returns: 업로드된 파일들의 public URL 배열
  Future<List<String>> uploadImages(
    List<File> files,
    String userId,
    String fragmentId,
  ) async {
    // 개수 제한 검증
    if (files.length > maxFilesPerFragment) {
      throw MediaException(
        'max_files_exceeded',
        details: {'count': maxFilesPerFragment.toString()},
      );
    }

    // 순차 업로드
    final uploadedUrls = <String>[];
    try {
      for (final file in files) {
        final url = await uploadImage(file, userId, fragmentId);
        uploadedUrls.add(url);
      }
      return uploadedUrls;
    } catch (e) {
      // 이미 업로드된 파일들 삭제 (롤백)
      if (uploadedUrls.isNotEmpty) {
        logger.w('Rolling back: deleting ${uploadedUrls.length} uploaded file(s)');
        await deleteImages(uploadedUrls, userId, fragmentId);
      }
      rethrow;
    }
  }

  /// 이미지 삭제 (단일)
  Future<void> deleteImage(
    String publicUrl,
    String userId,
    String fragmentId,
  ) async {
    // Public URL에서 파일 경로 추출
    // 예: https://xxx.supabase.co/storage/v1/object/public/users/fragments/user123/frag456/123_image.jpg
    // → fragments/user123/frag456/123_image.jpg
    final pathMatch = RegExp(r'/users/(.+)$').firstMatch(publicUrl);
    if (pathMatch == null) {
      logger.e('Invalid URL format: $publicUrl');
      return;
    }

    final filePath = pathMatch.group(1)!;

    try {
      await _supabase.storage.from('users').remove([filePath]);
    } catch (e, stack) {
      logger.e('Storage deletion failed', e, stack);
      throw MediaException(
        'delete_failed',
        details: {'message': e.toString()},
      );
    }
  }

  /// 여러 이미지 삭제
  Future<void> deleteImages(
    List<String> publicUrls,
    String userId,
    String fragmentId,
  ) async {
    for (final url in publicUrls) {
      try {
        await deleteImage(url, userId, fragmentId);
      } catch (e, stack) {
        logger.e('Image deletion failed (continuing)', e, stack);
      }
    }
  }
}

/// 미디어 관련 예외
class MediaException implements Exception {
  final String code;
  final Map<String, String>? details;

  MediaException(this.code, {this.details});

  @override
  String toString() => 'MediaException: $code ${details ?? ""}';
}
