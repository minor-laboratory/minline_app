import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_handler/share_handler.dart'
    show ShareHandlerPlatform, SharedMedia;

import '../utils/logger.dart';

/// 공유 수신 처리 서비스
///
/// 역할:
/// 1. 다른 앱에서 텍스트/이미지 공유 받기
/// 2. Timeline 화면으로 이동하여 입력창에 pre-fill
class ShareHandlerService {
  static final ShareHandlerService _instance = ShareHandlerService._internal();
  factory ShareHandlerService() => _instance;
  ShareHandlerService._internal();

  /// 글로벌 Navigator Key (main.dart에서 설정)
  static GlobalKey<NavigatorState>? navigatorKey;

  /// 초기화
  Future<void> initialize() async {
    try {
      logger.i('[ShareHandler] Initializing...');

      final handler = ShareHandlerPlatform.instance;

      // 앱이 공유로 시작된 경우 처리
      final initialMedia = await handler.getInitialSharedMedia();
      if (initialMedia != null) {
        logger.i('[ShareHandler] Found initial shared media');
        // 화면 로드 후 처리
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleSharedMedia(initialMedia);
        });
      }

      // 앱 실행 중 공유 수신
      handler.sharedMediaStream.listen(
        (SharedMedia media) {
          logger.i('[ShareHandler] Received shared media from stream');
          _handleSharedMedia(media);
        },
        onError: (error) {
          logger.e('[ShareHandler] Stream error', error);
        },
      );

      logger.i('[ShareHandler] Initialized successfully');
    } catch (e, stackTrace) {
      logger.e('[ShareHandler] Failed to initialize', e, stackTrace);
    }
  }

  /// 공유된 미디어 처리
  void _handleSharedMedia(SharedMedia media) {
    try {
      logger.d('[ShareHandler] Processing media...');
      logger.d('[ShareHandler] Content: ${media.content}');
      logger.d('[ShareHandler] Attachments: ${media.attachments?.length ?? 0}');

      final context = navigatorKey?.currentContext;
      if (context == null || !context.mounted) {
        logger.w('[ShareHandler] Context not available, retrying...');
        Future.delayed(const Duration(milliseconds: 1000), () {
          final retryContext = navigatorKey?.currentContext;
          if (retryContext != null && retryContext.mounted) {
            _processSharedData(retryContext, media);
          }
        });
        return;
      }

      _processSharedData(context, media);
    } catch (e, stackTrace) {
      logger.e('[ShareHandler] Failed to handle media', e, stackTrace);
    }
  }

  /// 공유 데이터 처리
  void _processSharedData(BuildContext context, SharedMedia media) {
    final router = GoRouter.of(context);

    // 이미지가 있는 경우
    if (media.attachments?.isNotEmpty == true) {
      final imagePath = media.attachments!.first?.path;
      if (imagePath != null && imagePath.isNotEmpty) {
        logger.i('[ShareHandler] Navigating to timeline with image');
        router.go('/timeline', extra: {
          'imagePath': imagePath,
          'content': media.content ?? '',
        });
        return;
      }
    }

    // 텍스트만 있는 경우
    if (media.content != null && media.content!.isNotEmpty) {
      logger.i('[ShareHandler] Navigating to timeline with text');
      router.go('/timeline', extra: {
        'content': media.content,
      });
      return;
    }

    logger.w('[ShareHandler] No valid data in shared media');
  }
}
