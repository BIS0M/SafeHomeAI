import 'dart:convert'; // ✅ jsonDecode, utf8를 위해 필요
import 'package:flutter/foundation.dart'; // ✅ debugPrint, ChangeNotifier를 위해 필요
import 'package:http/http.dart' as http; // ✅ http를 위해 필요

import '../models/child_profile.dart';
import '../services/storage_service.dart';
import 'api_provider.dart';

class ChildProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final ApiProvider api;

  List<Child> _children = [];
  bool _isLoaded = false;

  // ✅ [추가 1] 현재 선택된 아이를 저장할 변수 (초기값은 null)
  Child? _selectedChild;

  List<Child> get children => List.unmodifiable(_children);
  bool get isLoaded => _isLoaded;

  Child? get selectedChild => _selectedChild;

  ChildProvider({required this.api}) {
    loadChildren();
  }

  // ✅ [추가 3] 아이를 선택하는 함수
  void selectChild(Child? child) {
    _selectedChild = child;
    notifyListeners(); // 화면 갱신 알림
  }

  Future<void> loadChildren() async {
    final loaded = await _storage.loadChildren();
    _children = loaded;
    _isLoaded = true;
    notifyListeners();
  }

  // ✅ [수정] 서버 동기화 로직
  Future<void> fetchChildrenFromServer(String token) async {
    try {
      // api 객체를 통해 서버 데이터를 가져옵니다.
      final List<dynamic> serverData = await api.getChildProfiles(token);
      
      final List<Child> remoteChildren = serverData
          .map((json) => Child.fromJson(json))
          .toList();

      _children = remoteChildren;
      await _storage.saveChildren(_children);
      
      notifyListeners(); 
      debugPrint("✅ 아이 프로필 동기화 완료: ${_children.length}명");
    } catch (e) {
      debugPrint("❌ 아이 프로필 동기화 실패: $e");
    }
  }

  Future<void> addChild(Child child, String token) async {
    final success = await api.createChildProfile(
      childName: child.name,
      birthday: child.birthday,
      growthStage: child.growthStage,
      token: token,
    );

    if (success) {
      await fetchChildrenFromServer(token); 
    }
  }

  /// ✅ 삭제 기능: 서버에서 지우고 -> 성공하면 앱 목록에서도 지움
  Future<void> removeChild(String childId, String token) async {
    // 1. 서버에 삭제 요청
    final success = await api.deleteChildProfile(childId, token);
    
    if (success) {
      // 2. 서버 삭제 성공 시, 로컬 리스트에서 제거
      _children.removeWhere((c) => c.id == childId);
      if (_selectedChild?.id == childId) {
        _selectedChild = null;
        // 남은 아이가 있으면 첫번째로 재설정 (UX 옵션)
        if (_children.isNotEmpty) _selectedChild = _children.first;
      }
      // 3. 변경된 리스트를 로컬 저장소에도 반영 (앱 껐다 켜도 유지되도록)
      await _storage.saveChildren(_children);
      
      notifyListeners(); // 화면 갱신
    }
  }
  
}