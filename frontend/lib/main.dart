import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// [연결] Provider들
import 'providers/api_provider.dart';
import 'providers/ui_provider.dart';
import 'providers/history_provider.dart';
import 'providers/scan_provider.dart';
import 'providers/child_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/community_provider.dart';

// [연결] 화면 및 테마
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/child_profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

import 'package:flutter/foundation.dart';

/// ✅ 웹 환경에서 마우스 드래그로 스크롤 가능하게 설정
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

void main() async {
  // ✅ 2. 비동기 작업(권한 요청)을 위해 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 3. 앱 시작 시 알림 권한 요청 (브라우저에 허용/거부 팝업이 뜹니다)
  // await NotificationService.requestPermission();

  runApp(const SafeHomeApp());
}

class SafeHomeApp extends StatelessWidget {
  const SafeHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiProvider>(
          create: (_) => ApiProvider(
            baseUrl: kReleaseMode
                ? 'https://safehome-backend-151491903492.asia-northeast3.run.app/'
                : 'http://localhost:8000',
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(api: context.read<ApiProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => UiProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              HistoryProvider(api: context.read<ApiProvider>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ScanProvider(api: context.read<ApiProvider>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ChildProvider(api: context.read<ApiProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
      ],
      child: MaterialApp(
        title: '세이프홈',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
        scrollBehavior: MyCustomScrollBehavior(),
        debugShowCheckedModeBanner: false,

        // 🎨 AppTheme에 정의된 테마 일괄 적용
        theme: AppTheme.lightTheme,

        builder: (context, child) {
          return Container(
            color: const Color(0xFFF5F5F7), // 브라우저 배경
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450), // 모바일 폭 제한
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          );
        },
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.isInitialized) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!auth.isLoggedIn) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ui = context.read<UiProvider>();
                if (ui.tabIndex != 0) {
                  ui.setTabIndex(0);
                }
              });
              return const OnboardingScreen();
            }

            return const MainShell();
          },
        ),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/signup': (context) => const SignupScreen(),
          '/login': (context) => const LoginScreen(),
          '/child_registration': (context) => const ChildProfileScreen(),
          '/main': (context) => const MainShell(),
        },
      ),
    );
  }
}
