import 'dart:convert';

import 'package:flutter/foundation.dart'; // kIsWeb 사용
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // ✅ XFile 사용을 위해 필수

import '../models/analysis_result.dart';
import '../models/scan_record.dart';
import '../models/post_model.dart'; // ✅ Post 모델 사용을 위해 필수
import '../models/comment_model.dart'; // ✅ 이 줄을 추가하세요!

class ApiProvider {
  final String baseUrl;

  ApiProvider({required this.baseUrl});

  // ---------------------------------------------------------------------------
  // ✅ [CORS 대응] 이미지 주소 변환 함수
  // ---------------------------------------------------------------------------
  String toDisplayImageUrl(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;
    if (!kIsWeb) return originalUrl; // 웹이 아니면 프록시 필요 없음
    if (originalUrl.contains('/api/image_proxy?url=')) return originalUrl;
    // GCS 이미지를 백엔드 프록시를 거쳐서 가져오도록 변환
    return '$baseUrl/api/image_proxy?url=${Uri.encodeComponent(originalUrl)}';
  }

  // ---------------------------------------------------------------------------
  // ✅ [보안] 공통 인증 헤더 생성 함수
  // ---------------------------------------------------------------------------
  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------------------------
  // ✅ [메인 기능] 모든 요청에 token 매개변수 추가
  // ---------------------------------------------------------------------------

