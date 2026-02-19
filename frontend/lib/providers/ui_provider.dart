/// [Provider] 화면 UI 상태 관리 담당자
/// 메인 화면의 하단 탭 인덱스 관리 및 화면 간에 공유해야 할 일시적인 UI 상태들
/// (예: 상세 화면에서 보여줄 특정 위험 요소 선택 등)을 전역적으로 관리합니다.
import 'package:flutter/foundation.dart';
import '../models/risk_item.dart';

class UiProvider extends ChangeNotifier {
  int _tabIndex = 0; //
  RiskItem? _selectedRisk; //

  // ✅ [추가] 분석 진행 상태 관리 변수
  bool _isAnalysisInProgress = false;
  bool get isAnalysisInProgress => _isAnalysisInProgress;

  void setAnalysisInProgress(bool value) {
    _isAnalysisInProgress = value;
    notifyListeners();
  }

  // [추가] 1. 새로고침 신호 감지용 변수
  int _refreshCount = 0;
  int get refreshCount => _refreshCount;
  void triggerRefresh() {
    //
    _refreshCount++;
    notifyListeners();
  }

  int get tabIndex => _tabIndex;
  int get selectedIndex => _tabIndex;
  RiskItem? get selectedRisk => _selectedRisk;

  // [수정] 탭 변경 함수 (핵심 로직 변경!)
  void setTabIndex(int index) {
    if (_tabIndex == index) {
      // ✅ 같은 탭을 또 눌렀다면? -> "신호 보내라!" (Pop to Root 실행됨)
      triggerRefresh();
    } else {
      // ✅ 다른 탭을 눌렀다면? -> 탭만 변경
      _tabIndex = index;
      notifyListeners();
    }
  }

  void openRisk(RiskItem risk) {
    //
    _selectedRisk = risk;
    notifyListeners();
  }

  void clearSelectedRisk() {
    //
    _selectedRisk = null;
    notifyListeners();
  }
}
