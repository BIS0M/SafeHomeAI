import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// [Provider]
import '../providers/history_provider.dart';
import '../providers/ui_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/child_provider.dart';
import '../providers/community_provider.dart'; // ✅ 추가

// [Model]
import '../models/scan_record.dart';
import '../models/child_profile.dart';
import '../models/post_model.dart'; // ✅ 추가
// [Screen]
import '../screens/scan/analysis_result_screen.dart';

// [Widget]
import '../widgets/home/home_header.dart'; // 기존 헤더 사용
import '../widgets/home/home_empty_state.dart';
import '../widgets/community/mini_post_card.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 초기 데이터 로딩
    _refreshData();
  }
    // 화면 진입 시 데이터 최신화
    Future<void> _refreshData() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.token != null) {
      // 1. 아이 프로필 & 히스토리 로딩
      context.read<HistoryProvider>().fetchHistory(auth.email!, auth.token!);
      context.read<ChildProvider>().fetchChildrenFromServer(auth.token!);
      
      // 2. 오늘의 인기글 로딩 (await를 써서 완료될 때까지 기다림)
      await context.read<CommunityProvider>().fetchDailyBest(context);
    }
  }
  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final childProvider = context.watch<ChildProvider>();
    final uiProvider = context.read<UiProvider>();
    final communityProvider = context.watch<CommunityProvider>(); // ✅ 추가

    final records = historyProvider.history;
    final children = childProvider.children;
    final hasData = children.isNotEmpty || records.isNotEmpty;
    final dailyBestPosts = communityProvider.dailyBestPosts; // ✅ 인기글 데이터

    // 하단 '최근 분석 내역'용 리스트 (최대 5개)
    final recentRecords = records.take(5).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. 상단 헤더 (기존 유지)
          HomeHeader(onProfileTap: () => uiProvider.setTabIndex(4)),
          Expanded(
            // ✅ [수정] RefreshIndicator 추가: 당겨서 새로고침 기능
            child: RefreshIndicator(
              onRefresh: _refreshData, // 당기면 이 함수 실행
              color: Colors.blue,      // 로딩 인디케이터 색상
              backgroundColor: Colors.white,
              child: hasData
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(), // 내용이 적어도 스크롤 가능하게 설정
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -----------------------------------------------------
                          // 2. 아이별 안전 기록
                          // -----------------------------------------------------
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildSectionTitle('아이별 안전 기록', badgeText: '최신순'),
                          ),
                          const SizedBox(height: 10),
                          if (children.isEmpty)
                            _buildNoChildBox()
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: children.length,
                              itemBuilder: (context, index) {
                                final child = children[index];
                                final childRecords = records.where((r) => r.childId == child.id).toList()
                                  ..sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
                                return _ChildHistoryRow(child: child, records: childRecords);
                              },
                            ),
                          
                          const SizedBox(height: 30),
                          const Divider(thickness: 8, color: Color(0xFFF5F7FA)),
                          const SizedBox(height: 30),

                          // -----------------------------------------------------
                          // 3. 🔥 오늘의 인기글 (커뮤니티)
                          // -----------------------------------------------------
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildSectionTitle(
                              '오늘의 인기글',
                              isAction: true,
                              onActionTap: () => uiProvider.setTabIndex(1), 
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            height: 250, // MiniPostCard 높이에 맞춤
                            child: dailyBestPosts.isEmpty
                                ? _buildEmptyCommunityBox()
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: dailyBestPosts.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      // MiniPostCard 사용
                                      return MiniPostCard(post: dailyBestPosts[index]);
                                    },
                                  ),
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    )
                  : Stack( // 데이터 없을 때도 새로고침 가능하도록 Stack으로 감쌈
                      children: [
                        const HomeEmptyState(),
                        IgnorePointer(
                          ignoring: true,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [],
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

  // 인기글 없을 때 표시할 박스
  Widget _buildEmptyCommunityBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.auto_awesome, color: Colors.amber, size: 30),
          SizedBox(height: 10),
          Text(
            '아직 오늘의 인기글이 없어요.\n첫 번째 주인공이 되어보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.4),
          ),
        ],
      ),
    );
  }
  /// ✅ 섹션 타이틀: 아이콘/텍스트/뱃지/전체보기 가로(한 줄) 정렬 맞춤
  Widget _buildSectionTitle(
    String title, {
    String? badgeText,
    bool isAction = false,
    VoidCallback? onActionTap,
  }) {
    return SizedBox(
      height: 28, // ✅ 한 줄 높이 고정 (정렬 안정화)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // title
                Text(
                  title,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: 8),
                  // badge도 Center로 감싸서 텍스트와 같은 축에 맞춤
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (isAction)
            GestureDetector(
              onTap: onActionTap,
              child: const SizedBox(
                height: 28,
                child: Center(
                  child: Text(
                    '전체보기 >',
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.0),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 아이가 없을 때 박스 (기존 유지)
  Widget _buildNoChildBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Text('등록된 아이가 없습니다.', style: TextStyle(color: Colors.grey))),
    );
  }

  // 하단 '최근 분석 내역'의 각 행
  Widget _buildSimpleHistoryRow(BuildContext context, ScanRecord record) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AnalysisResultScreen(historyRecord: record)),
        );
      },
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Image.network(
                  record.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    record.room,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.dateLabel,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: record.risksFound > 0 ? const Color(0xFFFFE5E5) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                record.risksFound > 0 ? '위험 ${record.risksFound}' : '안전',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: record.risksFound > 0 ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 아래는 기존 위젯들 ---

class _ChildHistoryRow extends StatelessWidget {
  final Child child;
  final List<ScanRecord> records;
  const _ChildHistoryRow({required this.child, required this.records});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: SizedBox(
            height: 28, // ✅ 한 줄 높이 고정으로 아이콘/텍스트/뱃지 정렬 맞춤
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  child: Center(
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.face, size: 16, color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Center(
                  child: Text(
                    child.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, height: 1.0),
                  ),
                ),
                const SizedBox(width: 6),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      child.growthStage.split('-').first,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 11, height: 1.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 170,
          child: records.isEmpty
              ? _buildEmptyChildHistory()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _HistoryImageCard(record: records[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyChildHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: 140,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, color: Colors.grey),
          SizedBox(height: 8),
          Text('기록 없음', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _HistoryImageCard extends StatelessWidget {
  final ScanRecord record;
  const _HistoryImageCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final bool isSafe = record.risksFound == 0;
    final Color statusColor = isSafe ? Colors.green : Colors.redAccent;
    final String statusText = isSafe ? "안전" : "위험 ${record.risksFound}";

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalysisResultScreen(historyRecord: record))),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      record.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Text(
                        record.room,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.dateLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isSafe ? Icons.check_circle : Icons.warning_rounded, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
