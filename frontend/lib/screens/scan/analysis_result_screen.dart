import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart';

import '../../../models/analysis_result.dart';
import '../../../models/scan_record.dart';
import '../../../providers/scan_provider.dart';
import '../../../theme/app_theme.dart';
import 'solution_detail_screen.dart';
import '../../widgets/analysis_loading_widget.dart';
import '../../widgets/web_image_widget.dart';
import '../../../providers/ui_provider.dart';
import '../../../providers/history_provider.dart';


// ✅ 글쓰기 화면 연결 (경로 확인)
import '../community/write_post_screen.dart';

class AnalysisResultScreen extends StatefulWidget {
  final ScanRecord? historyRecord;

  const AnalysisResultScreen({super.key, this.historyRecord});

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<UiProvider>().setAnalysisInProgress(false);
      }
    });
  }

  // ✅ 커뮤니티 공유하기
  void _shareToCommunity() {
    final scan = context.read<ScanProvider>();
    final isHistory = widget.historyRecord != null;

    final String? id = isHistory
        ? widget.historyRecord!.id
        : scan.currentAnalysisRecord?.id;

    final String title = isHistory
        ? '${widget.historyRecord!.room} 안전 점검'
        : '${scan.currentAnalysisRecord?.room ?? '공간'} 안전 점검';

    final String imageUrl = isHistory
        ? widget.historyRecord!.imageUrl
        : (scan.resultImageUrl ?? '');

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("아직 저장되지 않은 기록이라 공유할 수 없습니다.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WritePostScreen(
          linkedAnalysis: {'id': id, 'title': title, 'image': imageUrl},
        ),
      ),
    );
  }

  /// ✅ 현재 화면에서 사용할 record를 안전하게 가져오기
  /// - 히스토리 화면에서는: provider의 최신 record를 우선 사용(토글 반영용)
  /// - 분석 직후 화면에서는: scan.currentAnalysisRecord 사용
  ScanRecord _recordToUse(BuildContext context, ScanProvider scan) {
    if (widget.historyRecord != null) {
      final history = context.read<HistoryProvider>();
      return history.findById(widget.historyRecord!.id) ?? widget.historyRecord!;
    }
    return scan.currentAnalysisRecord!;
  }


  Future<void> _openHazardDetail(
    BuildContext context,
    DetectedHazard h,
    int index,
  ) async {
    final scan = context.read<ScanProvider>();
    final recordToUse = _recordToUse(context, scan);

    

    setState(() => _selectedIndex = index);
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SolutionDetailScreen(record: recordToUse, hazard: h, index: index),
      ),
    );

    if (!mounted) return;
    setState(() => _selectedIndex = null);
  }

  // ✅ 위험도 정렬 우선순위: 위험(0) → 경고(1)
  int _riskOrder(String level) {
    switch (level) {
      case '위험':
        return 0;
      case '경고':
        return 1;
      default:
        return 2;
    }
  }

  DetectedHazard? _topHazard(List<DetectedHazard> hazards) {
    if (hazards.isEmpty) return null;
    final sorted = [...hazards]
      ..sort(
        (a, b) => _riskOrder(a.riskLevel).compareTo(_riskOrder(b.riskLevel)),
      );
    return sorted.first;
  }

  Map<String, int> _countByLevel(List<DetectedHazard> hazards) {
    final m = <String, int>{'위험': 0, '경고': 0};
    for (final h in hazards) {
      if (m.containsKey(h.riskLevel)) {
        m[h.riskLevel] = (m[h.riskLevel] ?? 0) + 1;
      }
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanProvider>();
    final history = context.watch<HistoryProvider>();

    final bool isHistoryView = widget.historyRecord != null;

    if (scan.isAnalyzing && !isHistoryView) {
    return const AnalysisLoadingWidget();
  }

  final ScanRecord recordToUse = isHistoryView
      ? (history.findById(widget.historyRecord!.id) ?? widget.historyRecord!)
      : scan.currentAnalysisRecord!;

  final String roomName = isHistoryView
      ? recordToUse.room
      : (scan.currentAnalysisRecord?.room ?? '분석 결과');

    final String dateLabel = isHistoryView
      ? recordToUse.dateLabel
      : (scan.currentAnalysisRecord?.dateLabel ?? '');


    final String imgUrl = isHistoryView
      ? recordToUse.imageUrl
      : (scan.resultImageUrl ?? '');


    final List<DetectedHazard> hazardsRaw = isHistoryView
      ? recordToUse.hazards
      : scan.hazards;

    // ✅ solvedKeys 불러오기
    final solvedKeys = recordToUse.solvedHazardKeys.toSet();

    // ✅ 남은(미해결)만 별도로 계산 (요구사항 1,2,3)
    final List<DetectedHazard> remainingHazards = hazardsRaw
        .where((h) => !solvedKeys.contains(h.hazardKey))
        .toList();

    // ✅ (수정) 리스트 정렬: 미해결 먼저 + 해결은 아래로, 동률이면 위험도 기준
    final List<DetectedHazard> uiHazards = [...hazardsRaw]
      ..sort((a, b) {
        final aSolved = solvedKeys.contains(a.hazardKey);
        final bSolved = solvedKeys.contains(b.hazardKey);

        if (aSolved != bSolved) return aSolved ? 1 : -1; // 해결된 건 아래로
        return _riskOrder(a.riskLevel).compareTo(_riskOrder(b.riskLevel));
      });

    // ✅ 상단 요약은 "남은 위험요소" 기준으로 실시간 반영 (요구사항 1,2)
    final top = _topHazard(remainingHazards);
    final counts = _countByLevel(remainingHazards);
    final bool allSolved = remainingHazards.isEmpty;

    final Widget content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 요약 배너(사진 위) - 남은 개수 기준 + 0개면 축하(초록)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: _SummaryBanner(
              remaining: remainingHazards.length,
              danger: counts['위험'] ?? 0,
              warn: counts['경고'] ?? 0,
              topHazardLevel: top?.riskLevel,
              allSolved: allSolved,
            ),
          ),

          // ✅ 이미지 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              // 🟢 [수정] 위젯을 바로 배치 (사이즈는 내부에서 결정)
              child: imgUrl.isEmpty
                  ? const SizedBox(
                      height: 200, 
                      child: Center(child: Text('이미지가 없습니다.'))
                    )
                  : _HazardOverlayImage(
                      imageUrl: imgUrl,
                      hazards: uiHazards,
                      // ✅ 비율을 맞출 것이므로 cover로 해도 잘리지 않음 (꽉 채움)
                      fit: BoxFit.cover, 
                      selectedIndex: _selectedIndex,
                      onSelectHazard: (hazard, index) {
                        _openHazardDetail(context, hazard, index);
                      },
                      record: recordToUse,
                    ),
            ),
          ),

          // ✅ (요구사항 3,4) "발견된 위험요소(n개)" 실시간 감소 + 오른쪽에 공유 버튼 배치
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '발견된 위험요소 (${remainingHazards.length}개)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 오른쪽 빈 여백에 공유 버튼
                OutlinedButton.icon(
                  onPressed: _shareToCommunity,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('공유'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary.withOpacity(0.55)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          // 리스트는 전체(uiHazards) 보여주되, 해결된 건 아래/회색 처리 + 아이콘/배지 변경
          ...uiHazards.asMap().entries.map((entry) {
            final index = entry.key;
            final hazard = entry.value;

            final isSolved = solvedKeys.contains(hazard.hazardKey);

            return Opacity(
              opacity: isSolved ? 0.55 : 1.0,
              child: _HazardAccordionTile(
                index: index,
                hazard: hazard,
                isSolved: isSolved,
                isSelected: _selectedIndex == index,
                onFocus: () => setState(() => _selectedIndex = index),
                onUnfocus: () {
                  if (_selectedIndex == index)
                    setState(() => _selectedIndex = null);
                },
                onDetailTap: () => _openHazardDetail(context, hazard, index),
              ),
            );
          }),

          const SizedBox(height: 24),
          const SizedBox(height: 40),
        ],
      ),
    );

    if (isHistoryView) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: Text('$roomName · $dateLabel'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: content,
      );
    }

    return content;
  }
}

