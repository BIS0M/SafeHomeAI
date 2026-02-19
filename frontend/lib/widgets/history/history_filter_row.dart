import 'package:flutter/material.dart';
import '../../theme/app_theme.dart'; // ✅ 테마 파일 import 복구

class HistoryFilterRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const HistoryFilterRow({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      child: Row(
        children: [
          _buildFilterBtn('전체', 0),
          const SizedBox(width: 8),
          _buildFilterBtn('공간별', 1),
          const SizedBox(width: 8),
          _buildFilterBtn('아이별', 2), // ✅ [추가] 아이별 버튼
          const SizedBox(width: 8),
          _buildFilterBtn('날짜별', 3), // ✅ [변경] 날짜별 인덱스 3으로 이동
        ],
      ),
    );
  }

  Widget _buildFilterBtn(String text, int index) {
    final bool isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // ✅ [수정] AppTheme.primary 사용
            color: isSelected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? null : Border.all(color: Colors.grey.shade200),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘 (선택 사항 - 공간이 좁으면 텍스트만 보여줘도 됨)
              if (isSelected) ...[
                Icon(
                  _getIconForIndex(index),
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: TextStyle(
                  // ✅ [수정] 텍스트 색상도 테마에 맞게
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12, // 버튼이 4개라 글씨 크기 살짝 조정
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return Icons.grid_view_rounded;
      case 1: return Icons.home_filled;
      case 2: return Icons.face; // 아이별 아이콘
      case 3: return Icons.calendar_today_rounded;
      default: return Icons.circle;
    }
  }
}