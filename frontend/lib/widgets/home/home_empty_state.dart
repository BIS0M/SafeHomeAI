/// [Widget] 홈 화면 빈 상태 안내 (Compact Ver.)
/// 작은 화면에서도 스크롤 없이 버튼이 보이도록 크기와 간격을 최적화했습니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_provider.dart';
import '../../screens/scan/child_selection_screen.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 디자인 시스템 컬러 정의
    const Color kBackgroundColor = Color(0xFFF9FAFB);
    const Color kBrandColor = Color(0xFF2563EB);
    const Color kTextTitleColor = Color(0xFF111827);
    const Color kTextBodyColor = Color(0xFF6B7280);

    // 화면 높이에 따라 유동적으로 여백 조절 (작은 폰 대응)
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenHeight < 700;

    return Container(
      color: kBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: isSmallScreen ? 10 : 20),

              // -------------------------------------------------------
              // [1] 메인 비주얼: 사이즈 축소 (140 -> 110)
              // -------------------------------------------------------
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110, // [수정] 크기 줄임
                    height: 110, // [수정] 크기 줄임
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: kBrandColor.withOpacity(0.1),
                          blurRadius: 30, // [수정] 블러 반경 조정
                          spreadRadius: 5,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.security_rounded,
                    size: 56, // [수정] 아이콘 크기 줄임 (72 -> 56)
                    color: kBrandColor,
                  ),
                  Positioned(
                    right: 24, // [수정] 위치 조정
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12, // [수정] 체크 아이콘 미세 조정
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 24 : 32), // [수정] 간격 축소
              // -------------------------------------------------------
              // [2] 텍스트 영역
              // -------------------------------------------------------
              const Text(
                "우리 집 안전 점검",
                style: TextStyle(
                  fontSize: 22, // [수정] 폰트 사이즈 미세 조정 (24 -> 22)
                  fontWeight: FontWeight.w800,
                  color: kTextTitleColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8), // [수정] 간격 축소
              Text(
                "사진 한 장으로 위험 요소를 찾고\n우리 가족을 위한 안전 가이드를 받아보세요.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, // [수정] 폰트 사이즈 미세 조정
                  color: kTextBodyColor,
                  height: 1.5,
                  letterSpacing: -0.2,
                ),
              ),

              SizedBox(height: isSmallScreen ? 24 : 32), // [수정] 간격 축소
              // -------------------------------------------------------
              // [3] 프로세스 카드: 패딩 축소
              // -------------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20, // [수정] 상하 패딩 축소 (28 -> 20)
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20), // [수정] 라운드 미세 조정
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9CA3AF).withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStepItem(
                      Icons.camera_alt_rounded,
                      "촬영",
                      kBrandColor,
                    ),
                    _buildArrow(),
                    _buildStepItem(
                      Icons.manage_search_rounded,
                      "분석",
                      kBrandColor,
                    ),
                    _buildArrow(),
                    _buildStepItem(
                      Icons.verified_user_rounded,
                      "해결",
                      kBrandColor,
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 32 : 40), // [수정] 간격 축소
              // -------------------------------------------------------
              // [4] CTA 버튼
              // -------------------------------------------------------
              Container(
                width: double.infinity,
                height: 54, // [수정] 버튼 높이 축소 (58 -> 54)
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kBrandColor.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChildSelectionScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "안전 진단 시작하기",
                    style: TextStyle(
                      fontSize: 16, // [수정] 폰트 미세 조정
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 [Helper] 단계별 아이템 위젯
  Widget _buildStepItem(IconData icon, String title, Color brandColor) {
    return Column(
      children: [
        Container(
          width: 48, // [수정] 아이콘 원형 크기 축소 (56 -> 48)
          height: 48,
          decoration: BoxDecoration(
            color: brandColor.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: brandColor, size: 22), // [수정] 아이콘 크기 축소
        ),
        const SizedBox(height: 8), // [수정] 간격 축소
        Text(
          title,
          style: const TextStyle(
            fontSize: 12, // [수정] 폰트 축소
            fontWeight: FontWeight.bold,
            color: Color(0xFF4B5563),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // 🔹 [Helper] 화살표 위젯
  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20), // [수정] 높이 맞춤
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 16,
        color: Colors.grey.shade300,
      ),
    );
  }
}