/* -------------------------------------------------------------------------- */
/* Colors                                                                     */
/* -------------------------------------------------------------------------- */

const Color _kSolvedGreen = Color(0xFF34C759); // iOS Green

Color _levelColor(String level) {
  switch (level) {
    case '위험':
      return const Color(0xFFFF3B30); // RED
    case '경고':
      return const Color(0xFFFFCC00); // YELLOW
    default:
      return const Color(0xFF8E8E93);
  }
}

Color _badgeBg(String level) {
  switch (level) {
    case '위험':
      return const Color(0xFFFFE5E5);
    case '경고':
      return const Color(0xFFFFF4CC);
    default:
      return const Color(0xFFF2F2F7);
  }
}

Color _badgeText(String level) {
  switch (level) {
    case '위험':
      return const Color(0xFFE53935);
    case '경고':
      return const Color(0xFFF9A825);
    default:
      return const Color(0xFF6B7280);
  }
}

/* -------------------------------------------------------------------------- */
/* Summary Banner                                                             */
/* -------------------------------------------------------------------------- */

class _SummaryBanner extends StatelessWidget {
  final int remaining;
  final int danger;
  final int warn;
  final String? topHazardLevel;
  final bool allSolved;

  const _SummaryBanner({
    required this.remaining,
    required this.danger,
    required this.warn,
    required this.topHazardLevel,
    required this.allSolved,
  });

