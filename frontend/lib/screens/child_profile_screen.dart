import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/child_profile.dart';
import '../providers/child_provider.dart';
import 'package:flutter/cupertino.dart';

class ChildProfileScreen extends StatefulWidget {
  /// true: ProfileScreen에서 "추가"로 들어왔을 때 (pop으로 Child 반환)
  /// false: 앱 처음 실행(온보딩) 등에서 들어왔을 때 (Provider에 저장 후 /main 이동)
  final bool returnResultToPrevious;

  const ChildProfileScreen({super.key, this.returnResultToPrevious = false});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedStage;
  bool _isRegistered = false;
  Child? _registeredChild;

  final List<String> _stages = [
    '누워있는 시기 (0~3개월)',
    '앉거나 기기 시작하는 시기 (4~6개월)',
    '보행기 및 탐색기 (7~12개월)',
    '혼자 걷기 시작하는 시기 (1~3세)',
    '활동 범위가 확대되는 시기(3~5세)',
    '독립성이 발달하는 시기 (5~9세)',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFormChanged);
    _dateController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    final birth = _parseBirthday();
    if (birth != null) {
      final autoStage = _stageFromBirth(birth);
      if (autoStage != null && autoStage != _selectedStage) {
        if (mounted) {
          setState(() {
            _selectedStage = autoStage;
          });
        }
        return;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _dateController.removeListener(_onFormChanged);
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _exitScreen() {
    if (widget.returnResultToPrevious &&
        _isRegistered &&
        _registeredChild != null) {
      Navigator.pop(context, _registeredChild);
      return;
    }
    Navigator.pop(context);
  }

  void _handleRegistration() {
    final name = _nameController.text.trim();
    final birthdayDate = _parseBirthday();
    final stage = _selectedStage;

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아이의 이름을 입력해주세요.')));
      return;
    }

    if (birthdayDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('생년월일을 선택해주세요.')));
      return;
    }

