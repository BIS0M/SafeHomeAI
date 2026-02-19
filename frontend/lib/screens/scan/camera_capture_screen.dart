import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// [연결] 상대 경로 수정: lib/screens 에서 lib/widgets/scan 으로 가는 경로
import '../../widgets/scan/camera_shutter_button.dart';
import 'photo_confirm_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  // [복구] 빠졌던 카메라 제어 변수들
  CameraController? _controller;
  bool _initializing = true;
  bool _taking = false;
  Object? _initError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // [복구] 카메라 초기화 로직
  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('No cameras');

      final back = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      final cam = back.isNotEmpty ? back.first : cameras.first;

      final ctrl = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await ctrl.initialize();

      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _controller = ctrl;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e;
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // [복구] 사진 촬영 로직
  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _taking) return;

    setState(() => _taking = true);
    try {
      final x = await ctrl.takePicture();
      if (!mounted) return;

      // ✅ 확인 화면에서 촬영한 XFile을 그대로 돌려받습니다.
      final confirmed = await Navigator.of(context).push<XFile?>(
        MaterialPageRoute(builder: (_) => PhotoConfirmScreen(xfile: x)),
      );

      if (mounted && confirmed != null) {
        Navigator.of(context).pop<XFile>(confirmed);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _taking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 카메라 미리보기 영역
            Positioned.fill(
              child: _initializing
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPreview(ctrl),
            ),
            // 상단 닫기 버튼
            Positioned(
              left: 12,
              top: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // [연결 핵심] 쪼개놓은 촬영 버튼 사용
            if (!_initializing &&
                _initError == null &&
                ctrl != null &&
                ctrl.value.isInitialized)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: CameraShutterButton(isTaking: _taking, onTap: _capture),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(CameraController? ctrl) {
    if (_initError != null || ctrl == null || !ctrl.value.isInitialized) {
      return const Center(
        child: Text('카메라 에러', style: TextStyle(color: Colors.white)),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: ctrl.value.previewSize?.height ?? 1,
        height: ctrl.value.previewSize?.width ?? 1,
        child: CameraPreview(ctrl),
      ),
    );
  }
}
