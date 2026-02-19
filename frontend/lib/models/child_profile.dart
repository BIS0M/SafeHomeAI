class Child {
  final String id;
  final String name;
  final String birthday;     // yyyy-MM-dd
  final String growthStage;

  Child({
    required this.id,
    required this.name,
    required this.birthday,
    required this.growthStage,
  });

  // ✅ [수정됨] JSON → Child (서버/로컬 호환)
  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      // id는 null일 경우 빈 문자열 처리
      id: json['id']?.toString() ?? '',
      
      // ✅ 핵심 수정: 서버의 'child_name'과 로컬의 'name'을 모두 확인합니다.
      name: json['child_name']?.toString() ?? json['name']?.toString() ?? '',
      
      birthday: json['birthday']?.toString() ?? '',
      
      // ✅ 핵심 수정: 서버의 'growth_stage'와 로컬의 'growthStage'를 모두 확인합니다.
      growthStage: json['growth_stage']?.toString() ?? json['growthStage']?.toString() ?? '',
    );
  }

  // ✅ Child → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // 로컬 저장 시에는 기존처럼 저장 (혹은 서버 형식에 맞춰 child_name으로 통일해도 됨)
      'name': name,
      'birthday': birthday,
      'growthStage': growthStage,
    };
  }
}