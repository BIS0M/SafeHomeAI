import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/analysis_result.dart';
import '../../../models/scan_record.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/scan_provider.dart';
import '../../../providers/ui_provider.dart';
import '../../../theme/app_theme.dart';

import '../../../widgets/solution/resolved_check_card.dart';
import '../../../widgets/solution/risk_header_card.dart';
import '../../../widgets/solution/action_list_card.dart';
import '../../../widgets/solution/product_recommendation_card.dart';

import '../../../providers/auth_provider.dart';

class SolutionDetailScreen extends StatefulWidget {
  final ScanRecord record;
  final DetectedHazard hazard;
  final int? index;

  const SolutionDetailScreen({
    super.key,
    required this.record,
    required this.hazard,
    this.index,
  });

  @override
  State<SolutionDetailScreen> createState() => _SolutionDetailScreenState();
}

class _SolutionDetailScreenState extends State<SolutionDetailScreen> {
  late bool _resolved;
  late List<String> _solvedKeys;

  @override
  void initState() {
    super.initState();
    _solvedKeys = List<String>.from(widget.record.solvedHazardKeys);
    _resolved = _solvedKeys.contains(widget.hazard.hazardKey);
  }

  Future<void> _onChanged(bool v) async {
    setState(() => _resolved = v);

    final history = context.read<HistoryProvider>();
    final scan = context.read<ScanProvider>();
    final auth = context.read<AuthProvider>();

    // ✅ 최신 record(히스토리 provider 기준)로 solvedKeys 기준 잡기
    final latestRecord = history.findById(widget.record.id) ?? widget.record;
    _solvedKeys = List<String>.from(latestRecord.solvedHazardKeys);

    final key = widget.hazard.hazardKey;

    if (v) {
      if (!_solvedKeys.contains(key)) _solvedKeys.add(key);
    } else {
      _solvedKeys.remove(key);
    }

    // ✅ token nullable 방어
    final String? token = auth.token;
    final String? safeToken =
        (token != null && token.trim().isNotEmpty) ? token : null;

    // ✅ 1) History(로컬 + 서버 PATCH) 업데이트
    await history.updateSolvedKeys(
      widget.record.id,
      List<String>.from(_solvedKeys),
      token: safeToken,
    );

    // ✅ 2) 현재 분석 화면도 즉시 반영
    scan.applySolvedKeys(widget.record.id, List<String>.from(_solvedKeys));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<UiProvider>();

    final risk = widget.hazard;
    final baseTheme = Theme.of(context);
    final textTheme = baseTheme.textTheme;

    final smallTextTheme = textTheme.copyWith(
      bodyLarge: textTheme.bodySmall,
      bodyMedium: textTheme.bodySmall,
      bodySmall: textTheme.labelSmall ?? textTheme.bodySmall,
      titleLarge: textTheme.titleSmall,
      titleMedium: textTheme.titleSmall,
    );

    final smallCheckboxTheme = CheckboxThemeData(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('해결 방법', style: TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Theme(
                data: baseTheme.copyWith(
                  textTheme: smallTextTheme,
                  checkboxTheme: smallCheckboxTheme,
                ),
                child: ResolvedCheckCard(
                  value: _resolved,
                  onChanged: (v) => _onChanged(v),
                ),
              ),
              const SizedBox(height: 12),
              Theme(
                data: baseTheme.copyWith(textTheme: smallTextTheme),
                child: RiskHeaderCard(
                  risk: risk.toRiskItem(),
                  index: widget.index,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '왜 위험한가요?',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    risk.reason,
                    style: textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Theme(
                data: baseTheme.copyWith(textTheme: smallTextTheme),
                child: ActionListCard(actionPlan: risk.actionPlan),
              ),
              const SizedBox(height: 18),
              ProductRecommendationCard(recommendations: risk.recommendations),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
