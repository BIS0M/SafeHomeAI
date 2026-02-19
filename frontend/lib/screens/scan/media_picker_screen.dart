/// [Screen] 미디어 선택 및 관리 화면
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../providers/scan_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';

// [연결] 쪼개놓은 부품들
import '../../../widgets/scan/media_picker_empty_state.dart';
import '../../../widgets/scan/selected_grid.dart';

// [연결] 화면들
import 'camera_capture_screen.dart';
import 'photo_confirm_screen.dart';

class MediaPickerScreen extends StatefulWidget {
  final String room;
  const MediaPickerScreen({super.key, required this.room});

  @override
  State<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends State<MediaPickerScreen> {
  final _picker = ImagePicker();

  // ✅ 단일 선택(0~1개)
  final List<XFile> _selected = [];

  // ✅ 갤러리에서 불러온 목록(미선택 상태로만 추가)
  final List<XFile> _galleryItems = [];

  bool _openedOnce = false;
  bool _busy = false;

  // ✅ 샘플 선택 상태(단일 선택)
  String? _selectedSampleAsset;

  // ✅ 샘플 이미지(최근 항목에 노출할 assets)
  final List<String> _sampleAssets = const [
    'assets/sample/sample_1.png',
    'assets/sample/sample_2.png',
    'assets/sample/sample_3.png',
    'assets/sample/sample_4.jpg',
  ];

  // assets → XFile 변환 캐시
  final Map<String, XFile> _assetCache = {};

  @override
  void initState() {
    super.initState();
    _openedOnce = true;
  }

  // ✅ 샘플 선택/해제 (샘플 선택 시 갤러리 선택 해제)
  Future<void> _toggleSampleSelect(String assetPath) async {
    if (_selectedSampleAsset == assetPath) {
      setState(() => _selectedSampleAsset = null);
      return;
    }

    setState(() {
      _selected.clear(); // 갤러리/카메라 선택 해제
      _selectedSampleAsset = assetPath;
    });

    // 완료 시 빠르게 쓰려고 캐시만 준비
    try {
      _assetCache[assetPath] ??= await _assetToXFile(assetPath);
    } catch (_) {}
  }

  // ✅ 갤러리 목록에서 탭으로 선택/해제 (단일 선택)
  void _toggleGallerySelect(XFile f) {
    // 이미 선택된 항목이면 해제
    if (_selected.isNotEmpty && _selected.first.path == f.path) {
      setState(() => _selected.clear());
      return;
    }

    setState(() {
      _selectedSampleAsset = null; // 샘플 선택 해제
      _selected
        ..clear()
        ..add(f);
    });
  }

  // ✅ assets → XFile (웹/모바일 모두)
  Future<XFile> _assetToXFile(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    final filename = assetPath.split('/').last;
    final ext = filename.split('.').last.toLowerCase();
    final mime = ext == 'png'
        ? 'image/png'
        : (ext == 'jpg' || ext == 'jpeg')
            ? 'image/jpeg'
            : 'application/octet-stream';

    return XFile.fromData(bytes, name: filename, mimeType: mime);
  }

  // ✅ 갤러리 열기: "불러온 사진"은 _galleryItems에만 추가(미선택)
  Future<void> _pickFromGallery({bool auto = false}) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final files = await _picker.pickMultiImage();
      if (!mounted) return;

      if (files.isNotEmpty) {
        setState(() {
          // ✅ 자동 선택 방지: 불러온 건 목록에만 추가
          final existing = _galleryItems.map((e) => e.path).toSet();
          for (final f in files) {
            if (!existing.contains(f.path)) _galleryItems.add(f);
          }

          // ✅ "불러온 순간 미선택"을 확실히 하기 위해 선택 초기화
          _selected.clear();
          _selectedSampleAsset = null;
        });
      } else if (auto) {
        setState(() => _openedOnce = true);
      }
    } catch (_) {
      if (auto) setState(() => _openedOnce = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ✅ 카메라 촬영: 촬영한 사진은 목록에 추가 + 그 사진을 선택(단일 선택)
  Future<void> _takePhoto() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      try {
        final x = await Navigator.of(context).push<XFile?>(
          MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
        );

        if (mounted && x != null) {
          setState(() {
            _selectedSampleAsset = null;

            if (!_galleryItems.any((e) => e.path == x.path)) _galleryItems.add(x);

            _selected
              ..clear()
              ..add(x);
          });
        }
        return;
      } catch (_) {}

      final x = await _picker.pickImage(source: ImageSource.camera);
      if (!mounted || x == null) return;

      // ✅ 확인 화면에서 촬영한 XFile을 그대로 돌려받습니다.
      final confirmed = await Navigator.of(context).push<XFile?>(
        MaterialPageRoute(builder: (_) => PhotoConfirmScreen(xfile: x)),
      );

      if (mounted && confirmed != null) {
        setState(() {
          _selectedSampleAsset = null;

          if (!_galleryItems.any((e) => e.path == confirmed.path)) {
            _galleryItems.add(confirmed);
          }

          _selected
            ..clear()
            ..add(confirmed);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ✅ 완료: (샘플 1개 선택) or (갤러리 1개 선택)일 때만 pop
  Future<void> _startAnalysis() async {
    final auth = context.read<AuthProvider>();

    if (!auth.isLoggedIn || auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 정보가 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

    // 선택 없음
    if (_selectedSampleAsset == null && _selected.isEmpty) return;

    // 샘플 선택 우선
    if (_selectedSampleAsset != null) {
      final path = _selectedSampleAsset!;
      final x = _assetCache[path] ?? await _assetToXFile(path);
      _assetCache[path] = x;
      Navigator.of(context).pop(x);
      return;
    }

    // 갤러리 선택
    Navigator.of(context).pop(_selected.first);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 단일 선택 조건: 샘플 1개 XOR 갤러리 1개
    final canDone = ((_selectedSampleAsset != null) ^ (_selected.length == 1)) && !_busy;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _busy ? null : () => _pickFromGallery(),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('갤러리', style: TextStyle(fontWeight: FontWeight.w900)),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: canDone ? _startAnalysis : null,
            child: const Text('완료', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
      body: SafeArea(
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : SelectedGrid(
                // ✅ 선택된 1장(0~1)
                files: _selected,
                // ✅ 목록(미선택 포함)
                galleryItems: _galleryItems,
                // ✅ 선택된 갤러리 항목(0~1)
                selectedGalleryItem: _selected.isNotEmpty ? _selected.first : null,
                // ✅ 탭으로 선택/해제
                onTapGallery: _toggleGallerySelect,

                // ✅ 샘플
                sampleAssets: _sampleAssets,
                onTapSample: _toggleSampleSelect,
                selectedSampleAsset: _selectedSampleAsset,

                // ✅ 카메라
                onAddCamera: _takePhoto,
              ),
      ),
    );
  }
}
