import 'package:shared_preferences/shared_preferences.dart';

/// ✅ 데모용 로컬 인증 서비스
/// - 회원가입(이메일/비밀번호) 정보를 SharedPreferences에 저장
/// - 로그인 시 저장된 정보로만 간단 검증(서버 연동 전 임시)
/// - 현재 백엔드 연동(AuthProvider + ApiProvider) 사용 시에는 미사용(레거시)
class AuthService {
  static const String _prefsKeyLoggedIn = 'safehome.auth.logged_in.v1';
  static const String _prefsKeyEmail = 'safehome.auth.email.v1';

  // ✅ 회원가입(등록) 정보 저장 키(데모: 비밀번호 평문 저장)
  static const String _prefsKeyRegisteredEmail =
      'safehome.auth.registered_email.v1';
  static const String _prefsKeyRegisteredPassword =
      'safehome.auth.registered_password.v1';

  // ✅ 데모용(간단 검증) 계정
  // 필요하면 추후 백엔드 로그인 API로 교체하세요.
  static const String demoEmail = 'gildong@example.com';
  static const String demoPassword = '1234';

  /// 회원가입으로 저장된 계정 정보 로드
  Future<({String? email, String? password})>
  loadRegisteredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_prefsKeyRegisteredEmail);
    final password = prefs.getString(_prefsKeyRegisteredPassword);
    return (email: email, password: password);
  }

  Future<bool> hasRegisteredCredentials() async {
    final creds = await loadRegisteredCredentials();
    return (creds.email ?? '').trim().isNotEmpty &&
        (creds.password ?? '').isNotEmpty;
  }

  /// 회원가입(로컬 저장)
  Future<void> register({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyRegisteredEmail, email.trim().toLowerCase());
    await prefs.setString(_prefsKeyRegisteredPassword, password);
  }

  /// 로그인 세션 로드
  Future<({bool isLoggedIn, String? email})> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_prefsKeyLoggedIn) ?? false;
    final email = prefs.getString(_prefsKeyEmail);
    return (isLoggedIn: isLoggedIn, email: email);
  }

  /// 로그인 세션 저장
  Future<void> saveSession({required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyLoggedIn, true);
    await prefs.setString(_prefsKeyEmail, email);
  }

  /// 로그아웃(세션 삭제)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyLoggedIn);
    await prefs.remove(_prefsKeyEmail);
  }

  Future<bool> verifyCredentials({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final pw = password;

    // ✅ 사용자 정보 체크(데모)
    // 1) 회원가입한 계정이 있으면 그 정보로 검증
    final registered = await loadRegisteredCredentials();
    final regEmail = (registered.email ?? '').trim().toLowerCase();
    final regPassword = registered.password ?? '';
    if (regEmail.isNotEmpty) {
      return normalized == regEmail && pw == regPassword;
    }

    // 2) 없으면 데모 계정 허용(초기 테스트용)
    return normalized == demoEmail && pw == demoPassword;
  }
}
