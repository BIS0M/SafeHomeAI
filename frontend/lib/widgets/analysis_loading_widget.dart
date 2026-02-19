import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnalysisLoadingWidget extends StatefulWidget {
  const AnalysisLoadingWidget({super.key});

  @override
  State<AnalysisLoadingWidget> createState() => _AnalysisLoadingWidgetState();
}

class _AnalysisLoadingWidgetState extends State<AnalysisLoadingWidget>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  double _progress = 0.0; // 0.0 ~ 100.0
  Timer? _progressTimer;

  late AnimationController _rotationController;

  // NOTE: duration 값은 외부 로직이 아닌 UI 단계 비율 계산용으로만 사용합니다.
  // 요청사항:
  // - 사진 업로드/안전 점검 완료: 짧게
  // - AI 분석 준비/위험 요소 검사: 시간을 반반
  // => 10% / 40% / 40% / 10% 비율로 단계 진행 표시
  final List<Map<String, dynamic>> _analysisSteps = [
    {'id': 1, 'label': '사진 업로드 중...', 'duration': 10},
    {'id': 2, 'label': 'AI 분석 중...', 'duration': 40},
    {'id': 3, 'label': '위험 요소 검사 중...', 'duration': 40},
    {'id': 4, 'label': '안전 점검 완료 중...', 'duration': 10},
  ];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();

    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      setState(() {
        if (_progress < 95.0) {
          _progress = (_progress + 0.55).clamp(0.0, 95.0);
        }
        _currentStep = _stepIndexForProgress(_progress);
      });
    });
  }

  int _stepIndexForProgress(double progress) {
    final int total = _analysisSteps.fold<int>(
      0,
      (sum, step) => sum + ((step['duration'] as int?) ?? 0),
    );

    if (total <= 0) {
      final double segment = 100.0 / _analysisSteps.length;
      final int stepByProgress = (progress / segment).floor();
      return stepByProgress.clamp(0, _analysisSteps.length - 1);
    }

    final double t = (progress.clamp(0.0, 100.0) / 100.0) * total;

    int acc = 0;
    for (int i = 0; i < _analysisSteps.length; i++) {
      acc += (_analysisSteps[i]['duration'] as int?) ?? 0;
      if (t < acc) return i;
    }
    return _analysisSteps.length - 1;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double p = (_progress / 100.0).clamp(0.0, 1.0);
    final int percent = _progress.round();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildAnimatedIcon(),
                    const SizedBox(height: 28),
                    _buildProgressBar(p, percent),
                    const SizedBox(height: 24),
                    _buildCurrentStepInfo(),
                    const SizedBox(height: 32),
                    _buildStepsList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '분석 중',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI가 안전 위험 요소를 검사하고 있습니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade100.withOpacity(0.35),
            ),
          ),
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(132, 132),
                  painter: _ArcPainter(
                    color: Colors.blue.shade300.withOpacity(0.75),
                    strokeWidth: 10,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.home_rounded,
                size: 44,
                color: Color(0xFF1A68FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double p, int percent) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFF1A68FF),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '${(_currentStep + 1).clamp(1, _analysisSteps.length)}/${_analysisSteps.length} 단계',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentStepInfo() {
    return const SizedBox.shrink();
  }

  Widget _buildStepsList() {
    final int len = _analysisSteps.length;
    final int current = _currentStep.clamp(0, len - 1);

    final List<int> visible = [
      current,
      for (int i = current + 1; i < len; i++) i,
    ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ✅ 현재 단계: "아래에서 자연스럽게 올라오고", 이전은 "위로 빠지며" 사라짐
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 520),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final isExiting = animation.status == AnimationStatus.reverse;

              final offset = (isExiting
                      ? Tween<Offset>(
                          begin: Offset.zero,
                          end: const Offset(0, -0.10),
                        )
                      : Tween<Offset>(
                          begin: const Offset(0, 0.18),
                          end: Offset.zero,
                        ))
                  .animate(CurvedAnimation(
                    parent: animation,
                    curve: isExiting ? Curves.easeInCubic : Curves.easeOutCubic,
                  ));

              final opacity = CurvedAnimation(
                parent: animation,
                curve: isExiting ? Curves.easeIn : Curves.easeOut,
              );

              // ✅ 클리핑으로 튕김/흔들림 느낌 줄이기
              return ClipRect(
                child: FadeTransition(
                  opacity: opacity,
                  child: SlideTransition(position: offset, child: child),
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey('current_$current'),
              child: _buildStepItem(current),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ 대기 단계: 완료 단계가 사라지며 AnimatedSize로 자연스럽게 위로 당겨짐
          for (int i = 1; i < visible.length; i++)
            KeyedSubtree(
              key: ValueKey('pending_${visible[i]}'),
              child: _buildStepItem(visible[i]),
            ),
        ],
      ),
    );
  }

  // ✅ [수정] removeMargin 파라미터 추가 (기본 false)
  Widget _buildStepItem(int index, {bool removeMargin = false}) {
    final bool isCompleted = index < _currentStep;
    final bool isCurrent = index == _currentStep;

    Color bgColor;
    Color borderColor = Colors.transparent;

    if (isCurrent) {
      bgColor = Colors.blue.shade100;
      borderColor = Colors.blue.shade300;
    } else if (isCompleted) {
      bgColor = Colors.green.shade50;
    } else {
      bgColor = Colors.grey.shade50;
    }

    return Container(
      // ✅ [수정] 스택에서는 margin 제거
      margin: EdgeInsets.only(bottom: removeMargin ? 0 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 2 : 0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green.shade500
                  : isCurrent
                      ? const Color(0xFF1A68FF)
                      : Colors.grey.shade300,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : isCurrent
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _analysisSteps[index]['label'] as String,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCompleted
                    ? Colors.green.shade700
                    : isCurrent
                        ? Colors.blue.shade900
                        : Colors.grey.shade500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ArcPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 / 3,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
