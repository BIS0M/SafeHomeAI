import 'package:flutter/foundation.dart';
import '../models/scan_record.dart';
import '../services/storage_service.dart';
import 'api_provider.dart';

class HistoryProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final ApiProvider api;

  List<ScanRecord> _history = [];
  bool _isLoading = false;
  bool _isLoaded = false;

  /// ✅ 현재 이 provider가 바라보는 "유저 키"
  /// - guest / member 섞임 방지용
  String? _activeUserKey;

  List<ScanRecord> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;

  HistoryProvider({required this.api}) {
    _init();
  }

  // ---------------------------------------------------------------------------
  // ✅ 내부 유틸
  // ---------------------------------------------------------------------------

  /// ✅ 유저별 캐시 키
  /// - email이 null이거나 빈 값이면 guest로 본다(원하면 guestId도 가능)
  String _userKeyOf(String? userId) {
    final u = (userId ?? '').trim().toLowerCase();
    if (u.isEmpty) return 'guest';
    return u;
  }

  void _sortHistory() {
    _history.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
  }

  /// 서버 + 로컬 병합(해결키만)
  /// - 기본: 서버 데이터가 기준
  /// - solvedHazardKeys는 "서버 값이 비어있으면 로컬 유지"
  /// - 서버에 없는 로컬 record는 유지(오프라인 생성/서버 동기화 전 대비)
  List<ScanRecord> _mergeRemoteAndLocal(
    List<ScanRecord> remote,
    List<ScanRecord> local,
  ) {
    final localMap = {for (final r in local) r.id: r};
    final remoteIds = remote.map((e) => e.id).toSet();

    final merged = <ScanRecord>[];

    for (final r in remote) {
      final l = localMap[r.id];
      if (l == null) {
        merged.add(r);
        continue;
      }

      final remoteSolved = r.solvedHazardKeys;
      final localSolved = l.solvedHazardKeys;

      final chosenSolved = remoteSolved.isNotEmpty ? remoteSolved : localSolved;

      merged.add(r.copyWith(solvedHazardKeys: List<String>.from(chosenSolved)));
    }

    // 서버에 없는 로컬도 유지
    for (final l in local) {
      if (!remoteIds.contains(l.id)) merged.add(l);
    }

    return merged;
  }

  // ---------------------------------------------------------------------------
  // ✅ 초기 로드
  // ---------------------------------------------------------------------------

  /// 앱 시작 시 로컬 캐시 먼저 로드 (단, "유저"가 아직 확정 전이면 guest 취급)
  Future<void> _init() async {
    // activeUserKey가 없으면 guest 캐시로 시작
    _activeUserKey ??= 'guest';

    final localData = await _storage.loadHistory();
    _history = localData;

    _sortHistory();
    _isLoaded = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // ✅ 핵심: 계정 전환/로그인/로그아웃 대응
  // ---------------------------------------------------------------------------

  /// ✅ 로그인/로그아웃/게스트 전환 시 반드시 호출
  /// - 유저가 바뀌면 메모리/로컬 캐시를 즉시 비움
  /// - 이후 fetchHistory로 서버 데이터를 다시 채우는 구조
  Future<void> setActiveUser(String? userId) async {
    final nextKey = _userKeyOf(userId);

    if (_activeUserKey == nextKey) return; // 동일 유저면 아무것도 안 함
    _activeUserKey = nextKey;

    // ✅ 1) 현재 메모리 비우기
    _history = [];
    _isLoaded = true;
    notifyListeners();

    // ✅ 2) 로컬 캐시도 비우기 (StorageService 수정 없이 전체 캐시 초기화)
    //    - "계정별 분리 저장"이 StorageService에 없다면, 최소한 섞임은 제거됨
    await _storage.clearHistory();
  }

  // ---------------------------------------------------------------------------
  // ✅ 서버 조회
  // ---------------------------------------------------------------------------

  Future<void> fetchHistory(String userId, String token) async {
    // ✅ fetchHistory가 호출되면 그 유저를 active로 본다
    final nextKey = _userKeyOf(userId);
    if (_activeUserKey != nextKey) {
      // 유저가 바뀌는 fetch라면 먼저 초기화
      await setActiveUser(userId);
    }

    _isLoading = true;
    notifyListeners();

    try {
      final remoteHistory = await api.getScanHistory(userId, token);

      // 서버 + 로컬 merge (해결키만 보호)
      _history = _mergeRemoteAndLocal(remoteHistory, _history);

      _sortHistory();
      await _storage.saveHistory(_history);
    } catch (e) {
      debugPrint("❌ [HistoryProvider] 서버 데이터 로드 실패: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // ✅ 로컬/메모리 업데이트
  // ---------------------------------------------------------------------------

  void addRecord(ScanRecord record) {
    final idx = _history.indexWhere((r) => r.id == record.id);
    if (idx == -1) {
      _history.insert(0, record);
    } else {
      _history[idx] = record;
    }
    _sortHistory();
    _storage.saveHistory(_history);
    notifyListeners();
  }

  Future<void> updateRecord(ScanRecord updated, {String? token}) async {
    final idx = _history.indexWhere((r) => r.id == updated.id);

    // 없으면 추가(HistoryScreen→Detail로 들어온 record가 provider에 없을 때)
    if (idx == -1) {
      _history.insert(0, updated);
    } else {
      _history[idx] = updated;
    }

    _sortHistory();
    await _storage.saveHistory(_history);
    notifyListeners();

    // 서버 동기화
    try {
      if (token != null && token.trim().isNotEmpty) {
        await api.updateSolvedHazardKeys(
          updated.id,
          updated.solvedHazardKeys,
          token,
        );
      }
    } catch (e) {
      debugPrint("❌ [HistoryProvider] solvedHazardKeys 서버 동기화 실패: $e");
    }
  }

  Future<void> updateSolvedKeys(
    String reportId,
    List<String> solvedKeys, {
    String? token,
  }) async {
    final idx = _history.indexWhere((r) => r.id == reportId);
    if (idx == -1) {
      debugPrint("⚠️ [HistoryProvider] updateSolvedKeys: record not found ($reportId)");
      return;
    }

    final current = _history[idx];
    await updateRecord(
      current.copyWith(solvedHazardKeys: List<String>.from(solvedKeys)),
      token: token,
    );
  }

  ScanRecord? findById(String reportId) {
    final idx = _history.indexWhere((r) => r.id == reportId);
    if (idx == -1) return null;
    return _history[idx];
  }

  // ---------------------------------------------------------------------------
  // ✅ 삭제
  // ---------------------------------------------------------------------------

  Future<void> deleteRecord(String reportId, String token) async {
    try {
      final success = await api.deleteScanRecord(reportId, token);
      if (success) {
        _history.removeWhere((r) => r.id == reportId);
        await _storage.saveHistory(_history);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ 삭제 실패: $e");
    }
  }

  Future<void> clearAllRecords(String userId, String token) async {
    try {
      final success = await api.deleteAllHistory(userId, token);
      if (success) {
        _history.clear();
        await _storage.clearHistory();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("❌ 전체 삭제 오류: $e");
    }
  }

  Future<ScanRecord?> loadSharedRecord(String recordId, String token) async {
    return await api.fetchScanRecord(recordId, token);
  }
}
