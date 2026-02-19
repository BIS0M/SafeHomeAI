import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/ui_provider.dart';
import 'signup_screen.dart';

/// ✅ 로그인(백엔드 연동)
/// - 이메일/비밀번호로 백엔드 로그인 후 JWT 저장
class LoginScreen extends StatefulWidget {
  final String? initialEmail;

  const LoginScreen({super.key, this.initialEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEmail;
    if (initial != null && initial.trim().isNotEmpty) {
      _emailController.text = initial.trim().toLowerCase();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final e = email.trim();
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(e);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final email = _emailController.text;
    final password = _passwordController.text;

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일 형식을 확인해주세요.')));
      return;
    }

    if (password.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호를 입력해주세요.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // ✅ 백엔드 로그인 성공 시 토큰이 저장되며 로그인 상태가 됩니다.
      final ok = await context.read<AuthProvider>().login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 또는 비밀번호가 올바르지 않습니다.')),
        );
        return;
      }

      context.read<UiProvider>().setTabIndex(0);
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 높이를 가져와서 작은 화면인지 체크 (높이 700 미만이면 작은 폰)
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // 작은 화면에서는 패딩을 조금 줄여서 공간 확보
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. 브랜드 로고 (크기 및 여백 축소)
                  Container(
                    padding: const EdgeInsets.all(12), // [수정] 16 -> 12
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.home,
                      size: 40, // [수정] 48 -> 40
                      color: Color(0xFF1A68FF),
                    ),
                  ),
                  const SizedBox(height: 16), // [수정] 24 -> 16
                  // 2. 서비스 이름 & 슬로건
                  const Text(
                    'SafeHome AI',
                    style: TextStyle(
                      fontSize: 24, // [수정] 26 -> 24
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A68FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '아이의 안전을 위한 첫걸음',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),

                  // [수정] 화면 크기에 따라 여백 유동적 조절 (작은 폰은 24, 큰 폰은 32)
                  SizedBox(height: isSmallScreen ? 24 : 32),

                  // 3. 이메일 입력
                  Align(alignment: Alignment.centerLeft, child: _label('이메일')),
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('safehome@example.com'),
                  ),
                  const SizedBox(height: 16),

                  // 4. 비밀번호 입력
                  Align(alignment: Alignment.centerLeft, child: _label('비밀번호')),
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: _inputDecoration('비밀번호 입력').copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ),

                  // [수정] 여백 대폭 축소 (32 -> 24)
                  const SizedBox(height: 24),

                  // 5. 로그인 버튼 (높이 축소 52 -> 48)
                  SizedBox(
                    width: double.infinity,
                    height: 48, // [수정] 52 -> 48
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A68FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20, // [수정] 로딩 인디케이터도 살짝 작게
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              '로그인',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12), // [수정] 버튼 사이 간격 16 -> 12
                  // 6. 게스트 체험 버튼 (높이 축소 52 -> 48)
                  SizedBox(
                    width: double.infinity,
                    height: 48, // [수정] 52 -> 48
                    child: OutlinedButton(
                      onPressed: () async {
                        // ... (기존 로직 동일) ...
                        if (_isSubmitting) return;
                        setState(() => _isSubmitting = true);
                        try {
                          final success = await context
                              .read<AuthProvider>()
                              .guestLogin();
                          if (!mounted) return;
                          if (success) {
                            context.read<UiProvider>().setTabIndex(0);
                            Navigator.pushReplacementNamed(context, '/main');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('게스트 로그인 실패')),
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                        // ... (여기까지 기존 로직) ...
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1A68FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '게스트로 체험하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A68FF),
                        ),
                      ),
                    ),
                  ),

                  // [수정] 하단 여백 축소 (24 -> 16)
                  const SizedBox(height: 16),

                  // 7. 회원가입 링크
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '계정이 없으신가요?',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<UiProvider>().setTabIndex(0);
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: const Text(
                          '회원가입',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A68FF),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 키보드가 올라왔을 때를 대비한 하단 여백 확보
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[700], // 진한 회색
          fontWeight: FontWeight.normal, // 굵기 보통
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: const Color(0xFFEBF2FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: const Color(0xFF1A68FF).withOpacity(0.7)),
      ),
    );
  }
}
