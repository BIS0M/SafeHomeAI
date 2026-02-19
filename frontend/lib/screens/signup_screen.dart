import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// ✅ 회원가입 화면
/// - 이름(username), 이메일, 비밀번호를 입력받아 백엔드에 전송합니다.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ✅ 컨트롤러 정의
  final _nameController = TextEditingController(); // 이름(username)용
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();

  bool _isSubmitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    super.dispose();
  }

  // 이메일 정규식 검사
  bool _isValidEmail(String email) {
    final e = email.trim();
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(e);
  }

  /// ✅ 가입 제출 로직
  Future<void> _submit() async {
    if (_isSubmitting) return;

    final userName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final password2 = _password2Controller.text.trim();

    // 1. 유효성 검사
    if (userName.isEmpty) {
      _showSnackBar('이름을 입력해주세요.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('이메일 형식을 확인해주세요.');
      return;
    }

    if (password.length < 4) {
      _showSnackBar('비밀번호는 4자리 이상으로 입력해주세요.');
      return;
    }

    if (password != password2) {
      _showSnackBar('비밀번호가 서로 일치하지 않습니다.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ✅ 2. AuthProvider의 signup 호출 (username 전달)
      final ok = await context.read<AuthProvider>().signup(
        email: email,
        password: password,
        userName: userName,
      );

      if (!mounted) return;

      if (!ok) {
        _showSnackBar('이미 가입된 이메일입니다.');
        return;
      }

      // 가입 성공 시 다음 단계(아이 등록)로 이동
      Navigator.pushReplacementNamed(context, '/child_registration');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 공통 스낵바 알림
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 화면 높이에 따라 여백 유동적 조절 (높이 700 미만 작은 폰 대응)
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(""),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. 브랜드 로고 (크기 축소: 48->40, 패딩 16->12)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.home,
                        size: 40, // ✅ 로고 축소
                        color: Color(0xFF1A68FF),
                      ),
                    ),
                    const SizedBox(height: 16), // ✅ 간격 축소 (24->16)
                    // 2. 타이틀
                    const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 24, // ✅ 폰트 축소 (26->24)
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A68FF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '아이의 안전을 위한 계정을 생성합니다.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),

                    // 화면 크기에 따른 유동적 여백
                    SizedBox(height: isSmallScreen ? 20 : 32),

                    // 3. 이름 입력
                    Align(alignment: Alignment.centerLeft, child: _label('이름')),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 14), // ✅ 입력 글자 크기 14 고정
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('사용하실 이름을 입력해주세요'),
                    ),
                    const SizedBox(height: 12), // ✅ 간격 축소 (16->12)
                    // 4. 이메일 입력
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _label('이메일'),
                    ),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(fontSize: 14), // ✅ 입력 글자 크기 14 고정
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('예: safehome@example.com'),
                    ),
                    const SizedBox(height: 12), // ✅ 간격 축소
                    // 5. 비밀번호 입력
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _label('비밀번호'),
                    ),
                    TextField(
                      controller: _passwordController,
                      style: const TextStyle(fontSize: 14), // ✅ 입력 글자 크기 14 고정
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration('비밀번호 (4자리 이상)').copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey[500],
                            size: 20, // ✅ 아이콘 크기 축소
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12), // ✅ 간격 축소
                    // 6. 비밀번호 확인
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _label('비밀번호 확인'),
                    ),
                    TextField(
                      controller: _password2Controller,
                      style: const TextStyle(fontSize: 14), // ✅ 입력 글자 크기 14 고정
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: _inputDecoration('비밀번호를 다시 입력해주세요'),
                    ),

                    const SizedBox(height: 24), // ✅ 버튼 위 간격 축소 (32->24)
                    // 7. 회원가입 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 48, // ✅ 버튼 높이 축소 (52->48)
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
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                '회원가입 완료',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16), // ✅ 하단 간격 축소
                    // 8. 로그인 링크
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '이미 계정이 있으신가요?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text(
                            '로그인',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A68FF),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 👇 [스타일 통일] 로그인 화면과 똑같은 라벨 스타일
  // 👇 [수정] 라벨 간격과 폰트 크기 축소
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6), // ✅ 간격 8 -> 6 축소
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.normal,
          fontSize: 13, // ✅ 폰트 14 -> 13 축소
        ),
      ),
    );
  }

  // 👇 [스타일 통일] 로그인 화면과 똑같은 입력창 스타일
  // 👇 [수정] 입력창 높이를 16 -> 12로 줄이고, isDense 옵션 추가
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 14, // 힌트 크기
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true, // ✅ [핵심] 내부 여백을 타이트하게 조절
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ), // ✅ 세로 여백 축소
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEBF2FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A68FF)),
      ),
    );
  }
}
