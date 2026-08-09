import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/locator.dart';
import '../../core/network/api_exception.dart';
import '../../features/reminders/reminder_registration_service.dart';
import '../../features/reminders/services/reminder_notification_service.dart';
import 'assistant_message_support.dart';
import 'data/assistant_repository.dart';
import 'models/assistant_reply.dart';
import 'models/assistant_session.dart';
import 'models/chat_message.dart';
import 'services/speech_to_text_service.dart';
import 'services/text_to_speech_service.dart';

enum AssistantInteractionState {
  idle,
  listening,
  processing,
  speaking,
}

class AssistantUiState {
  const AssistantUiState({
    this.interactionState = AssistantInteractionState.idle,
    this.messages = const [],
    this.partialTranscript,
    this.sessionId,
    this.pendingRetryText,
    this.errorMessage,
  });

  final AssistantInteractionState interactionState;
  final List<ChatMessage> messages;
  final String? partialTranscript;
  final String? sessionId;
  final String? pendingRetryText;
  final String? errorMessage;

  bool get isMicEnabled =>
      interactionState == AssistantInteractionState.idle ||
      interactionState == AssistantInteractionState.listening;

  /// Whether the latest assistant reply is waiting for another voice answer.
  bool get expectsFollowUpInput {
    for (var i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      if (!message.isUser) {
        return message.replyType == AssistantReplyType.followUp ||
            message.replyType == AssistantReplyType.confirmation;
      }
    }
    return false;
  }