  @override
  Widget build(BuildContext context) {
    if (allSolved) {
      // ✅ (요구사항 2) 0개면 초록 + 축하 문구
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kSolvedGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kSolvedGreen.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.celebration_rounded, color: _kSolvedGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '위험요소를 전부 해결하였습니다! 🎉',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '현재 공간은 안전한 상태입니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final level = topHazardLevel ?? '위험';
    final levelColor = _levelColor(level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _badgeBg(level),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: levelColor.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: levelColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '현재 공간에서 $remaining개의 위험 요소가 발견되었습니다',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '위험 $danger · 경고 $warn',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.62),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* Hazard Accordion Tile                                                      */
/* -------------------------------------------------------------------------- */

class _HazardAccordionTile extends StatefulWidget {
  final int index;
  final DetectedHazard hazard;
  final bool isSolved;

  final bool isSelected;
  final VoidCallback onFocus;
  final VoidCallback onUnfocus;
  final VoidCallback onDetailTap;

  const _HazardAccordionTile({
    required this.index,
    required this.hazard,
    required this.isSolved,
    required this.onDetailTap,
    required this.isSelected,
    required this.onFocus,
    required this.onUnfocus,
  });

  @override
  State<_HazardAccordionTile> createState() => _HazardAccordionTileState();
}

class _HazardAccordionTileState extends State<_HazardAccordionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hazard = widget.hazard;
    final level = hazard.riskLevel;

    // ✅ (요구사항 5) 해결이면 초록 체크, 아니면 기존 색
    final Color mainColor = widget.isSolved
        ? _kSolvedGreen
        : _levelColor(level);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: widget.isSelected
              ? mainColor.withOpacity(0.35)
              : Colors.grey.shade200,
          width: widget.isSelected ? 1.2 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          widget.onFocus();
          widget.onDetailTap();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  // ✅ 왼쪽 동그라미: 해결이면 체크 표시(초록)
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: mainColor,
                      shape: BoxShape.circle,
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: mainColor.withOpacity(0.25),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: widget.isSolved
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : Text(
                            '${widget.index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  Expanded(
                    child: Text(
                      hazard.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  // ✅ 오른쪽 배지: 해결이면 "해결"(초록), 아니면 위험/경고
                  _buildStatusBadge(level, widget.isSolved),
                ],
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _summaryOrFallback(hazard),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.black.withOpacity(0.62),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        widget.onFocus();
                        widget.onDetailTap();
                      },
                      icon: Icon(
                        widget.isSolved
                            ? Icons.check_circle_rounded
                            : Icons.article_outlined,
                        size: 16,
                        color: widget.isSolved ? _kSolvedGreen : null,
                      ),
                      label: Text(widget.isSolved ? '해결 상태 보기' : '해결 방법 보기'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: widget.isSolved
                              ? _kSolvedGreen
                              : AppTheme.primary,
                        ),
                        foregroundColor: widget.isSolved
                            ? _kSolvedGreen
                            : AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onFocus();
                        setState(() => _isExpanded = !_isExpanded);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isSolved
                            ? _kSolvedGreen
                            : AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isExpanded
                                ? Icons.shopping_cart
                                : Icons.shopping_cart_outlined,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text('제품 추천'),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (_isExpanded) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                if (hazard.recommendations.isNotEmpty)
                  ...hazard.recommendations.map(
                    (p) => _ProductItem(
                      name: p.name,
                      price: p.price != null ? p.price.toString() : '',
                      imageUrl: p.imageUrl ?? "https://via.placeholder.com/150",
                      linkUrl: p.buyUrl ?? '',
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        "연관된 추천 상품이 없습니다.",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String level, bool solved) {
    if (solved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _kSolvedGreen.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _kSolvedGreen.withOpacity(0.35)),
        ),
        child: const Text(
          '해결',
          style: TextStyle(
            color: _kSolvedGreen,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final bgColor = _badgeBg(level);
    final textColor = _badgeText(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _summaryOrFallback(DetectedHazard h) {
    final s = (h.summary ?? '').trim();
    if (s.isNotEmpty) return s;

    final title = h.title;
    if (title.contains('추락')) return '높이/모서리로 인해 영유아 추락 위험이 있습니다.';
    if (title.contains('유리')) return '파손 시 날카로운 파편으로 상해 위험이 있습니다.';
    if (title.contains('화초') || title.contains('식물'))
      return '섭취 시 중독/알레르기 위험이 있습니다.';
    if (title.contains('콘센트')) return '감전 및 화재 위험이 있습니다.';
    return '해당 요소는 아이에게 위험할 수 있습니다.';
  }
}

/* -------------------------------------------------------------------------- */
/* Product Item                                                               */
/* -------------------------------------------------------------------------- */

class _ProductItem extends StatelessWidget {
  final String name;
  final String price;
  final String imageUrl;
  final String linkUrl;

  const _ProductItem({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.linkUrl,
  });

  Future<void> _launchUrl() async {
    if (linkUrl.trim().isEmpty) return;
    final Uri url = Uri.parse(linkUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $linkUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final formattedPrice = _formatPriceString(price);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 52,
          height: 52,
          child: WebImageWidget(imageUrl: imageUrl, fit: BoxFit.cover),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        formattedPrice.isEmpty ? '' : '₩$formattedPrice',
        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
      ),
      trailing: ElevatedButton(
        onPressed: linkUrl.trim().isEmpty ? null : _launchUrl,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(64, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          '구매',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

    String _formatPriceString(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final value = int.tryParse(digits);
    if (value == null) return '';
    return NumberFormat('#,###').format(value);
  }
}

/* -------------------------------------------------------------------------- */
/* Hazard Overlay Image                                                       */
/* -------------------------------------------------------------------------- */

class _HazardOverlayImage extends StatefulWidget {
  final String imageUrl;
  final List<DetectedHazard> hazards;
  final BoxFit fit;

  final int? selectedIndex;
  final void Function(DetectedHazard hazard, int index)? onSelectHazard;

  final ScanRecord record;

  const _HazardOverlayImage({
    required this.imageUrl,
    required this.hazards,
    required this.fit,
    required this.record,
    this.selectedIndex,
    this.onSelectHazard,
  });

  @override
  State<_HazardOverlayImage> createState() => _HazardOverlayImageState();
}

class _HazardOverlayImageState extends State<_HazardOverlayImage> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _loadNaturalSize(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant _HazardOverlayImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageSize = null;
      _loadNaturalSize(widget.imageUrl);
    }
  }

  void _loadNaturalSize(String url) {
    if (url.isEmpty) return;

    final provider = NetworkImage(url);
    provider
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            if (!mounted) return;
            setState(() {
              _imageSize = Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              );
            });
          }, onError: (dynamic e, StackTrace? st) {}),
        );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 이미지 비율 계산 (로딩 중일 땐 기본 4:3 = 1.33)
    final double aspectRatio = (_imageSize != null && _imageSize!.height > 0)
        ? _imageSize!.width / _imageSize!.height
        : 16 / 12;

    // 2. AspectRatio로 감싸서, 위젯 전체 높이를 이미지 비율에 맞춤
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, c) {
          final containerSize = Size(c.maxWidth, c.maxHeight);
          
          return Stack(
            fit: StackFit.expand,
            children: [
              // 이미지 (WebImageWidget)
              WebImageWidget(imageUrl: widget.imageUrl, fit: widget.fit),

              // 탭 힌트
              const Positioned(
                top: 10,
                left: 10,
                child: IgnorePointer(
                  child: _TapHintOverlay(text: '사진 탭 → 해결 방법'),
                ),
              ),

              // 위험 요소 박스들 (Bbox) - 별도 함수로 분리하여 깔끔하게 처리
              if (_imageSize != null)
                ..._buildHazardBoxes(containerSize),
            ],
          );
        },
      ),
    );
  }

