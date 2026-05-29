import 'package:flutter_application_1/core/services/supabase_service.dart';

class LiveKitTokenResponse {
  final String token;
  final String url;
  final String roomName;
  final String identity;
  final String participantName;

  LiveKitTokenResponse({
    required this.token,
    required this.url,
    required this.roomName,
    required this.identity,
    required this.participantName,
  });

  factory LiveKitTokenResponse.fromMap(Map<String, dynamic> map) {
    return LiveKitTokenResponse(
      token: map['token']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      roomName: map['room_name']?.toString() ?? '',
      identity: map['identity']?.toString() ?? '',
      participantName: map['participant_name']?.toString() ?? '',
    );
  }
}

class VideoCallService {
  Future<LiveKitTokenResponse> createLiveKitToken({
    required String sessionId,
    required String participantName,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Görüntülü görüşmeye katılmak için giriş yapmalısın.');
    }

    final response = await supabase.functions.invoke(
      'create-livekit-token',
      body: {
        'session_id': sessionId,
        'participant_name': participantName,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw Exception('LiveKit token cevabı geçersiz geldi.');
    }

    final result = Map<String, dynamic>.from(data);

    if (result['error'] != null) {
      throw Exception(result['error'].toString());
    }

    final tokenResponse = LiveKitTokenResponse.fromMap(result);

    if (tokenResponse.token.isEmpty || tokenResponse.url.isEmpty) {
      throw Exception('LiveKit bağlantı bilgileri eksik geldi.');
    }

    return tokenResponse;
  }
}