  AssistantUiState copyWith({
    AssistantInteractionState? interactionState,
    List<ChatMessage>? messages,
    String? partialTranscript,
    bool clearPartialTranscript = false,
    String? sessionId,
    String? pendingRetryText,
    bool clearPendingRetryText = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AssistantUiState(
      interactionState: interactionState ?? this.interactionState,
      messages: messages ?? this.messages,
      partialTranscript:
          clearPartialTranscript ? null : (partialTranscript ?? this.partialTranscript),
      sessionId: sessionId ?? this.sessionId,
      pendingRetryText: clearPendingRetryText
          ? null
          : (pendingRetryText ?? this.pendingRetryText),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AssistantController extends Notifier<AssistantUiState> {
  late final SpeechToTextService _stt;
  late final TextToSpeechService _tts;
  late final AssistantRepository _repo;
  late final ReminderRegistrationService _reminderRegistration;

  /// Voice capture source reused across multi-turn follow-up chains.
  String? _activeCaptureSource;

  @override
  AssistantUiState build() {
    _stt = ref.read(speechToTextServiceProvider);
    _tts = ref.read(textToSpeechServiceProvider);
    _repo = locator<AssistantRepository>();
    _reminderRegistration = locator<ReminderRegistrationService>();

    ref.onDispose(() {
      _tts.stop();
      _stt.stopListening();
    });
    _tts.setCompletionHandler(_onSpeechComplete);
    Future.microtask(_ensureSession);
    return const AssistantUiState();
  }

  Future<void> _ensureSession() async {
    if (state.sessionId != null) return;
    try {
      final session = await _repo.createSession();
      state = state.copyWith(sessionId: session.id, clearErrorMessage: true);
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Could not start assistant session.',
      );
    }
  }

  Future<void> onMicPressed() async {
    if (!state.isMicEnabled) return;

    if (state.interactionState == AssistantInteractionState.listening) {
      await _stt.stopListening();
      _activeCaptureSource = null;
      state = state.copyWith(
        interactionState: AssistantInteractionState.idle,
        clearPartialTranscript: true,
      );
      return;
    }

    await startManualCommandCapture(source: 'button');
  }

  /// Starts microphone capture for a manual (button/widget) command.
  ///
  /// Unlike [onMicPressed], does not stop an active listening session — no-op
  /// when the assistant is not [AssistantInteractionState.idle].
  Future<void> startManualCommandCapture({String source = 'button'}) async {
    if (state.interactionState != AssistantInteractionState.idle) return;

    _activeCaptureSource = source;

    state = state.copyWith(
      interactionState: AssistantInteractionState.listening,
      clearPartialTranscript: true,
      clearErrorMessage: true,
    );

    final started = await _stt.startListening(
      onPartial: (transcript) {
        state = state.copyWith(partialTranscript: transcript);
      },
      onFinal: (transcript) {
        _handleManualCommandTranscript(transcript, source: source);
      },
    );

    if (!started) {
      _activeCaptureSource = null;
      final message = _stt.error?.message ?? 'Could not start listening.';
      state = state.copyWith(
        interactionState: AssistantInteractionState.idle,
        clearPartialTranscript: true,
        errorMessage: message,
      );
    }
  }

  Future<void> _handleManualCommandTranscript(
    String transcript, {
    required String source,
  }) async {
    final text = transcript.trim();
    await _stt.stopListening();

    if (text.isEmpty) {
      _activeCaptureSource = null;
      state = state.copyWith(
        interactionState: AssistantInteractionState.idle,
        clearPartialTranscript: true,
      );
      return;
    }

    await _sendUserMessage(text, source: source);
  }

  Future<void> _sendUserMessage(
    String text, {
    bool isRetry = false,
    String source = 'button',
  }) async {
    if (state.sessionId == null) {
      await _ensureSession();
      if (state.sessionId == null) return;
    }

    state = state.copyWith(
      interactionState: AssistantInteractionState.processing,
      messages: isRetry
          ? state.messages
          : [...state.messages, ChatMessage(text: text, isUser: true)],
      clearPartialTranscript: true,
      clearPendingRetryText: true,
      clearErrorMessage: true,
    );

    try {
      final result = await _repo.sendMessage(
        sessionId: state.sessionId!,
        text: text,
        source: source,
      );

      final response = result.response;
      final reply = response.reply;
      final displayText = assistantReplyDisplayText(
        text: reply.text,
        action: reply.action,
      );

      if (reply.type == AssistantReplyType.actionResult) {
        if (state.interactionState == AssistantInteractionState.listening) {
          await _stt.stopListening();
        }
        _activeCaptureSource = null;
      }

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(
            text: displayText,
            isUser: false,
            replyType: reply.type,
            action: reply.action,
          ),
        ],
        interactionState: AssistantInteractionState.speaking,
      );

      if (reply.type == AssistantReplyType.actionResult && reply.action != null) {
        unawaited(_reminderRegistration.handleActionResult(reply.action!));
      }

      final topLevelAction = result.action;
      final replyAction = reply.action;
      final reminderSlug = topLevelAction?.pluginSlug ?? replyAction?.pluginSlug;
      final reminderStatus = topLevelAction?.status ?? replyAction?.status;
      if (reminderSlug == 'reminder' && reminderStatus == 'success') {
        unawaited(locator<ReminderNotificationService>().syncReminders());
      }

      if (response.sessionStatus == AssistantSessionStatus.completed) {
        await _startNewSession();
      }

      await _tts.speak(displayText);
      if (!_tts.isSupported) {
        _onSpeechComplete();
      }
    } on ApiException catch (e) {
      _activeCaptureSource = null;
      state = state.copyWith(
        interactionState: AssistantInteractionState.idle,
        pendingRetryText: text,
        errorMessage: e.message,
      );
    } catch (_) {
      _activeCaptureSource = null;
      state = state.copyWith(
        interactionState: AssistantInteractionState.idle,
        pendingRetryText: text,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _startNewSession() async {
    try {
      final session = await _repo.createSession();
      state = state.copyWith(sessionId: session.id);
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Could not start a new assistant session.',
      );
    }
  }

  bool _lastAssistantReplyExpectsInput() => state.expectsFollowUpInput;

  void _onSpeechComplete() {
    if (state.interactionState != AssistantInteractionState.speaking) return;

    if (_lastAssistantReplyExpectsInput()) {
      unawaited(_resumeListeningForFollowUp());
      return;
    }

    _activeCaptureSource = null;
    state = state.copyWith(interactionState: AssistantInteractionState.idle);
  }

  Future<void> _resumeListeningForFollowUp() async {
    state = state.copyWith(
      interactionState: AssistantInteractionState.listening,
      clearPartialTranscript: true,
      clearErrorMessage: true,
    );

    final started = await _stt.startListening(
      onPartial: (transcript) {
        state = state.copyWith(partialTranscript: transcript);
      },
      onFinal: (transcript) {
        _handleFollowUpTranscript(transcript);
      },
    );

    if (!started) {
      _activeCaptureSource = null;
      final message = _stt.error?.message ?? 'Could not start listening.';
      state = state.copyWith(
        interactionState: AssistantInteractionState.idle,
        clearPartialTranscript: true,
        errorMessage: message,
      );
    }
  }

  Future<void> _handleFollowUpTranscript(String transcript) async {
    final text = transcript.trim();
    await _stt.stopListening();

    if (text.isEmpty) {
      _activeCaptureSource = null;
      state = state.copyWith(
        interactionState: AssistantInteractionState.idle,
        clearPartialTranscript: true,
      );
      return;
    }

    await _sendUserMessage(
      text,
      source: _activeCaptureSource ?? 'button',
    );
  }

  /// Sends a yes/no answer to the latest confirmation prompt.
  Future<void> sendConfirmationResponse({required bool confirmed}) async {
    if (!state.expectsFollowUpInput) return;
    if (state.interactionState == AssistantInteractionState.listening) {
      await _stt.stopListening();
    }
    await _sendUserMessage(
      confirmed ? 'yes' : 'no',
      source: _activeCaptureSource ?? 'button',
    );
  }

  Future<void> retryLastMessage() async {
    final text = state.pendingRetryText;
    if (text == null) return;
    await _sendUserMessage(text, isRetry: true, source: 'button');
  }

  /// Sends a command captured after wake-word detection.
  Future<void> sendWakeWordCommand(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _activeCaptureSource = 'wake_word';
    await _sendUserMessage(trimmed, source: 'wake_word');
  }

  /// Opens the assistant prompt and listens for a command after wake word only.
  Future<void> startWakeWordCommandCapture() async {
    if (state.interactionState != AssistantInteractionState.idle) return;

    _activeCaptureSource = 'wake_word';

    state = state.copyWith(
      interactionState: AssistantInteractionState.listening,
      clearPartialTranscript: true,
      clearErrorMessage: true,
    );

    final started = await _stt.startListening(
      onPartial: (transcript) {
        state = state.copyWith(partialTranscript: transcript);
      },
      onFinal: (transcript) {
        _handleWakeWordCommandTranscript(transcript);
      },
    );

    if (!started) {
      _activeCaptureSource = null;
      final message = _stt.error?.message ?? 'Could not start listening.';
      state = state.copyWith(
        interactionState: AssistantInteractionState.idle,
        clearPartialTranscript: true,
        errorMessage: message,
      );
    }
  }

  Future<void> _handleWakeWordCommandTranscript(String transcript) async {
    final text = transcript.trim();
    await _stt.stopListening();

    if (text.isEmpty) {
      _activeCaptureSource = null;
      state = state.copyWith(
        interactionState: AssistantInteractionState.idle,
        clearPartialTranscript: true,
      );
      return;
    }

    await _sendUserMessage(text, source: 'wake_word');
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }
}

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantUiState>(
  AssistantController.new,
);
