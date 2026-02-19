import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recommended_product.dart';
import '../models/analysis_result.dart';
import '../models/scan_record.dart';
import '../providers/history_provider.dart';
import 'api_provider.dart';
import 'package:flutter/widgets.dart';

class ScanProvider extends ChangeNotifier {
  final ApiProvider api;

  ScanProvider({required this.api});

  String? _selectedRoom;
  ScanRecord? _currentAnalysisRecord;

  // 위험요소 + bbox
  List<DetectedHazard> _hazards = [];

  // 추천상품
  List<RecommendedProduct> _recommendations = [];

  String? _resultImageUrl;
  bool _isAnalyzing = false;
  String? _error;

  String? get selectedRoom => _selectedRoom;
  ScanRecord? get currentAnalysisRecord => _currentAnalysisRecord;
  List<DetectedHazard> get hazards => _hazards;
  List<RecommendedProduct> get recommendations => _recommendations;
  String? get resultImageUrl => _resultImageUrl;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;

  void selectRoom(String room) {
    _selectedRoom = room;
    notifyListeners();
  }

  void clearCurrentResult() {
    _currentAnalysisRecord = null;
    _resultImageUrl = null;
    _hazards = [];
    _recommendations = [];
    _error = null;
    _isAnalyzing = false;
    notifyListeners();
  }

  /// ✅ SolutionDetailScreen에서 체크 토글 시, 분석/히스토리 화면이 즉시 갱신되도록
  /// - record에 solvedHazardKeys가 존재하고 copyWith가 구현돼 있다는 전제입니다.
  void applySolvedKeys(String reportId, List<String> solvedKeys) {
    if (_currentAnalysisRecord != null &&
        _currentAnalysisRecord!.id == reportId) {
      _currentAnalysisRecord = _currentAnalysisRecord!.copyWith(
        solvedHazardKeys: List<String>.from(solvedKeys),
      );
      notifyListeners();
    }
  }

  /// ✅ (핵심 유지) image_picker의 XFile로 분석 실행
  Future<void> runAnalysisFromXFile(
    XFile xfile, {
    required String userId,
    required String token,
    HistoryProvider? historyProvider,
    String? childId,
    String growthStage = "walking",
  }) async {
    if (_selectedRoom == null) {
      _error = "방 정보를 선택해주세요.";
      notifyListeners();
      return;
    }

    _isAnalyzing = true;
    _error = null;
    _currentAnalysisRecord = null;
    notifyListeners();

    try {
      final bytes = await xfile.readAsBytes();

      // 1) API 호출
      final result = await api.analyzePhoto(
        imageBytes: bytes,
        userId: userId,
        spaceType: _selectedRoom!,
        growthStage: growthStage,
        childId: childId,
        token: token,
      );

      // 2) 결과 반영
      _resultImageUrl = result.resultImageUrl;
      _hazards = result.hazards;
      _recommendations = result.recommendations;

      // 3) 날짜 라벨 생성
      final now = result.createdAt?.toLocal() ?? DateTime.now();
      final dateLabel =
          '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

      // 4) ScanRecord 생성
      final record = ScanRecord(
        id: result.reportId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        room: _selectedRoom!,
        dateLabel: dateLabel,
        risksFound: _hazards.length,
        shortSummary: _hazards.isNotEmpty
            ? '위험 요소 ${_hazards.length}개 발견'
            : '감지된 위험 요소 없음',
        createdAtMillis: now.millisecondsSinceEpoch,
        imageUrl: _resultImageUrl ?? '',
        hazards: _hazards,
        childId: childId,
        // ✅ 모델에 필드가 있다면 기본값 유지(없으면 이 줄 삭제)
        solvedHazardKeys: const [],
      );

      _currentAnalysisRecord = record;

      // 5) 히스토리에 즉시 추가
      if (historyProvider != null) {
        // ✅ 빌드가 끝난 후 데이터를 추가하도록 예약합니다.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          historyProvider.addRecord(record);
        });
      }
    } catch (e) {
      _error = "분석 중 오류가 발생했습니다: $e";
      debugPrint("❌ [ScanProvider] 분석 에러: $e");
    } finally {
      // ✅ 로딩 상태를 끄고 화면을 새로고침하는 작업을 안전하게 예약합니다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isAnalyzing = false;
        notifyListeners();
      });
    }
  }

  /// ✅ (기존 유지) 파일 경로 기반 래퍼
  Future<ScanRecord?> runRealAnalysis(
    String filePath, {
    required String userId,
    required String token,
    HistoryProvider? historyProvider,
  }) async {
    await runAnalysisFromXFile(
      XFile(filePath),
      userId: userId,
      token: token,
      historyProvider: historyProvider,
    );
    return _currentAnalysisRecord;
  }
}
