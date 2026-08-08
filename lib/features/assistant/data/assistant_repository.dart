import '../../../core/network/api_client.dart';
import '../models/assistant_session.dart';

class AssistantRepository {
  AssistantRepository(this._api);

  final ApiClient _api;

  static const sessionsPath = '/api/v1/assistant/sessions';

  Future<AssistantSession> createSession() {
    return _api.post<AssistantSession>(
      sessionsPath,
      decoder: (raw) => AssistantSession.fromJson(_unwrap(raw)),
    );
  }

  Future<AssistantMessageResponse> sendMessage({
    required String sessionId,
    required String text,
    required String source,
  }) {
    return _api.post<AssistantMessageResponse>(
      '$sessionsPath/$sessionId/messages',
      body: {
        'text': text,
        'source': source,
      },
      decoder: (raw) => AssistantMessageResponse.fromJson(_unwrap(raw)),
    );
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    final map = (raw as Map).cast<String, dynamic>();
    return (map['data'] as Map).cast<String, dynamic>();
  }
}
