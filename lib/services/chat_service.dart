import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/api_client.dart';
import 'department_service.dart';

class ChatSource {
  const ChatSource({required this.title, required this.snippet, this.url});

  final String title;
  final String snippet;
  final String? url;

  factory ChatSource.fromMap(Map<String, dynamic> map) {
    return ChatSource(
      title: map['title'] as String? ?? '출처',
      snippet: map['snippet'] as String? ?? '',
      url: map['url'] as String?,
    );
  }
}

class ChatReply {
  const ChatReply({required this.message, this.sources = const []});

  final String message;
  final List<ChatSource> sources;
}

class ChatService {
  ChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ChatReply> requestReply(
    String message, {
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    // 로컬 데이터로 증상 관련 쿼리 처리
    final localReply = await _tryLocalReply(message);
    if (localReply != null) {
      return localReply;
    }

    final uri = ApiConfig.buildChatUri('/api/chat/');
    final response = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        if (sessionId != null) 'session_id': sessionId,
        if (metadata != null) 'metadata': metadata,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final reply = data['reply'];
      if (reply is String) {
        final List<dynamic>? rawSources = data['sources'] as List<dynamic>?;
        final sources = rawSources == null
            ? const <ChatSource>[]
            : rawSources
                  .whereType<Map<String, dynamic>>()
                  .map(ChatSource.fromMap)
                  .toList();
        return ChatReply(message: reply, sources: sources);
      }
      throw ApiException(500, '잘못된 응답 형식입니다.');
    }

    final text = response.body.isEmpty ? '{}' : response.body;
    final dynamic errorData = jsonDecode(text);
    final messageText = errorData is Map<String, dynamic>
        ? errorData['error'] ?? errorData['detail'] ?? '요청이 실패했습니다.'
        : '요청이 실패했습니다.';

    throw ApiException(response.statusCode, messageText.toString());
  }

  Future<ChatReply?> _tryLocalReply(String message) async {
    try {
      final mapping = await DepartmentMapping.load();

      // 증상 관련 키워드 확인
      final symptomKeywords = ['증상', '아프', '통증', '기침', '숨', '멍울', '촬영', '치료'];
      final hasSymptomKeyword = symptomKeywords.any((keyword) => message.contains(keyword));

      if (hasSymptomKeyword) {
        final department = mapping.findDepartmentForSymptom(message);
        if (department != null) {
          return ChatReply(
            message: '${department} 진료를 추천합니다. 정확한 진단을 위해 병원을 방문해주세요.',
            sources: [
              ChatSource(
                title: mapping.title,
                snippet: '증상별 진료과 안내 데이터',
                url: null,
              ),
            ],
          );
        }
      }
    } catch (e) {
      // 로컬 데이터 로드 실패 시 null 반환하여 API 호출로 진행
      return null;
    }
    return null;
  }

  void close() => _client.close();
}
