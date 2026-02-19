import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// ✅ 온보딩 완료 후 회원가입(→로그인→아이 프로필 등록) 플로우로 진입
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {"title": "아이를 위한\n안전한 공간", "desc": "AI가 위험 요소를 찾아냅니다.", "icon": "shield"},
    {"title": "사진 촬영으로\n빠른 분석", "desc": "카메라로 찍으면 즉시 분석합니다.", "icon": "camera"},
    {"title": "맞춤형 해결 방법", "desc": "안전 솔루션을 제공합니다.", "icon": "warning"},
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  // ✅ 이미 로그인 상태면 다음 단계로, 아니면 로그인으로
                  final route = auth.isLoggedIn
                      ? '/child_registration'
                      : '/login';
                  Navigator.pushReplacementNamed(context, route);
                },
                child: const Text('건너뛰기', style: TextStyle(color: Colors.grey)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => _buildPage(index),
              ),
            ),
            _buildBottomSection(isLoggedIn: auth.isLoggedIn),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    final data = _onboardingData[index];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFFEBF2FF),
          child: Icon(
            _getIcon(data['icon']!),
            color: const Color(0xFF1A68FF),
            size: 40,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          data['title']!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          data['desc']!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBottomSection({required bool isLoggedIn}) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => _buildDot(index)),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage == 2) {
                  final route = isLoggedIn ? '/child_registration' : '/login';
                  Navigator.pushReplacementNamed(context, route);
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A68FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentPage == 2 ? '시작하기' : '다음',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      height: 6,
      width: _currentPage == index ? 20 : 6,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: _currentPage == index
            ? const Color(0xFF1A68FF)
            : Colors.grey.shade300,
      ),
    );
  }

  IconData _getIcon(String name) {
    if (name == 'shield') return Icons.shield_outlined;
    if (name == 'camera') return Icons.camera_alt_outlined;
    return Icons.warning_amber_rounded;
  }
}
