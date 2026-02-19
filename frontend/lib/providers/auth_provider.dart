import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_provider.dart';

/// ✅ 앱 전역 인증 상태(백엔드 연동)
/// - 회원가입/로그인 시 JWT(access_token)와 사용자 이름을 로컬에 저장합니다.
class AuthProvider extends ChangeNotifier {
  static const String _prefsKeyToken = 'safehome.auth.token.v1';
  static const String _prefsKeyEmail = 'safehome.auth.email.v1';
  static const String _prefsKeyUserName = 'safehome.user.name.v1';
  static const String _prefsKeyIsGuest = 'safehome.user.is_guest.v1';

  final ApiProvider api;

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  bool _isGuest = false;
  String? _email;
  String? _token;
  String? _userName;

  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;
  String? get email => _email;
  String? get token => _token;
  String? get userName => _userName;

  AuthProvider({required this.api}) {
    _init();
  }

  /// 앱 시작 시 저장된 세션 복구
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_prefsKeyToken);
    _email = prefs.getString(_prefsKeyEmail);
    _userName = prefs.getString(_prefsKeyUserName);
    _isGuest = prefs.getBool(_prefsKeyIsGuest) ?? false;

    _isLoggedIn = (_token ?? '').isNotEmpty;
    _isInitialized = true;
    notifyListeners();
  }

  /// ✅ 회원가입 + 자동 로그인
  Future<bool> signup({
    required String email,
    required String password,
    required String userName,
  }) async {
    try {
      // 1. 서버에 가입 요청
      final token = await api.register(
        email: email,
        password: password,
        userName: userName,
      );

      if (token.isEmpty) return false;

      // 2. 상태 갱신 및 로컬 저장
      final prefs = await SharedPreferences.getInstance();
      _token = token;
      _email = email.trim().toLowerCase();
      _userName = userName;
      _isLoggedIn = true;
      _isGuest = false; // 일반 가입이므로 게스트 아님

      await prefs.setString(_prefsKeyToken, _token!);
      await prefs.setString(_prefsKeyEmail, _email!);
      await prefs.setString(_prefsKeyUserName, _userName!);
      await prefs.setBool(_prefsKeyIsGuest, false);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Signup Error: $e");
      return false;
    }
  }

  /// ✅ 로그인
  Future<bool> login({required String email, required String password}) async {
    try {
      // ApiProvider의 login이 Map을 반환하도록 수정되었다고 가정합니다.
      // 만약 String을 반환한다면 api_provider.dart 확인이 필요합니다.
      final dynamic result = await api.login(email: email, password: password);

      String? token;
      String? nameFromServer;

      // result가 Map인지 String인지 확인하여 처리 (호환성 확보)
      if (result is Map<String, dynamic>) {
        token = result['access_token'];
        nameFromServer = result['user_name'];
      } else if (result is String) {
        token = result;
      }

      if (token == null || token.isEmpty) return false;

      final prefs = await SharedPreferences.getInstance();
      _token = token;
      _email = email.trim().toLowerCase();
      _isLoggedIn = true;
      _isGuest = false;

      // 서버에서 이름을 받아왔다면 업데이트, 아니면 기존 로직 유지
      if (nameFromServer != null) {
        _userName = nameFromServer;
        await prefs.setString(_prefsKeyUserName, _userName!);
      }

      await prefs.setString(_prefsKeyToken, _token!);
      await prefs.setString(_prefsKeyEmail, _email!);
      await prefs.setBool(_prefsKeyIsGuest, false);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Login Error: $e");
      return false;
    }
  }

  /// 🟢 게스트 로그인 함수
  Future<bool> guestLogin() async {
    try {
      // 1. 데이터를 Map 형태로 받습니다.
      final data = await api.guestLogin();

      // 2. Map에서 필요한 값만 추출
      final token = data['access_token'];
      final email = data['email'];
      final userName = data['user_name'];
      final isGuest = data['is_guest'] ?? false;

      if (token == null) return false;

      final prefs = await SharedPreferences.getInstance();

      // 3. 상태 저장
      _token = token;
      _email = email;
      _userName = userName;
      _isLoggedIn = true;
      _isGuest = isGuest;

      await prefs.setString(_prefsKeyToken, _token!);
      await prefs.setString(_prefsKeyEmail, _email ?? '');
      await prefs.setString(_prefsKeyUserName, _userName ?? '');
      await prefs.setBool(_prefsKeyIsGuest, _isGuest);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Guest login error: $e');
      return false;
    }
  }

  /// ✅ 로그아웃 (세션, 이름, 게스트 정보 제거)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyToken);
    await prefs.remove(_prefsKeyEmail);
    await prefs.remove(_prefsKeyUserName);
    await prefs.remove(_prefsKeyIsGuest); // 게스트 정보 삭제

    _isLoggedIn = false;
    _email = null;
    _token = null;
    _userName = null;
    _isGuest = false; // 게스트 상태 초기화

    notifyListeners();
  }
}
