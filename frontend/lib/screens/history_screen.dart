import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/history_provider.dart';
import '../providers/ui_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/child_provider.dart';
import '../providers/scan_provider.dart'; // ✅ 추가: ScanProvider 재주입용
import '../theme/app_theme.dart';
import '../widgets/history/history_filter_row.dart';
import '../widgets/history/history_record_card.dart';
import 'scan/analysis_result_screen.dart';
import '../models/scan_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _filterIndex = 0;
  bool _isAscending = false;

  String? _selectedRoom;
  String? _selectedChildId;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;

  static const int _allFilterIndex = 0;
  static const int _spaceFilterIndex = 1;
  static const int _childFilterIndex = 2;
  static const int _dateFilterIndex = 3;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn && auth.email != null && auth.token != null) {
        context.read<HistoryProvider>().fetchHistory(auth.email!, auth.token!);
        context.read<ChildProvider>().fetchChildrenFromServer(auth.token!);
      }
    });
  }

  String _formatYMD(DateTime d) {
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: AppTheme.lightTheme, child: child!);
      },
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: AppTheme.lightTheme, child: child!);
      },
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _applyDateFilter() {
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
    });
  }

  void _resetDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _appliedStartDate = null;
      _appliedEndDate = null;
    });
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '전체 삭제',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('저장된 모든 검사 기록을 삭제할까요?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final auth = context.read<AuthProvider>();
              context.read<HistoryProvider>().clearAllRecords(auth.email!, auth.token!);
              Navigator.pop(ctx);
            },
            child: const Text('전체 삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final childProvider = context.watch<ChildProvider>();
    final ui = context.read<UiProvider>();

    final records = historyProvider.history;
    final children = childProvider.children;
    final rooms = records.map((r) => r.room).toSet().toList()..sort();

    final bool isSpaceFilter = _filterIndex == _spaceFilterIndex;
    final bool isChildFilter = _filterIndex == _childFilterIndex;
    final bool isDateFilter = _filterIndex == _dateFilterIndex;

    List<ScanRecord> filteredRecords = records.where((r) {
      if (_filterIndex == _allFilterIndex) return true;
      if (isSpaceFilter && _selectedRoom != null) {
        if (r.room != _selectedRoom) return false;
      }
      if (isChildFilter && _selectedChildId != null) {
        if (r.childId != _selectedChildId) return false;
      }
      if (isDateFilter && _appliedStartDate != null && _appliedEndDate != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAtMillis);
        final start = DateTime(_appliedStartDate!.year, _appliedStartDate!.month, _appliedStartDate!.day);
        final end = DateTime(_appliedEndDate!.year, _appliedEndDate!.month, _appliedEndDate!.day, 23, 59, 59);
        if (dt.isBefore(start) || dt.isAfter(end)) return false;
      }
      return true;
    }).toList();

    filteredRecords.sort((a, b) {
      final cmp = a.createdAtMillis.compareTo(b.createdAtMillis);
      return _isAscending ? cmp : -cmp;
    });

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => ui.setTabIndex(0),
        ),
        title: const Text(
          '저장된 기록',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1) 필터 버튼 Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: HistoryFilterRow(
                      selectedIndex: _filterIndex,
                      onChanged: (i) => setState(() {
                        _filterIndex = i;
                        if (i != _spaceFilterIndex) _selectedRoom = null;
                        if (i != _childFilterIndex) _selectedChildId = null;
                        if (i != _dateFilterIndex) _resetDateFilter();
                      }),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'sort') {
                        setState(() => _isAscending = !_isAscending);
                      } else if (value == 'clear') {
                        _showClearAllDialog();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'sort',
                        child: Text(_isAscending ? '최신순 정렬' : '과거순 정렬'),
                      ),
                      const PopupMenuItem(
                        value: 'clear',
                        child: Text('전체 삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2-A) 공간 필터
            if (isSpaceFilter && rooms.isNotEmpty)
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      label: const Text('전체'),
                      selected: _selectedRoom == null,
                      onSelected: (_) => setState(() => _selectedRoom = null),
                      showCheckmark: false,
                      avatar: (_selectedRoom == null)
                          ? Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                            )
                          : null,
                      selectedColor: AppTheme.primary.withOpacity(0.10),
                      backgroundColor: Colors.white,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: _selectedRoom == null ? AppTheme.primary : Colors.grey.shade300,
                          width: _selectedRoom == null ? 1.2 : 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      labelStyle: TextStyle(
                        color: _selectedRoom == null ? AppTheme.primary : Colors.black87,
                        fontWeight: _selectedRoom == null ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...rooms.map(
                      (room) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(room),
                          selected: _selectedRoom == room,
                          onSelected: (_) => setState(() => _selectedRoom = room),
                          showCheckmark: false,
                          avatar: (_selectedRoom == room)
                              ? Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.check, size: 12, color: Colors.white),
                                  ),
                                )
                              : null,
                          selectedColor: AppTheme.primary.withOpacity(0.10),
                          backgroundColor: Colors.white,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: _selectedRoom == room ? AppTheme.primary : Colors.grey.shade300,
                              width: _selectedRoom == room ? 1.2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          labelStyle: TextStyle(
                            color: _selectedRoom == room ? AppTheme.primary : Colors.black87,
                            fontWeight: _selectedRoom == room ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 2-B) 아이별 필터
            if (isChildFilter)
              Container(
                height: 69,
                padding: const EdgeInsets.only(top: 8, bottom: 0),
                child: children.isEmpty
                    ? const Center(
                        child: Text("등록된 아이가 없습니다.", style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: children.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 20),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildProfileItem(
                              name: "전체",
                              isSelected: _selectedChildId == null,
                              onTap: () => setState(() => _selectedChildId = null),
                              isAll: true,
                            );
                          }
                          final child = children[index - 1];
                          return _buildProfileItem(
                            name: child.name,
                            isSelected: _selectedChildId == child.id,
                            onTap: () => setState(() => _selectedChildId = child.id),
                            isAll: false,
                          );
                        },
                      ),
              ),

            // 2-C) 날짜 필터
            if (isDateFilter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            text: _startDate == null ? '시작일' : _formatYMD(_startDate!),
                            onTap: _pickStartDate,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('~'),
                        ),
                        Expanded(
                          child: _DateField(
                            text: _endDate == null ? '종료일' : _formatYMD(_endDate!),
                            onTap: _pickEndDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (_startDate != null && _endDate != null) ? _applyDateFilter : null,
                            child: const Text('적용'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetDateFilter,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('초기화', style: TextStyle(color: Colors.black87)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 3) 기록 리스트
            Expanded(
              child: historyProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredRecords.isEmpty
                      ? Center(
                          child: Text(
                            isChildFilter && _selectedChildId != null ? '이 아이의 기록이 없습니다.' : '해당하는 기록이 없습니다',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: filteredRecords.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 5),
                          itemBuilder: (context, index) {
                            final ScanRecord record = filteredRecords[index];

                            return Dismissible(
                              key: Key(record.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightTheme.colorScheme.error,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 28),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('기록 삭제'),
                                    content: const Text('이 기록을 영구적으로 삭제할까요?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) {
                                final auth = context.read<AuthProvider>();
                                context.read<HistoryProvider>().deleteRecord(record.id, auth.token!);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${record.room} 기록 삭제됨')));
                              },

                              // ✅✅✅ 여기만 핵심 수정 (Provider 재주입 + 탭 100% 보장)
                              child: Builder(
                                builder: (innerCtx) {
                                  return HistoryRecordCard(
                                    record: record,
                                    onTap: () {
                                      Navigator.of(innerCtx).push(
                                        MaterialPageRoute(
                                          builder: (_) => MultiProvider(
                                            providers: [
                                              ChangeNotifierProvider.value(value: innerCtx.read<HistoryProvider>()),
                                              ChangeNotifierProvider.value(value: innerCtx.read<ScanProvider>()),
                                              ChangeNotifierProvider.value(value: innerCtx.read<UiProvider>()),
                                            ],
                                            child: AnalysisResultScreen(historyRecord: record),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isAll,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              isAll ? Icons.people_alt_rounded : Icons.face,
              color: isSelected ? AppTheme.primary : Colors.grey.shade400,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primary : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _DateField({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
