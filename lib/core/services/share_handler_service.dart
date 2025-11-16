import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_handler/share_handler.dart'
    show ShareHandlerPlatform, SharedMedia;

import '../providers/shared_media_provider.dart';
import '../utils/logger.dart';

/// 공유 수신 처리 서비스
///
/// 역할:
/// 1. 다른 앱에서 텍스트/이미지 공유 받기
/// 2. ShareInputPage로 이동하여 공유 데이터 처리
///
/// Lifecycle: @Riverpod(keepAlive: true) Provider로 관리
class ShareHandlerService {
  final Ref _ref;

  ShareHandlerService(this._ref);

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

    // 공유 데이터를 Provider에 설정
    _ref.read(sharedMediaProvider.notifier).setMedia(media);

    // ShareInputPage로 이동
    logger.i('[ShareHandler] Navigating to share input page');
    router.go('/share/input');
  }

  /// 서비스 정리
  void dispose() {
    logger.i('[ShareHandler] Disposing share handler service');
    // ShareHandlerPlatform.instance의 stream은 자동으로 정리됨
  }
}
