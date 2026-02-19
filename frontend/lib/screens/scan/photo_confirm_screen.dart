/// [Screen] 촬영 사진 확인 화면
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/scan_provider.dart';
import '../../providers/auth_provider.dart';    // ✅ 추가: 신분증(토큰)을 꺼내기 위해
import '../../providers/history_provider.dart'; // ✅ 추가: 분석 후 목록 업데이트를 위해
import '../../providers/child_provider.dart';  // ✅ 추가: 선택된 아이 정보 가져오기

import '../../theme/app_theme.dart';
import 'analysis_result_screen.dart';

class PhotoConfirmScreen extends StatefulWidget {
  final XFile xfile;
  const PhotoConfirmScreen({super.key, required this.xfile});

  @override
  State<PhotoConfirmScreen> createState() => _PhotoConfirmScreenState();
}

class _PhotoConfirmScreenState extends State<PhotoConfirmScreen> {
  bool _loading = false;

  Widget _image() {
    if (kIsWeb) return Image.network(widget.xfile.path, fit: BoxFit.contain);
    return Image.file(File(widget.xfile.path), fit: BoxFit.contain);
  }

  Future<void> _usePhoto() async {
    // ✅ 촬영 확인 화면에서는 분석을 시작하지 않습니다.
    //    '사진 사용'을 누르면 촬영한 XFile을 상위 화면(미디어 피커)에 반환합니다.
    //    분석은 미디어 피커의 '완료' 버튼에서 시작됩니다.
    if (_loading) return;
    Navigator.of(context).pop<XFile>(widget.xfile);
  }

  @override
  Widget build(BuildContext context) {
    // ... 이하 UI 빌드 로직은 기존과 동일하므로 생략합니다 ...
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: Center(child: _image())),

            // Bottom bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  height: 86,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.black.withOpacity(0.9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _loading
                                ? null
                                : () => Navigator.of(context).pop(false),
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Text(
                                '다시 찍기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _loading ? null : _usePhoto,
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Text(
                                '사진 사용',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 4,
              top: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context).pop(false),
              ),
            ),

            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          '분석 중...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}