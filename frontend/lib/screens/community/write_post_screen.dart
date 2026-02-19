import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/community_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/community/analysis_card_widget.dart'; // 👈 3단계에서 만든 위젯 import

class WritePostScreen extends StatefulWidget {
  // ✅ [추가] 외부에서 전달받을 분석 결과 데이터
  // 예: {'id': '...', 'title': '...', 'image': '...'}
  final Map<String, dynamic>? linkedAnalysis;

  const WritePostScreen({super.key, this.linkedAnalysis});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // ✅ [센스] 분석 결과를 공유하러 들어왔으면, 제목에 자동으로 내용을 좀 채워줍니다.
    if (widget.linkedAnalysis != null) {
      final analysisTitle = widget.linkedAnalysis!['title'] ?? '분석 결과';
      _titleController.text = "['$analysisTitle'] 관련 질문입니다.";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      debugPrint("사진 선택 오류: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ✅ [핵심] 분석 결과 데이터(widget.linkedAnalysis)도 같이 보냄!
      final success = await context.read<CommunityProvider>().addPost(
        context,
        title: title,
        content: content,
        images: _selectedImages,
        linkedAnalysis: widget.linkedAnalysis, // 👈 여기가 중요!
      );

      if (!mounted) return;
      
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 등록되었습니다! 🎉')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('업로드 실패. 잠시 후 다시 시도해주세요.')),
        );
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('글쓰기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // ✅ [추가] 만약 분석 공유로 들어왔다면, 상단에 카드를 보여줌
            if (widget.linkedAnalysis != null) ...[
              AnalysisCardWidget(
                title: widget.linkedAnalysis!['title'] ?? '분석 결과',
                imageUrl: widget.linkedAnalysis!['image'],
                onTap: () {
                   // 작성 중에는 클릭해도 별 동작 없음 (혹은 미리보기)
                },
              ),
              const SizedBox(height: 20),
            ],

            // 사진 선택 영역
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, color: Colors.grey),
                          const SizedBox(height: 4),
                          Text('${_selectedImages.length}/10', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  ..._selectedImages.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final XFile image = entry.value;
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(image.path) 
                                  : FileImage(File(image.path)) as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            const Divider(),
            
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '내용을 입력하세요.\n아이의 안전과 관련된 질문이나 팁을 공유해보세요!',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 10,
            ),
          ],
        ),
      ),
    );
  }
}