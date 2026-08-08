import '../../../core/network/api_client.dart';
import '../models/assistant_action.dart';
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

  Future<AssistantMessageResult> sendMessage({
    required String sessionId,
    required String text,
    required String source,
  }) {
    return _api.post<AssistantMessageResult>(
      '$sessionsPath/$sessionId/messages',
      body: {
        'text': text,
        'source': source,
      },
      decoder: (raw) {
        final data = _unwrap(raw);
        final actionJson = data['action'];
        return AssistantMessageResult(
          response: AssistantMessageResponse.fromJson(data),
          action: actionJson is Map<String, dynamic>
              ? AssistantAction.fromJson(actionJson)
              : actionJson is Map
                  ? AssistantAction.fromJson(actionJson.cast<String, dynamic>())
                  : null,
        );
      },
    );
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    final map = (raw as Map).cast<String, dynamic>();
    return (map['data'] as Map).cast<String, dynamic>();
  }
}
