/// [Widget] 공간 선택 칩 아이템
/// 검사 설정 화면에서 아이방, 거실 등 분석할 장소를 선택할 때 사용하는 버튼 부품입니다.
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RoomChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const RoomChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppTheme.primary : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade900,
            ),
          ),
        ),
      ),
    );
  }
}
