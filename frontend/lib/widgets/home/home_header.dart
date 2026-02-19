/// [Widget] 홈 화면 상단 헤더 (Commercial Modern Style)
/// 기존의 파란색 배경을 제거하고, 깔끔한 흰색 배경과 모던한 타이포그래피를 적용했습니다.
import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onProfileTap;

  const HomeHeader({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      // [수정 1] 배경색 변경: 파란색 -> 흰색
      color: Colors.white,

      // 상단 상태바 높이(SafeArea) + 여백 적용
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 24, // 여백을 조금 더 넓혀서 시원하게
        right: 24,
        bottom: 12, // 하단 여백을 살짝 줄여서 본문과 가깝게
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 타이틀 영역
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SafeHome AI',
                style: TextStyle(
                  // [수정 2] 텍스트 색상 변경: 흰색 -> 진한 검정 (다크 그레이)
                  color: Color(0xFF1F2937),
                  fontSize: 22, // 크기는 유지하되
                  fontWeight: FontWeight.w800, // 두께감 유지
                  letterSpacing: -0.5, // 자간을 좁혀서 더 단단한 느낌
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '우리 집 안전 지킴이',
                style: TextStyle(
                  // [수정 3] 서브 텍스트 변경: 흰색70 -> 연한 회색
                  color: Colors.grey[500],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // 프로필 아이콘 버튼
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(30), // 터치 시 물결 효과 둥글게
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                // [수정 4] 아이콘 배경: 투명 흰색 -> 아주 연한 회색
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded, // 둥근 아이콘 사용
                // [수정 5] 아이콘 색상: 흰색 -> 진한 회색
                color: Color(0xFF4B5563),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
