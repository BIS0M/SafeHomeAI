/// [Service] 로컬 데이터 저장 서비스
/// SharedPreferences를 사용하여 기기 내부에 검사 기록 등을 반영구적으로 저장하고
/// 앱 실행 시 다시 불러오는 물리적인 저장소 입출력을 담당합니다.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_record.dart';
import '../models/child_profile.dart';

class StorageService {
  // 저장소 키 (버전 관리를 위해 v1 붙임)
  static const String _prefsKeyHistory = 'safehome.history.v1';

  // ✅ 아이 프로필 저장 키
  static const String _prefsKeyChildren = 'safehome.children.v1';

  // -------------------------
  // [History]
  // -------------------------
  Future<List<ScanRecord>> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyHistory);
      if (raw == null || raw.trim().isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
              (m) => ScanRecord.fromJson(
                m.map((k, v) => MapEntry(k.toString(), v)),
              ),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveHistory(List<ScanRecord> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(history.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKeyHistory, raw);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyHistory);
  }

  // -------------------------
  // [Children]
  // -------------------------
  Future<void> saveChildren(List<Child> children) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(children.map((c) => c.toJson()).toList());
      await prefs.setString(_prefsKeyChildren, raw);
    } catch (_) {}
  }

  Future<List<Child>> loadChildren() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyChildren);
      if (raw == null || raw.trim().isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((m) => Child.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> clearChildren() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyChildren);
  }
}
