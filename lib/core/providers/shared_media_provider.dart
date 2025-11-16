import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_handler/share_handler.dart' show SharedMedia;

part 'shared_media_provider.g.dart';

/// 공유 받은 미디어 데이터를 임시 저장하는 Provider
///
/// ShareHandlerService에서 설정하고, ShareInputPage에서 사용 후 초기화
@Riverpod(keepAlive: true)
class SharedMediaNotifier extends _$SharedMediaNotifier {
  @override
  SharedMedia? build() {
    return null;
  }

  /// 공유 받은 미디어 설정
  void setMedia(SharedMedia media) {
    state = media;
  }

  /// 미디어 초기화 (사용 완료 후)
  void clear() {
    state = null;
  }
}