  // ✅ [수정] 복잡한 박스 생성 로직을 함수로 분리
  List<Widget> _buildHazardBoxes(Size containerSize) {
    final items = widget.hazards
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final h = entry.value;

          // 해결된 건 박스 안 그림
          if (widget.record.solvedHazardKeys.contains(h.hazardKey)) {
            return null;
          }

          // 좌표 변환
          final rect = _mapBboxToContainerRect(
            bbox: h.bbox,
            imageSize: _imageSize!,
            containerSize: containerSize,
            fit: widget.fit,
          );

          // 유효성 검사
          final area = rect.width * rect.height;
          if (rect.width <= 0 || rect.height <= 0) return null;

          return _HazardRectItem(
            index: index,
            hazard: h,
            rect: rect,
            area: area,
          );
        })
        .whereType<_HazardRectItem>()
        .toList();

    // 작은 박스가 위에 오도록 정렬 (면적 내림차순 -> 나중에 그리는게 위로 올라오므로 큰거부터 그림)
    // 잠깐, 원래 코드는 `b.area.compareTo(a.area)` 였으므로 큰 것부터 정렬됨.
    // Stack은 나중에 그려진 게 위에 올라오므로, 작은 박스를 나중에 그려야 클릭이 됨.
    // 따라서 큰 박스 -> 작은 박스 순서로 정렬해서 리턴하면 됨.
    items.sort((a, b) => b.area.compareTo(a.area));

    return items.map((it) {
      final index = it.index;
      final h = it.hazard;
      final rect = it.rect;

      final level = h.riskLevel;
      final isSelected = widget.selectedIndex == index;

      final bool nearLeft = rect.left <= 10;
      final bool nearTop = rect.top <= 10;

      final Color borderColor = _levelColor(level);

      final double fillOpacity = widget.selectedIndex != null
          ? (isSelected ? 0.16 : 0.06)
          : 0.10;
      final double borderWidth = widget.selectedIndex != null
          ? (isSelected ? 2.0 : 1.0)
          : 1.2;
      final double scale = widget.selectedIndex != null
          ? (isSelected ? 1.02 : 1.0)
          : 1.0;
      final double dimOpacity = widget.selectedIndex != null
          ? (isSelected ? 1.0 : 0.55)
          : 0.85;

      final Color fillColor = borderColor.withOpacity(fillOpacity);

      return Positioned.fromRect(
        rect: rect,
        child: Opacity(
          opacity: dimOpacity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (widget.onSelectHazard != null) {
                widget.onSelectHazard!(h, index);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SolutionDetailScreen(
                    record: widget.record,
                    hazard: h,
                    index: index,
                  ),
                ),
              );
            },
            child: AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: scale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 박스 테두리 및 배경
                  Container(
                    decoration: BoxDecoration(
                      color: fillColor,
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // 선택 시 배경 강조
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  // 번호 배지 (Badge)
                  Positioned(
                    top: nearTop ? null : -12,
                    bottom: nearTop ? -12 : null,
                    left: nearLeft ? null : -12,
                    right: nearLeft ? -12 : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: isSelected ? 26 : 22,
                      height: isSelected ? 26 : 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: borderColor,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: borderColor.withOpacity(0.25),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSelected ? 12.5 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Rect _mapBboxToContainerRect({
    required List<double> bbox,
    required Size imageSize,
    required Size containerSize,
    required BoxFit fit,
  }) {
    // ... (이 함수는 기존 코드 그대로 유지)
    double x1 = bbox.isNotEmpty ? bbox[0] : 0;
    double y1 = bbox.length > 1 ? bbox[1] : 0;
    double x2 = bbox.length > 2 ? bbox[2] : 0;
    double y2 = bbox.length > 3 ? bbox[3] : 0;

    final maxVal = [x1, y1, x2, y2].fold<double>(0, (m, v) => v > m ? v : m);
    if (maxVal <= 2.0 && imageSize.width > 0 && imageSize.height > 0) {
      x1 *= imageSize.width;
      x2 *= imageSize.width;
      y1 *= imageSize.height;
      y2 *= imageSize.height;
    }

    final left = (x1 < x2 ? x1 : x2).clamp(0.0, imageSize.width);
    final top = (y1 < y2 ? y1 : y2).clamp(0.0, imageSize.height);
    final right = (x1 < x2 ? x2 : x1).clamp(0.0, imageSize.width);
    final bottom = (y1 < y2 ? y2 : y1).clamp(0.0, imageSize.height);

    final imgRect = Rect.fromLTRB(left, top, right, bottom);

    final fitted = applyBoxFit(fit, imageSize, containerSize);
    final sourceRect = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & imageSize,
    );
    final destRect = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & containerSize,
    );

    final sx = destRect.width / sourceRect.width;
    final sy = destRect.height / sourceRect.height;

    return Rect.fromLTRB(
      (imgRect.left - sourceRect.left) * sx + destRect.left,
      (imgRect.top - sourceRect.top) * sy + destRect.top,
      (imgRect.right - sourceRect.left) * sx + destRect.left,
      (imgRect.bottom - sourceRect.top) * sy + destRect.top,
    );
  }
}

class _HazardRectItem {
  final int index;
  final DetectedHazard hazard;
  final Rect rect;
  final double area;

  _HazardRectItem({
    required this.index,
    required this.hazard,
    required this.rect,
    required this.area,
  });
}

class _TapHintOverlay extends StatelessWidget {
  final String text;
  const _TapHintOverlay({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
        ],
      ),
    );
  }
}
