import 'dart:ui';

import 'package:flutter/material.dart';

/// 키보드 애니메이션을 부드럽게 처리하는 위젯
///
/// MediaQuery.viewInsets.bottom을 모니터링하여 키보드 높이를 추적하고,
/// DartPerformanceMode.latency를 사용하여 부드러운 애니메이션 제공
class KeyboardAnimationBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, double keyboardHeight) builder;
  final bool interpolateLastPart;

  const KeyboardAnimationBuilder({
    super.key,
    required this.builder,
    this.interpolateLastPart = true,
  });

  @override
  State<KeyboardAnimationBuilder> createState() =>
      _KeyboardAnimationBuilderState();
}

class _KeyboardAnimationBuilderState extends State<KeyboardAnimationBuilder>
    with WidgetsBindingObserver {
  double _keyboardHeight = 0;
  double _previousKeyboardHeight = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final newHeight = View.of(context).viewInsets.bottom /
        View.of(context).devicePixelRatio;

    if (newHeight != _keyboardHeight) {
      setState(() {
        _previousKeyboardHeight = _keyboardHeight;
        _keyboardHeight = newHeight;

        // 키보드 애니메이션 시작/종료 감지
        if (newHeight > 0 && _previousKeyboardHeight == 0) {
          // 키보드 올라오기 시작
          _isAnimating = true;
          _setPerformanceMode(DartPerformanceMode.latency);
        } else if (newHeight == 0 && _previousKeyboardHeight > 0) {
          // 키보드 내려가기 시작
          _isAnimating = true;
          _setPerformanceMode(DartPerformanceMode.latency);
        }

        // 애니메이션 완료 대기 (300ms 후)
        if (_isAnimating) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _isAnimating = false;
                _setPerformanceMode(DartPerformanceMode.balanced);
              });
            }
          });
        }
      });
    }
  }

  void _setPerformanceMode(DartPerformanceMode mode) {
    try {
      final window = WidgetsBinding.instance.platformDispatcher;
      window.requestDartPerformanceMode(mode);
    } catch (e) {
      // 지원하지 않는 플랫폼이면 무시
    }
  }

  double get _smoothedKeyboardHeight {
    if (!widget.interpolateLastPart) {
      return _keyboardHeight;
    }

    // 서브픽셀 jank 방지: 0.5px 단위로 반올림
    return (_keyboardHeight * 2).roundToDouble() / 2;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: widget.builder(context, _smoothedKeyboardHeight),
    );
  }
}
