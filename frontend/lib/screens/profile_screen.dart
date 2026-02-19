import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_profile.dart';
import '../providers/child_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ui_provider.dart';
import 'child_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// 로컬 저장용 키 (수정 시 동기화용)
  static const String _prefsKeyUserName = 'safehome.user.name.v1';
  final String _defaultUserName = '사용자';

  /// 🛠️ 이름 수정 다이얼로그
  /// - 입력받은 이름을 로컬 저장소에 업데이트합니다.
  Future<void> _showEditNameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이름 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(hintText: '새 이름을 입력하세요'),
          onSubmitted: (_) => Navigator.pop(context, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final nextName = result.trim();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyUserName, nextName);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름이 수정되었습니다. 앱 재시작 시 반영됩니다.')),
      );
      // TODO: 필요 시 AuthProvider의 이름을 즉시 업데이트하는 함수를 호출하세요.
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // 탭 화면 특성상 뒤로가기 시 홈(0번 탭)으로 이동
    return WillPopScope(
      onWillPop: () async {
        context.read<UiProvider>().setTabIndex(0);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => context.read<UiProvider>().setTabIndex(0),
          ),
          title: Text(
            '내 정보',
            style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ) ??
                const TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 22),
          child: Column(
            children: [
              _buildUserProfileCard(),
              const SizedBox(height: 8),
              _buildChildSection(),
              const SizedBox(height: 12),

              // ✅ 하단 설정 섹션: 섹션 타이틀 + 카드
              _buildSettings(),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ 사용자 프로필 카드: AuthProvider의 실시간 데이터를 사용합니다.
  Widget _buildUserProfileCard() {
    final auth = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;

    // AuthProvider에 저장된 이름이 있으면 사용하고, 없으면 기본값을 표시합니다.
    final displayName = auth.userName ?? _defaultUserName;
    final email = auth.email ?? "정보 없음";

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFEBF2FF),
            child: Icon(Icons.person, color: Color(0xFF1A68FF), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: textTheme.labelSmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '이름 수정',
            onPressed: () => _showEditNameDialog(displayName),
            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 우리 아이 목록 섹션
  Widget _buildChildSection() {
    final childProvider = context.watch<ChildProvider>();
    final textTheme = Theme.of(context).textTheme;
    final children = childProvider.children;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '우리 아이 관리',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          if (!childProvider.isLoaded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],

          if (children.isNotEmpty) ...[
            ...children.map((c) => _childCard(c)),
            const SizedBox(height: 12),
          ],

          // ✅ 여기서 로그아웃/로그인 이동 절대 하면 안 됨
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChildProfileScreen(returnResultToPrevious: true),
                ),
              );

              if (result is Child && mounted) {
                final token = context.read<AuthProvider>().token;
                if (token != null) {
                  await context.read<ChildProvider>().fetchChildrenFromServer(token);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEBF2FF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: Color(0xFF1A68FF), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '새 아이 프로필 추가하기',
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF1A68FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 개별 아이 카드 구성
  Widget _childCard(Child c) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBF2FF)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFEBF2FF),
            child: Icon(Icons.face, color: Color(0xFF1A68FF), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.birthday} 생',
                      style: textTheme.labelSmall?.copyWith(color: Colors.black54),
                    ),
                    Text(
                      c.growthStage,
                      style: textTheme.labelSmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _showDeleteConfirm(c),
          ),
        ],
      ),
    );
  }

  /// 삭제 확인 다이얼로그
  void _showDeleteConfirm(Child c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('프로필 삭제'),
        content: Text("'${c.name}' 프로필을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final token = context.read<AuthProvider>().token;
              if (token != null) {
                await context.read<ChildProvider>().removeChild(c.id, token);
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 하단 설정 메뉴 리스트
  Widget _buildSettings() {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(textTheme, '앱 설정'),
          _buildSectionCard(
            children: [
              _buildSectionTile(
                icon: Icons.notifications_none,
                title: '알림 설정',
                onTap: () {},
              ),
              _buildDivider(),
              _buildSectionTile(
                icon: Icons.language,
                title: '언어 설정',
                trailingText: '한국어',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionTitle(textTheme, '데이터 관리'),
          _buildSectionCard(
            children: [
              _buildSectionTile(
                icon: Icons.delete_outline,
                title: '캐시 관리',
                onTap: () {},
              ),
              _buildDivider(),
              _buildSectionTile(
                icon: Icons.storage_outlined,
                title: '저장된 기록 백업 / 복원',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionTitle(textTheme, '도움말 및 정보'),
          _buildSectionCard(
            children: [
              _buildSectionTile(
                icon: Icons.info_outline,
                title: '앱 버전',
                trailingText: '1.0.0',
                onTap: () {},
              ),
              _buildDivider(),
              _buildSectionTile(
                icon: Icons.campaign_outlined,
                title: '공지사항',
                onTap: () {},
              ),
              _buildDivider(),
              _buildSectionTile(
                icon: Icons.help_outline,
                title: '자주 묻는 질문',
                onTap: () {},
              ),
              _buildDivider(),
              _buildSectionTile(
                icon: Icons.shield_outlined,
                title: '개인정보 처리방침',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            children: [
              _buildSectionTile(
                icon: Icons.logout,
                title: '로그아웃',
                isDestructive: true,
                onTap: () async {
                  // ✅ 탭 이동(setTabIndex) 제거: 프로필/홈 재로딩 현상 방지
                  await context.read<AuthProvider>().logout();
                  if (!mounted) return;

                  // ✅ 루트 네비게이터에서 스택 초기화 + 로그인 화면으로 강제 이동
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              '© 2026 세이프홈. All rights reserved.',
              style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // 헬퍼들 (이름 유지)
  // =========================

  Widget _buildSectionTitle(TextTheme textTheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F6));
  }

  Widget _buildSectionTile({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final textTheme = Theme.of(context).textTheme;

    // 로그아웃 포함 동일 정렬/톤
    final Color iconColor = (icon == Icons.logout) ? Colors.red : Colors.black87;
    final Color titleColor = Colors.black87;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                child: Center(
                  child: Icon(icon, size: 22, color: iconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.normal,
                      color: titleColor,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (trailingText != null) ...[
                      Flexible(
                        child: Text(
                          trailingText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.normal,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // 기존 함수(이름/시그니처 유지)
  // =========================
  Widget _settingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right, size: 20),
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}
