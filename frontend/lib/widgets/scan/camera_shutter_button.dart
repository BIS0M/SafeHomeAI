/// [Widget] 카메라 셔터 버튼
/// 커스텀 카메라 화면 하단에서 실제로 사진을 찍을 때 사용하는 둥근 버튼 부품입니다.
import 'package:flutter/material.dart';

class CameraShutterButton extends StatelessWidget {
  final bool isTaking;
  final VoidCallback onTap;

  const CameraShutterButton({
    super.key,
    required this.isTaking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: isTaking ? null : onTap,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