  /// 분석 요청
  Future<AnalysisResult> analyzePhoto({
    required Uint8List imageBytes,
    required String userId,
    required String spaceType,
    required String growthStage,
    String? childId,
    
    required String token, // ✅ 토큰 추가
  }) async {
    final uri = Uri.parse('$baseUrl/api/analyze');
    final req = http.MultipartRequest('POST', uri);

    req.headers['Authorization'] = 'Bearer $token';

    req.fields['user_id'] = userId;
    req.fields['space_type'] = spaceType;
    req.fields['growth_stage'] = growthStage;
    if (childId != null) {
      req.fields['child_id'] = childId;
    }
    req.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: 'upload.jpg'),
    );

    // ===== 요청 로그 =====
    debugPrint('===== REQUEST =====');
    debugPrint('POST $uri');
    debugPrint('fields: ${req.fields}');
    debugPrint('file size: ${imageBytes.length}');
    debugPrint('===================');

    final streamedResponse = await req.send();
    final response = await http.Response.fromStream(streamedResponse);


    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'analyzePhoto failed: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    // 분석 결과 이미지도 웹이면 프록시 처리
    final String rawUrl = (json['image_url'] ?? '').toString();
    if (rawUrl.isNotEmpty) {
      json['image_url'] = toDisplayImageUrl(rawUrl);
    }

    return AnalysisResult.fromJson(json);
  }

  /// ✅ 기록 조회
  Future<List<ScanRecord>> getScanHistory(String userId, String token) async {
    final uri = Uri.parse('$baseUrl/api/history/$userId');

    try {
      final res = await http.get(uri, headers: _getHeaders(token));

      // debugPrint('===== HISTORY RESPONSE =====');
      // debugPrint('GET $uri');
      // debugPrint('statusCode: ${res.statusCode}');
      // debugPrint(utf8.decode(res.bodyBytes));
      // debugPrint('===========================');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('기록 조회 실패: ${res.statusCode}');
      }

      final Map<String, dynamic> root =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

      final List<dynamic> list = (root['data'] ?? []) as List<dynamic>;

      return list.whereType<Map<String, dynamic>>().map((e) {
        // ✅ 조회된 각 기록의 이미지 URL도 웹이면 프록시 처리
        final String rawUrl = (e['image_url'] ?? '').toString();
        if (rawUrl.isNotEmpty) {
          e['image_url'] = toDisplayImageUrl(rawUrl);
        }
        return ScanRecord.fromJson(e);
      }).toList();
    } catch (e) {
      debugPrint("❌ getScanHistory 에러: $e");
      rethrow;
    }
  }
    // ✅ solvedHazardKeys 서버 저장

  Future<void> updateSolvedHazardKeys(
    String reportId,
    List<String> solvedKeys,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/api/history/$reportId/solved-keys'); // ✅ /api 포함

    final res = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'solved_hazard_keys': solvedKeys,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('updateSolvedHazardKeys failed: ${res.statusCode} ${res.body}');
    }
  }

  /// ✅ 기록 삭제(단일)
  Future<bool> deleteScanRecord(String reportId, String token) async {
    final uri = Uri.parse('$baseUrl/api/history/$reportId');
    final res = await http.delete(uri, headers: _getHeaders(token));
    return res.statusCode == 200;
  }
  /// ✅ [추가] 특정 ID의 검사 기록 1개 조회 (공유된 분석 결과 보기용)
  Future<ScanRecord?> fetchScanRecord(String recordId, String token) async {
    // URL은 백엔드 구현에 따라 다를 수 있으나, 보통 history/{id} 형태입니다.
    final uri = Uri.parse('$baseUrl/api/history/shared/$recordId');
    
    try {
      final res = await http.get(uri, headers: _getHeaders(token));
      
      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        
        // 응답 구조가 { "data": { ... } } 인지, 바로 { ... } 인지에 따라 처리
        final data = json['data'] ?? json;
        
        // 이미지 URL 프록시 처리 (웹 환경 대응)
        if (data['image_url'] != null) {
          data['image_url'] = toDisplayImageUrl(data['image_url']);
        }
        
        return ScanRecord.fromJson(data);
      } else {
        debugPrint("❌ 기록 상세 조회 실패: ${res.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ 기록 상세 조회 통신 에러: $e");
      return null;
    }
  }
  /// ✅ 기록 삭제(전체)
  Future<bool> deleteAllHistory(String userId, String token) async {
    final uri = Uri.parse('$baseUrl/api/history/all/$userId');
    final res = await http.delete(uri, headers: _getHeaders(token));
    return res.statusCode == 200;
  }

  // ---------------------------------------------------------------------------
  // ✅ [인증] 회원가입 & 로그인
  // ---------------------------------------------------------------------------

  Future<String> register({
    required String email,
    required String password,
    required String userName,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');

    debugPrint('📡 [API 요청 시작] URL: $uri');
    debugPrint('📡 [API 요청 바디] email: $email, userName: $userName');

    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
              'user_name': userName,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 [API 응답] 코드: ${res.statusCode}');
      debugPrint('📡 [API 응답] 바디: ${res.body}');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        debugPrint(
          '⚠️ [API 에러 발생] 상세: ${_extractErrorMessage(res, fallback: "알 수 없는 에러")}',
        );
        throw ApiException(
          res.statusCode,
          _extractErrorMessage(res, fallback: '가입 실패'),
        );
      }

      final json = jsonDecode(res.body);
      debugPrint('✅ [API 성공] 토큰 획득 완료');
      return json['access_token'] ?? '';
    } catch (e) {
      debugPrint('❌ [API 통신 실패] 에러 내용: $e');
      rethrow;
    }
  }

  /// ✅ 로그인 (String 반환 버전을 삭제하고 Map 반환 버전으로 통합)
  /// user_name을 받아오기 위해 Map<String, dynamic>을 반환합니다.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');

    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(
          res.statusCode,
          _extractErrorMessage(res, fallback: '로그인 실패'),
        );
      }

      // ✅ Map 전체 반환 (access_token, user_name 등 포함)
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("❌ Login Error: $e");
      rethrow;
    }
  }

  /// ✅ [NEW] 게스트 로그인 (POST /api/auth/guest-login)
  /// 서버에서 {access_token, email, user_name, is_guest} 등을 포함한 Map을 반환함
  Future<Map<String, dynamic>> guestLogin() async {
    final uri = Uri.parse('$baseUrl/api/auth/guest-login');

    debugPrint('📡 [게스트 로그인 요청] URL: $uri');

    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(
          res.statusCode,
          _extractErrorMessage(res, fallback: '게스트 로그인 실패'),
        );
      }

      // 토큰뿐만 아니라 이메일(guest_xxx) 등 정보를 다 받기 위해 Map 반환
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      debugPrint('✅ [게스트 로그인 성공] 이메일: ${json['email']}');

      return json;
    } catch (e) {
      debugPrint("❌ 게스트 로그인 오류: $e");
      rethrow;
    }
  }

  /// ✅ 아이 프로필 서버 저장
  Future<bool> createChildProfile({
    required String childName,
    required String birthday,
    required String growthStage,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/childs');

    try {
      final res = await http.post(
        uri,
        headers: _getHeaders(token),
        body: jsonEncode({
          'child_name': childName,
          'birthday': birthday,
          'growth_stage': growthStage,
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        debugPrint("✅ 서버 저장 성공!");
        return true;
      } else {
        debugPrint("❌ 서버 저장 실패: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ 네트워크 오류: $e");
      return false;
    }
  }

  /// ✅ 아이 프로필 목록 조회
  Future<List<dynamic>> getChildProfiles(String token) async {
    final uri = Uri.parse('$baseUrl/api/childs');

    try {
      final res = await http.get(uri, headers: _getHeaders(token));

      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        return json['data'] ?? [];
      } else {
        debugPrint("❌ 프로필 조회 실패: ${res.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ 네트워크 오류: $e");
      return [];
    }
  }

  /// ✅ 아이 프로필 삭제 요청
  Future<bool> deleteChildProfile(String profileId, String token) async {
    final uri = Uri.parse('$baseUrl/api/childs/$profileId');

    try {
      final res = await http.delete(uri, headers: _getHeaders(token));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("❌ 프로필 삭제 오류: $e");
      return false;
    }
  }

  String _extractErrorMessage(http.Response res, {required String fallback}) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map && decoded.containsKey('detail')) {
        final detail = decoded['detail'];
        if (detail is Map) return detail['message'] ?? fallback;
        return detail.toString();
      }
    } catch (_) {}
    return fallback;
  }
  // ---------------------------------------------------------------------------
  // ✅ [커뮤니티] 게시판 관련 API (사용자 코드 반영)
  // ---------------------------------------------------------------------------

  /// 1. 게시글 목록 조회
  Future<List<Post>> fetchCommunityPosts(String token) async {
    final uri = Uri.parse('$baseUrl/api/community/posts'); // /api 경로 주의
    try {
      final res = await http.get(uri, headers: _getHeaders(token));
      
      if (res.statusCode == 200) {
        // UTF-8 디코딩 처리
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> list = json['data'] ?? [];
        
        return list.map((e) {
            // 이미지 프록시 처리 (웹 대응)
            List<String> urls = List<String>.from(e['image_urls'] ?? []);
            e['imageUrls'] = urls.map((url) => toDisplayImageUrl(url)).toList();
            // ✅ [수정] 분석 공유 카드 이미지도 프록시 처리 추가!
            if (e['linked_analysis'] != null && e['linked_analysis']['image'] != null) {
              String rawAnalysisImg = e['linked_analysis']['image'];
              // 프록시 URL로 변환하여 덮어쓰기
              e['linked_analysis']['image'] = toDisplayImageUrl(rawAnalysisImg);
            }
            // Post 모델 변환
            return Post.fromMap(e, e['id']);
        }).toList();
      } else {
        debugPrint("❌ 게시글 조회 실패: ${res.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ 게시글 통신 에러: $e");
      return [];
    }
  }

  /// 2. 게시글 작성 (Multipart - 사진 여러 장 + 분석 공유 필드 개별 전송)
  Future<bool> createCommunityPost({
    required String token,
    required String title,
    required String content,
    List<XFile>? images,
    // ✅ 분석 공유 데이터 (개별 필드로 받음)
    String? linkedAnalysisId,
    String? linkedAnalysisTitle,
    String? linkedAnalysisImage,
  }) async {
    final uri = Uri.parse('$baseUrl/api/community/posts');
    final req = http.MultipartRequest('POST', uri);
    
    req.headers['Authorization'] = 'Bearer $token';
    
    // 텍스트 필드 추가
    req.fields['title'] = title;
    req.fields['content'] = content;
    
    // 분석 공유 데이터가 있으면 추가
    if (linkedAnalysisId != null) {
      req.fields['linked_analysis_id'] = linkedAnalysisId;
      req.fields['linked_analysis_title'] = linkedAnalysisTitle ?? '';
      req.fields['linked_analysis_image'] = linkedAnalysisImage ?? '';
    }

    // 파일 필드 추가 (여러 장)
    if (images != null) {
      for (var image in images) {
        final bytes = await image.readAsBytes();
        req.files.add(
          http.MultipartFile.fromBytes(
            'files', // 백엔드 매개변수 이름 ('files')과 일치해야 함
            bytes,
            filename: image.name,
          ),
        );
      }
    }

    try {
      final streamedResponse = await req.send();
      final res = await http.Response.fromStream(streamedResponse);
      
      if (res.statusCode == 201) {
        return true;
      } else {
        debugPrint("❌ 글쓰기 실패: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ 글쓰기 통신 에러: $e");
      return false;
    }
  }

  /// 3. 좋아요 토글
  Future<bool> toggleLike(String postId, String token) async {
    final uri = Uri.parse('$baseUrl/api/community/posts/$postId/like');
    try {
      final res = await http.post(uri, headers: _getHeaders(token));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  /// ✅ 4. 게시글 삭제 (이 부분이 없으면 삭제 요청을 못 보냅니다!)
  Future<bool> deleteCommunityPost(String postId, String token) async {
    final uri = Uri.parse('$baseUrl/api/community/posts/$postId');
    try {
      final res = await http.delete(uri, headers: _getHeaders(token));
      // 200 OK가 와야 성공
      if (res.statusCode == 200) {
        return true;
      } else {
        debugPrint("❌ 삭제 실패 상태코드: ${res.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ 게시글 삭제 통신 에러: $e");
      return false;
    }
  }

  /// ✅ [NEW] 오늘의 인기글 조회
  Future<List<Post>> fetchDailyBestPosts(String token) async {
    final uri = Uri.parse('$baseUrl/api/community/daily-best');
    try {
      final res = await http.get(uri, headers: _getHeaders(token));
      
      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> list = json['data'] ?? [];
        
        return list.map((e) {
            // 이미지 프록시 처리
            List<String> urls = List<String>.from(e['image_urls'] ?? []);
            e['imageUrls'] = urls.map((url) => toDisplayImageUrl(url)).toList();
            // ✅ [수정] 분석 공유 카드 이미지 처리 추가!
            if (e['linked_analysis'] != null && e['linked_analysis']['image'] != null) {
              String rawAnalysisImg = e['linked_analysis']['image'];
              e['linked_analysis']['image'] = toDisplayImageUrl(rawAnalysisImg);
            }
            return Post.fromMap(e, e['id']);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint("❌ 인기글 통신 에러: $e");
      return [];
    }
  }
  // ---------------------------------------------------------------------------
  // ✅ 댓글 (Comment) 관련 API
  // ---------------------------------------------------------------------------

  // 댓글 목록 조회
  Future<List<Comment>> fetchComments(String postId, String token) async {
    final uri = Uri.parse('$baseUrl/api/community/posts/$postId/comments');
    try {
      final res = await http.get(uri, headers: _getHeaders(token));
      
      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> list = json['data'] ?? [];
        // Comment.fromMap이 snake_case 처리를 다 해두었으므로 그대로 변환
        return list.map((e) => Comment.fromMap(e, e['id'] ?? '')).toList();
      }
      return [];
    } catch (e) {
      debugPrint("❌ 댓글 조회 실패: $e");
      return [];
    }
  }

  // 댓글 작성
  Future<bool> addComment(String postId, String content, String token) async {
    final uri = Uri.parse('$baseUrl/api/community/posts/$postId/comments');
    try {
      final res = await http.post(
        uri, 
        headers: {
          ..._getHeaders(token),
          'Content-Type': 'application/x-www-form-urlencoded', // 폼 데이터 전송
        }, 
        body: {'content': content}
      );
      return res.statusCode == 200; // 200 OK면 성공
    } catch (e) {
      debugPrint("❌ 댓글 작성 실패: $e");
      return false;
    }
  }
}


class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}