    if (stage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('발달 단계를 선택해주세요.')));
      return;
    }

    setState(() {
      _registeredChild = Child(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        birthday: _dateController.text,
        growthStage: stage,
      );
      _isRegistered = true;
    });
  }

  void _openStageBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 드래그 핸들
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EAF1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),

                // 타이틀
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFF2F6BFF),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '발달 단계 선택',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 리스트
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _stages.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF0F2F6)),
                    itemBuilder: (_, i) {
                      final s = _stages[i];
                      final selected = s == _selectedStage;

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() => _selectedStage = s);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                    color: selected
                                        ? const Color(0xFF2F6BFF)
                                        : const Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF2F6BFF)
                                        : const Color(0xFFD5DBE6),
                                    width: 2,
                                  ),
                                ),
                                child: selected
                                    ? const Center(
                                        child: Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Color(0xFF2F6BFF),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // 닫기 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F6FF),
                      foregroundColor: const Color(0xFF2F6BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _finish() async {
    if (_registeredChild == null) {
      if (!mounted) return;
      if (widget.returnResultToPrevious) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token != null) {
      await context.read<ChildProvider>().addChild(_registeredChild!, token);
    }

    if (widget.returnResultToPrevious) {
      if (!mounted) return;
      Navigator.pop(context, _registeredChild);
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/main');
  }

  void _handleSkip() {
    if (widget.returnResultToPrevious) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, '/main');
  }

  // ✅ [교체] 달력 대신 휠 피커를 띄우는 함수
  void _showWheelDatePicker() {
    // 1. 초기값 설정 (입력된 날짜가 있으면 그 날짜, 없으면 오늘)
    final initialDate = _parseBirthday() ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300, // 피커 높이
          child: Column(
            children: [
              // [취소 / 완료] 버튼 영역
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '취소',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2F6BFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 휠 피커 본체
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date, // 날짜 모드
                  initialDateTime: initialDate,
                  minimumDate: DateTime(2010), // 2010년생부터 (필요시 수정)
                  maximumDate: DateTime.now(), // 오늘 이후 선택 불가
                  dateOrder: DatePickerDateOrder.ymd, // 연-월-일 순서
                  onDateTimeChanged: (DateTime newDate) {
                    // 휠을 돌릴 때마다 텍스트 필드에 즉시 반영
                    // (initState에 등록된 리스너가 있어서 나이/단계도 자동 계산됨)
                    setState(() {
                      _dateController.text =
                          "${newDate.year}년 ${newDate.month}월 ${newDate.day}일";
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  DateTime? _parseBirthday() {
    final raw = _dateController.text.trim();
    final RegExp digitRegex = RegExp(r'\d+');
    final matches = digitRegex.allMatches(raw).map((m) => m.group(0)).toList();

    if (matches.length < 3) return null;

    try {
      return DateTime(
        int.parse(matches[0]!),
        int.parse(matches[1]!),
        int.parse(matches[2]!),
      );
    } catch (_) {
      return null;
    }
  }

  int? _calcFullMonths(DateTime birth) {
    final now = DateTime.now();
    if (birth.isAfter(now)) return null;

    int months = (now.year - birth.year) * 12 + (now.month - birth.month);
    if (now.day < birth.day) months -= 1;
    if (months < 0) months = 0;
    return months;
  }

  int? _calcManAgeYears(DateTime birth) {
    final months = _calcFullMonths(birth);
    if (months == null) return null;
    return months ~/ 12;
  }

  int? _calcKoreanAge(DateTime birth) {
    final now = DateTime.now();
    if (birth.isAfter(now)) return null;
    return now.year - birth.year + 1;
  }

  String? _stageFromBirth(DateTime birth) {
    final months = _calcFullMonths(birth);
    if (months == null) return null;

    if (months <= 3) return _stages[0];
    if (months <= 6) return _stages[1];
    if (months <= 12) return _stages[2];
    if (months <= 36) return _stages[3];
    if (months <= 60) return _stages[4];
    if (months <= 108) return _stages[5];
    return _stages[5];
  }

  Widget _buildStageInfoTooltip() {
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(left: 8),

      // ✅ 흰색 배경 + 파란 테두리
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2F6BFF), // 앱 메인 블루
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      // ✅ 글자 색: 검정(다크 그레이)
      textStyle: const TextStyle(
        color: Color(0xFF2C2C2C),
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),

      message:
          '아이의 현재 발달 단계에 따라\n'
          '위험 요소와 안전 가이드가 달라져요.\n'
          '가장 가까운 단계로 선택해 주세요.',

      // ✅ 동그라미 안 물음표 아이콘 유지
      child: const Icon(
        Icons.help_outline_rounded,
        size: 18,
        color: Color(0xFF2F6BFF),
      ),
    );
  }

  Widget _buildBottomRegisterButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F6BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: const Text(
              '등록 완료하기',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _exitScreen();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
              size: 20,
            ),
            onPressed: _exitScreen,
          ),
          title: Text(
            _isRegistered ? '등록 완료' : '프로필 등록',
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ) ??
                const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
          ),
          centerTitle: false,
        ),
        body: _isRegistered ? _buildSuccessView() : _buildFormView(),
        bottomNavigationBar: _isRegistered
            ? null
            : _buildBottomRegisterButton(),
      ),
    );
  }

  Widget _buildFormView() {
    final birth = _parseBirthday();
    final months = birth == null ? null : _calcFullMonths(birth);
    final manAge = birth == null ? null : _calcManAgeYears(birth);
    final korAge = birth == null ? null : _calcKoreanAge(birth);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.child_care,
                        size: 40,
                        color: Color(0xFF2F6BFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '아이 정보를 입력해주세요',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '정확한 월령별 안전 가이드를 위해\n생년월일과 발달 단계가 필요해요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '아이의 이름 (애칭)', // 각 제목에 맞게 텍스트 내용은 유지하세요 ('아이의 생년월일', '발달 단계')
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800, // ✅ w800 -> w600 (SemiBold)으로 완화
                color: const Color(0xFF1A1A1A), // ✅ AppTheme.gray900 색상 적용
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _nameController,
              hint: '예: 안전이, 튼튼이',
              icon: Icons.face,
            ),
            const SizedBox(height: 22),
            const Text(
              '아이의 생년월일',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 10),
            _buildDateField(),
            const SizedBox(height: 22),
            Row(
              children: [
                const Text(
                  '발달 단계',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
                const SizedBox(width: 6),
                _buildStageInfoTooltip(),
              ],
            ),
            const SizedBox(height: 10),
            _buildStageDropdown(),
            const SizedBox(height: 18),
            // ✅ 원래(화이트) 디자인 리포트 + 멘트 삭제
            _buildSummaryCard(months: months, manAge: manAge, korAge: korAge),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: TextField(
        controller: controller,

        // ✅ [수정] 입력 글자: 힌트와 같은 크기(bodyMedium) 적용
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF1A1A1A),
          fontWeight: FontWeight.w500, // 두께는 입력값이니 살짝(w500) 줍니다
        ),

        decoration: InputDecoration(
          hintText: hint,

          // ✅ [수정] 힌트 글자: 입력 글자와 같은 크기(bodyMedium) 적용
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF9CA3AF)),

          border: InputBorder.none,
          isDense: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, color: Colors.grey.shade400),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: TextField(
        controller: _dateController,
        readOnly: true,
        onTap: _showWheelDatePicker,

        // ✅ [수정] 날짜 글자: 힌트와 같은 크기 적용
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF1A1A1A),
          fontWeight: FontWeight.w500,
        ),

        decoration: InputDecoration(
          hintText: '생년월일을 선택해주세요',

          // ✅ [수정] 힌트 글자: 날짜 글자와 같은 크기 적용
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF9CA3AF)),

          border: InputBorder.none,
          prefixIcon: Icon(Icons.cake, color: Colors.grey.shade400),
          suffixIcon: const Icon(
            Icons.calendar_month,
            color: Color(0xFF2F6BFF),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStageDropdown() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _openStageBottomSheet,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECF3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedStage ?? '현재 아이의 발달 단계를 선택해주세요',
                style: (_selectedStage == null)
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF9CA3AF), // 힌트 색상 (연한 회색)
                      )
                    : Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            FontWeight.w500, // ✅ w800 -> w500 (AppTheme 기본)
                        color: const Color(0xFF1A1A1A), // ✅ AppTheme.gray900
                      ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 원래(화이트 카드 + 헤더) 디자인으로 복귀
  // ✅ '발달 단계~' 안내 멘트 삭제
  // ✅ '만 나이', '한국 나이' 라벨은 TextTheme로 한 단계 작게
  Widget _buildSummaryCard({int? months, int? manAge, int? korAge}) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Colors.grey.shade500,
      fontWeight: FontWeight.w700,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A68FF).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더(원래 스타일)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F6FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: const [
                Icon(Icons.stars_rounded, color: Color(0xFF1A68FF), size: 18),
                SizedBox(width: 8),
                Text(
                  '현재 아이 상태 리포트',
                  style: TextStyle(
                    color: Color(0xFF1A68FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // 내용
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('만 나이', style: labelStyle),
                      const SizedBox(height: 10),
                      Text(
                        months == null ? '-' : '${manAge ?? 0}세 ($months개월)',
                        style: const TextStyle(
                          color: Color(0xFF1A68FF),
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: const Color(0xFFE6EAF1)),
                Expanded(
                  child: Column(
                    children: [
                      Text('한국 나이', style: labelStyle),
                      const SizedBox(height: 10),
                      Text(
                        korAge == null ? '-' : '${korAge}세',
                        style: const TextStyle(
                          color: Color(0xFF2C2C2C),
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: const Color(0xFF2F6BFF).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2F6BFF),
                size: 44,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              '프로필 등록이 완료됐어요!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '이제 아이 발달 단계에 맞는\n안전 가이드를 받을 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
