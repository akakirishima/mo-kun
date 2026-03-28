import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:record/record.dart' hide IosAudioCategory;
import 'package:web_socket_channel/io.dart';

enum LiveVoicePhase {
  disconnected,
  connecting,
  listening,
  speaking,
  reconnecting,
  error,
}

enum LiveVoiceSpeaker { user, assistant }

class LiveVoiceTranscriptEntry {
  const LiveVoiceTranscriptEntry({
    required this.turnId,
    required this.speaker,
    required this.text,
    required this.isPartial,
  });

  final String turnId;
  final LiveVoiceSpeaker speaker;
  final String text;
  final bool isPartial;

  LiveVoiceTranscriptEntry copyWith({
    String? turnId,
    LiveVoiceSpeaker? speaker,
    String? text,
    bool? isPartial,
  }) {
    return LiveVoiceTranscriptEntry(
      turnId: turnId ?? this.turnId,
      speaker: speaker ?? this.speaker,
      text: text ?? this.text,
      isPartial: isPartial ?? this.isPartial,
    );
  }
}

class LiveVoiceUiState {
  const LiveVoiceUiState({
    required this.phase,
    required this.microphoneEnabled,
    this.transcriptText,
    this.assistantText,
    this.partialTranscriptText,
    this.partialAssistantText,
    this.errorText,
    this.model,
    this.fallbackUsed = false,
    this.acceptanceNotes = const <String>[],
    this.transcriptEntries = const <LiveVoiceTranscriptEntry>[],
    this.inputLevelHistory = const <double>[],
    this.inputStreamingSuspended = false,
  });

  final LiveVoicePhase phase;
  final bool microphoneEnabled;
  final String? transcriptText;
  final String? assistantText;
  final String? partialTranscriptText;
  final String? partialAssistantText;
  final String? errorText;
  final String? model;
  final bool fallbackUsed;
  final List<String> acceptanceNotes;
  final List<LiveVoiceTranscriptEntry> transcriptEntries;
  final List<double> inputLevelHistory;
  final bool inputStreamingSuspended;

  LiveVoiceUiState copyWith({
    LiveVoicePhase? phase,
    bool? microphoneEnabled,
    String? transcriptText,
    String? assistantText,
    String? partialTranscriptText,
    String? partialAssistantText,
    String? errorText,
    String? model,
    bool? fallbackUsed,
    List<String>? acceptanceNotes,
    List<LiveVoiceTranscriptEntry>? transcriptEntries,
    List<double>? inputLevelHistory,
    bool? inputStreamingSuspended,
    bool clearTranscriptText = false,
    bool clearAssistantText = false,
    bool clearPartialTranscriptText = false,
    bool clearPartialAssistantText = false,
    bool clearErrorText = false,
    bool clearModel = false,
  }) {
    return LiveVoiceUiState(
      phase: phase ?? this.phase,
      microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
      transcriptText: clearTranscriptText
          ? null
          : transcriptText ?? this.transcriptText,
      assistantText: clearAssistantText
          ? null
          : assistantText ?? this.assistantText,
      partialTranscriptText: clearPartialTranscriptText
          ? null
          : partialTranscriptText ?? this.partialTranscriptText,
      partialAssistantText: clearPartialAssistantText
          ? null
          : partialAssistantText ?? this.partialAssistantText,
      errorText: clearErrorText ? null : errorText ?? this.errorText,
      model: clearModel ? null : model ?? this.model,
      fallbackUsed: fallbackUsed ?? this.fallbackUsed,
      acceptanceNotes: acceptanceNotes ?? this.acceptanceNotes,
      transcriptEntries: transcriptEntries ?? this.transcriptEntries,
      inputLevelHistory: inputLevelHistory ?? this.inputLevelHistory,
      inputStreamingSuspended:
          inputStreamingSuspended ?? this.inputStreamingSuspended,
    );
  }

  static const disconnected = LiveVoiceUiState(
    phase: LiveVoicePhase.disconnected,
    microphoneEnabled: false,
  );
}

abstract class LiveVoiceSessionController {
  ValueListenable<LiveVoiceUiState> get listenable;

  LiveVoiceUiState get state;

  Future<void> connect({required String threadId});

  Future<void> toggleMicrophone();

  Future<void> disconnect();

  Future<void> dispose();
}

class DeviceLiveVoiceSessionController implements LiveVoiceSessionController {
  DeviceLiveVoiceSessionController({
    FirebaseAuth? auth,
    AudioRecorder? recorder,
    DevicePcmAudioPlayer? audioPlayer,
    Uri? backendUri,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _recorder = recorder ?? AudioRecorder(),
       _audioPlayer = audioPlayer ?? DevicePcmAudioPlayer(),
       _backendUri = backendUri ?? _resolveBackendWsUri() {
    _audioPlayer.onPlatformAudioReady = () =>
        _ensureCallAudioConfigured(refreshOutputRoute: true);
  }

  final FirebaseAuth _auth;
  final AudioRecorder _recorder;
  final DevicePcmAudioPlayer _audioPlayer;
  final Uri _backendUri;
  final _LiveVoiceCallAudioConfigurator _callAudioConfigurator =
      _LiveVoiceCallAudioConfigurator();
  final ValueNotifier<LiveVoiceUiState> _stateNotifier = ValueNotifier(
    LiveVoiceUiState.disconnected,
  );
  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  StreamSubscription<Uint8List>? _microphoneSubscription;
  final BytesBuilder _inputAudioBuffer = BytesBuilder(copy: false);
  final BytesBuilder _preReadyInputBuffer = BytesBuilder(copy: false);
  String? _activeTurnId;
  String? _threadId;
  String? _resumeSessionId;
  String? _resumeHandle;
  bool _disconnectRequested = false;
  bool _microphoneDesired = false;
  bool _suspendInputStreaming = false;
  bool _callAudioConfigured = false;
  bool _sessionReady = false;
  bool _speechDetectedSinceLastFlush = false;
  int _lastSpeechDetectedMs = 0;
  int _lastMicrophoneChunkAtMs = 0;
  int _microphoneStartAttemptAtMs = 0;
  int _microphoneStartupRetryCount = 0;
  Timer? _pendingInputFlushTimer;
  Timer? _microphoneStartupWatchdog;
  int _reconnectAttempts = 0;
  int _lastInputLevelUiUpdateMs = 0;

  @override
  ValueListenable<LiveVoiceUiState> get listenable => _stateNotifier;

  @override
  LiveVoiceUiState get state => _stateNotifier.value;

  @override
  Future<void> connect({required String threadId}) async {
    try {
      if (_threadId == threadId &&
          _channel != null &&
          state.phase != LiveVoicePhase.disconnected) {
        return;
      }

      if (_channel != null) {
        await _closeSocket();
      }

      _threadId = threadId;
      _activeTurnId = null;
      _disconnectRequested = false;
      _suspendInputStreaming = false;
      _sessionReady = false;
      _preReadyInputBuffer.clear();
      _speechDetectedSinceLastFlush = false;
      _lastSpeechDetectedMs = 0;
      _lastMicrophoneChunkAtMs = 0;
      _microphoneStartAttemptAtMs = 0;
      _microphoneStartupRetryCount = 0;
      _pendingInputFlushTimer?.cancel();
      _pendingInputFlushTimer = null;
      _microphoneStartupWatchdog?.cancel();
      _microphoneStartupWatchdog = null;
      _reconnectAttempts = 0;
      _setState(
        state.copyWith(
          phase: LiveVoicePhase.connecting,
          clearErrorText: true,
          clearTranscriptText: true,
          clearAssistantText: true,
          clearPartialTranscriptText: true,
          clearPartialAssistantText: true,
          transcriptEntries: const <LiveVoiceTranscriptEntry>[],
          inputLevelHistory: const <double>[],
          inputStreamingSuspended: false,
        ),
      );

      await _ensureCallAudioConfigured();
      await _openSocket();
    } catch (error) {
      await _releaseCallAudioConfiguration();
      _setState(
        state.copyWith(
          phase: LiveVoicePhase.error,
          errorText: error.toString(),
          microphoneEnabled: false,
        ),
      );
    }
  }

  @override
  Future<void> toggleMicrophone() async {
    try {
      if (state.phase == LiveVoicePhase.connecting ||
          state.phase == LiveVoicePhase.reconnecting) {
        _microphoneDesired = !_microphoneDesired;
        if (_microphoneDesired && _microphoneSubscription == null) {
          await _startMicrophone();
        } else if (!_microphoneDesired && _microphoneSubscription != null) {
          await _stopMicrophone(
            nextPhase: state.phase,
            shouldFlushServerAudio: false,
          );
        }
        return;
      }

      if (_microphoneSubscription == null) {
        _microphoneDesired = true;
        await _startMicrophone();
        return;
      }

      _microphoneDesired = false;
      await _stopMicrophone();
    } catch (error) {
      _setState(
        state.copyWith(
          phase: LiveVoicePhase.error,
          errorText: error.toString(),
          microphoneEnabled: false,
        ),
      );
    }
  }

  @override
  Future<void> disconnect() async {
    _disconnectRequested = true;
    _microphoneDesired = false;
    _suspendInputStreaming = false;
    _sessionReady = false;
    _preReadyInputBuffer.clear();
    _speechDetectedSinceLastFlush = false;
    _lastSpeechDetectedMs = 0;
    _lastMicrophoneChunkAtMs = 0;
    _microphoneStartAttemptAtMs = 0;
    _microphoneStartupRetryCount = 0;
    _pendingInputFlushTimer?.cancel();
    _pendingInputFlushTimer = null;
    _microphoneStartupWatchdog?.cancel();
    _microphoneStartupWatchdog = null;
    _reconnectAttempts = 0;
    await _stopMicrophone(nextPhase: LiveVoicePhase.disconnected);
    await _closeSocket();
    _resumeSessionId = null;
    _resumeHandle = null;
    await _audioPlayer.stop();
    await _releaseCallAudioConfiguration();
    _setState(
      LiveVoiceUiState.disconnected.copyWith(
        transcriptText: state.transcriptText,
        assistantText: state.assistantText,
        transcriptEntries: state.transcriptEntries,
        inputLevelHistory: state.inputLevelHistory,
        inputStreamingSuspended: false,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _recorder.dispose();
    await _audioPlayer.dispose();
    _stateNotifier.dispose();
  }

  Future<void> _openSocket() async {
    final threadId = _threadId;
    final user = _auth.currentUser;
    if (threadId == null || user == null) {
      throw const VoiceControllerException('音声セッションを開始できません。');
    }

    final token = await user.getIdToken();
    final channel = IOWebSocketChannel.connect(
      _backendUri,
      headers: {'Authorization': 'Bearer $token'},
      pingInterval: const Duration(seconds: 20),
      connectTimeout: const Duration(seconds: 15),
    );

    _channel = channel;
    _socketSubscription = channel.stream.listen(
      _handleSocketEvent,
      onError: (Object error, StackTrace stackTrace) {
        _setState(
          state.copyWith(
            phase: LiveVoicePhase.error,
            errorText: error.toString(),
          ),
        );
      },
      onDone: () {
        _handleSocketDone();
      },
      cancelOnError: true,
    );

    _sendControl(<String, Object?>{
      'type': 'session.start',
      'threadId': threadId,
      'resumeSessionId': _resumeSessionId,
      'resumeHandle': _resumeHandle,
    });
  }

  Future<void> _closeSocket() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _channel?.sink.close();
    _channel = null;
    _sessionReady = false;
  }

  Future<void> _handleSocketDone() async {
    _socketSubscription = null;
    _channel = null;
    _sessionReady = false;
    _preReadyInputBuffer.clear();
    _lastMicrophoneChunkAtMs = 0;
    _microphoneStartAttemptAtMs = 0;
    _microphoneStartupRetryCount = 0;
    _microphoneStartupWatchdog?.cancel();
    _microphoneStartupWatchdog = null;
    final shouldReconnect =
        !_disconnectRequested && _threadId != null && _reconnectAttempts < 1;
    await _audioPlayer.stop();

    if (!shouldReconnect) {
      await _stopMicrophone(nextPhase: LiveVoicePhase.disconnected);
      await _releaseCallAudioConfiguration();
      _setState(
        state.copyWith(
          phase: state.phase == LiveVoicePhase.error
              ? LiveVoicePhase.error
              : LiveVoicePhase.disconnected,
          microphoneEnabled: false,
        ),
      );
      return;
    }

    _reconnectAttempts += 1;
    _suspendInputStreaming = false;
    _sessionReady = false;
    _preReadyInputBuffer.clear();
    _speechDetectedSinceLastFlush = false;
    _lastSpeechDetectedMs = 0;
    _lastMicrophoneChunkAtMs = 0;
    _microphoneStartAttemptAtMs = 0;
    _microphoneStartupRetryCount = 0;
    _pendingInputFlushTimer?.cancel();
    _pendingInputFlushTimer = null;
    _microphoneStartupWatchdog?.cancel();
    _microphoneStartupWatchdog = null;
    _setState(
      state.copyWith(
        phase: LiveVoicePhase.reconnecting,
        microphoneEnabled: false,
        inputStreamingSuspended: false,
      ),
    );
    await _stopMicrophone(nextPhase: LiveVoicePhase.reconnecting);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _ensureCallAudioConfigured();
    await _openSocket();
  }

  void _handleSocketEvent(dynamic event) {
    if (event is String) {
      final decoded = jsonDecode(event) as Map<String, dynamic>;
      final type = decoded['type'] as String? ?? '';
      switch (type) {
        case 'session.ready':
          _resumeSessionId = decoded['sessionId'] as String?;
          _suspendInputStreaming = false;
          _sessionReady = true;
          _setState(
            state.copyWith(
              phase: LiveVoicePhase.listening,
              model: decoded['model'] as String?,
              fallbackUsed: decoded['fallbackUsed'] as bool? ?? false,
              acceptanceNotes: List<String>.from(
                decoded['acceptance'] as List? ?? const <String>[],
              ),
              inputStreamingSuspended: false,
              clearErrorText: true,
            ),
          );
          _flushBufferedInputAudio();
          if (_microphoneDesired && _microphoneSubscription == null) {
            unawaited(_startMicrophone());
          }
          return;
        case 'session.resumption':
          _resumeSessionId = decoded['sessionId'] as String?;
          _resumeHandle = decoded['handle'] as String?;
          return;
        case 'transcript.input.partial':
          _handleTranscriptUpdate(
            turnId: decoded['turnId'] as String?,
            speaker: LiveVoiceSpeaker.user,
            text: decoded['text'] as String?,
            isPartial: true,
          );
          return;
        case 'transcript.input.final':
          _handleTranscriptUpdate(
            turnId: decoded['turnId'] as String?,
            speaker: LiveVoiceSpeaker.user,
            text: decoded['text'] as String?,
            isPartial: false,
          );
          return;
        case 'transcript.output.partial':
          _activeTurnId = decoded['turnId'] as String? ?? _activeTurnId;
          unawaited(_prepareAssistantPlayback());
          _handleTranscriptUpdate(
            turnId: decoded['turnId'] as String?,
            speaker: LiveVoiceSpeaker.assistant,
            text: decoded['text'] as String?,
            isPartial: true,
          );
          return;
        case 'transcript.output.final':
          _handleTranscriptUpdate(
            turnId: decoded['turnId'] as String?,
            speaker: LiveVoiceSpeaker.assistant,
            text: decoded['text'] as String?,
            isPartial: false,
          );
          return;
        case 'assistant.interrupted':
          unawaited(_audioPlayer.stop());
          _suspendInputStreaming = false;
          _setState(
            state.copyWith(
              phase: LiveVoicePhase.listening,
              inputStreamingSuspended: false,
            ),
          );
          return;
        case 'assistant.turn_complete':
          _activeTurnId = null;
          _suspendInputStreaming = false;
          _setState(
            state.copyWith(
              phase: state.microphoneEnabled
                  ? LiveVoicePhase.listening
                  : LiveVoicePhase.listening,
              clearPartialTranscriptText: true,
              clearPartialAssistantText: true,
              inputStreamingSuspended: false,
            ),
          );
          return;
        case 'session.waiting_for_input':
          _activeTurnId = null;
          _suspendInputStreaming = false;
          _setState(
            state.copyWith(
              phase: state.microphoneEnabled
                  ? LiveVoicePhase.listening
                  : LiveVoicePhase.listening,
              clearPartialTranscriptText: true,
              clearPartialAssistantText: true,
              inputStreamingSuspended: false,
            ),
          );
          return;
        case 'error':
          _suspendInputStreaming = false;
          _setState(
            state.copyWith(
              phase: LiveVoicePhase.error,
              errorText:
                  decoded['detail'] as String? ?? decoded['code'] as String?,
              microphoneEnabled: false,
              inputStreamingSuspended: false,
            ),
          );
          return;
        case 'session.closed':
          unawaited(_closeSocket());
          _suspendInputStreaming = false;
          final reason = decoded['reason'] as String?;
          final code = decoded['code'];
          _setState(
            state.copyWith(
              phase: LiveVoicePhase.disconnected,
              microphoneEnabled: false,
              inputStreamingSuspended: false,
              errorText: (reason != null && reason.isNotEmpty)
                  ? '接続が閉じられました: $reason'
                  : code != null
                  ? '接続が閉じられました: code=$code'
                  : '接続が閉じられました。',
              clearModel: true,
            ),
          );
          return;
      }
    }

    if (event is List<int>) {
      final bytes = Uint8List.fromList(event);
      if (bytes.isEmpty) {
        return;
      }
      unawaited(_prepareAssistantPlayback());
      unawaited(_audioPlayer.enqueue(bytes));
    }
  }

  void _handleTranscriptUpdate({
    required String? turnId,
    required LiveVoiceSpeaker speaker,
    required String? text,
    required bool isPartial,
  }) {
    final resolvedTurnId = turnId ?? _activeTurnId;
    final incomingText = text?.trim();
    if (resolvedTurnId == null ||
        incomingText == null ||
        incomingText.isEmpty) {
      return;
    }
    _activeTurnId = resolvedTurnId;
    final previousEntry = state.transcriptEntries.lastWhere(
      (entry) => entry.turnId == resolvedTurnId && entry.speaker == speaker,
      orElse: () => LiveVoiceTranscriptEntry(
        turnId: resolvedTurnId,
        speaker: speaker,
        text: '',
        isPartial: true,
      ),
    );
    final resolvedText = _mergeTranscriptText(previousEntry.text, incomingText);

    _setState(
      state.copyWith(
        phase: speaker == LiveVoiceSpeaker.assistant
            ? LiveVoicePhase.speaking
            : state.phase,
        transcriptText: !isPartial && speaker == LiveVoiceSpeaker.user
            ? resolvedText
            : null,
        assistantText: !isPartial && speaker == LiveVoiceSpeaker.assistant
            ? resolvedText
            : null,
        partialTranscriptText: isPartial && speaker == LiveVoiceSpeaker.user
            ? resolvedText
            : null,
        partialAssistantText: isPartial && speaker == LiveVoiceSpeaker.assistant
            ? resolvedText
            : null,
        clearPartialTranscriptText:
            !isPartial && speaker == LiveVoiceSpeaker.user,
        clearPartialAssistantText:
            !isPartial && speaker == LiveVoiceSpeaker.assistant,
        transcriptEntries: _mergeTranscriptEntry(
          state.transcriptEntries,
          LiveVoiceTranscriptEntry(
            turnId: resolvedTurnId,
            speaker: speaker,
            text: resolvedText,
            isPartial: isPartial,
          ),
        ),
      ),
    );
  }

  Future<void> _prepareAssistantPlayback() async {
    _setState(
      state.copyWith(
        phase: LiveVoicePhase.speaking,
        microphoneEnabled: _microphoneSubscription != null,
        inputStreamingSuspended: false,
      ),
    );
  }

  Future<void> _startMicrophone() async {
    if (_microphoneSubscription != null) {
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw const VoiceControllerException('マイクの権限がありません。');
    }

    await _ensureCallAudioConfigured();
    final iosRecorder = _recorder.ios;
    if (iosRecorder != null) {
      await iosRecorder.manageAudioSession(false);
    }
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: false,
        echoCancel: true,
        noiseSuppress: false,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceCommunication,
          audioManagerMode: AudioManagerMode.modeInCommunication,
          speakerphone: false,
        ),
        iosConfig: IosRecordConfig(
          categoryOptions: <IosAudioCategoryOption>[
            IosAudioCategoryOption.defaultToSpeaker,
            IosAudioCategoryOption.allowBluetooth,
            IosAudioCategoryOption.allowBluetoothA2DP,
          ],
        ),
      ),
    );
    _microphoneStartAttemptAtMs = DateTime.now().millisecondsSinceEpoch;
    _lastMicrophoneChunkAtMs = 0;
    _microphoneSubscription = stream.listen((Uint8List chunk) {
      _appendInputChunk(chunk);
    });
    _armMicrophoneStartupWatchdog();
    _setState(
      state.copyWith(
        microphoneEnabled: true,
        phase: LiveVoicePhase.listening,
        inputStreamingSuspended: _suspendInputStreaming,
        clearErrorText: true,
      ),
    );
  }

  Future<void> _stopMicrophone({
    LiveVoicePhase nextPhase = LiveVoicePhase.listening,
    bool shouldFlushServerAudio = true,
  }) async {
    _microphoneStartupWatchdog?.cancel();
    _microphoneStartupWatchdog = null;
    await _microphoneSubscription?.cancel();
    _microphoneSubscription = null;
    _inputAudioBuffer.clear();
    _preReadyInputBuffer.clear();
    _speechDetectedSinceLastFlush = false;
    _lastSpeechDetectedMs = 0;
    _lastMicrophoneChunkAtMs = 0;
    _microphoneStartAttemptAtMs = 0;
    _pendingInputFlushTimer?.cancel();
    _pendingInputFlushTimer = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (shouldFlushServerAudio && _channel != null && _sessionReady) {
      _sendControl(const <String, Object?>{'type': 'audio.flush'});
    }
    _setState(
      state.copyWith(
        microphoneEnabled: false,
        phase: nextPhase,
        inputStreamingSuspended: false,
      ),
    );
  }

  Future<void> _ensureCallAudioConfigured({
    bool refreshOutputRoute = false,
  }) async {
    if (_callAudioConfigured && !refreshOutputRoute) {
      return;
    }
    await _callAudioConfigurator.activate(
      refreshOutputRoute: refreshOutputRoute,
    );
    _callAudioConfigured = true;
  }

  Future<void> _releaseCallAudioConfiguration() async {
    if (!_callAudioConfigured) {
      return;
    }
    await _callAudioConfigurator.deactivate();
    _callAudioConfigured = false;
  }

  void _appendInputChunk(Uint8List chunk) {
    _lastMicrophoneChunkAtMs = DateTime.now().millisecondsSinceEpoch;
    _microphoneStartupWatchdog?.cancel();
    _microphoneStartupWatchdog = null;
    final inputLevel = _calculateInputLevel(chunk);
    final speechActivity = _calculateSpeechActivity(chunk);
    _pushInputLevel(inputLevel);
    _trackInputTurnBoundary(speechActivity);
    if (_channel == null) {
      _inputAudioBuffer.clear();
      _preReadyInputBuffer.clear();
      return;
    }
    if (!_sessionReady) {
      _bufferPreReadyAudio(chunk);
      return;
    }
    if (_preReadyInputBuffer.length > 0) {
      _flushBufferedInputAudio();
    }

    _inputAudioBuffer.add(chunk);
    final bytes = _inputAudioBuffer.toBytes();
    const frameSize = 640;
    if (bytes.length < frameSize) {
      return;
    }

    var offset = 0;
    while (bytes.length - offset >= frameSize) {
      final frame = Uint8List.sublistView(bytes, offset, offset + frameSize);
      _channel?.sink.add(frame);
      offset += frameSize;
    }

    _inputAudioBuffer.clear();
    if (offset < bytes.length) {
      _inputAudioBuffer.add(Uint8List.sublistView(bytes, offset));
    }
  }

  void _pushInputLevel(double nextLevel) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastInputLevelUiUpdateMs < 48) {
      return;
    }
    _lastInputLevelUiUpdateMs = nowMs;
    final history = [...state.inputLevelHistory, nextLevel];
    const maxSamples = 20;
    final trimmed = history.length <= maxSamples
        ? history
        : history.sublist(history.length - maxSamples);
    _setState(
      state.copyWith(inputLevelHistory: List<double>.unmodifiable(trimmed)),
    );
  }

  double _calculateInputLevel(Uint8List chunk) {
    if (chunk.length < 2) {
      return 0;
    }

    final byteData = ByteData.sublistView(chunk);
    var sampleCount = 0;
    var energy = 0.0;
    var peak = 0.0;
    for (var offset = 0; offset + 1 < chunk.length; offset += 2) {
      final normalized =
          byteData.getInt16(offset, Endian.little).abs() / 32768.0;
      energy += normalized * normalized;
      peak = math.max(peak, normalized);
      sampleCount += 1;
    }
    if (sampleCount == 0) {
      return 0;
    }
    final rms = math.sqrt(energy / sampleCount);
    final emphasized = math.max(peak * 0.95, rms * 2.6);
    final normalized = math.sqrt(emphasized).clamp(0.0, 1.0) * 1.2;
    return normalized.clamp(0.05, 1.0);
  }

  double _calculateSpeechActivity(Uint8List chunk) {
    if (chunk.length < 2) {
      return 0;
    }

    final byteData = ByteData.sublistView(chunk);
    var sampleCount = 0;
    var energy = 0.0;
    var peak = 0.0;
    for (var offset = 0; offset + 1 < chunk.length; offset += 2) {
      final normalized =
          byteData.getInt16(offset, Endian.little).abs() / 32768.0;
      energy += normalized * normalized;
      peak = math.max(peak, normalized);
      sampleCount += 1;
    }
    if (sampleCount == 0) {
      return 0;
    }
    final rms = math.sqrt(energy / sampleCount);
    return math.max(peak * 0.9, rms * 1.9).clamp(0.0, 1.0);
  }

  void _sendControl(Map<String, Object?> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void _trackInputTurnBoundary(double speechActivity) {
    if (_microphoneSubscription == null || _channel == null || !_sessionReady) {
      return;
    }

    const speechThreshold = 0.085;
    const silenceFlushDelay = Duration(milliseconds: 340);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (speechActivity >= speechThreshold) {
      _speechDetectedSinceLastFlush = true;
      _lastSpeechDetectedMs = nowMs;
      _pendingInputFlushTimer?.cancel();
      _pendingInputFlushTimer = null;
      return;
    }

    if (!_speechDetectedSinceLastFlush) {
      return;
    }
    if (nowMs - _lastSpeechDetectedMs < 120) {
      return;
    }
    if (_pendingInputFlushTimer != null) {
      return;
    }

    _pendingInputFlushTimer = Timer(silenceFlushDelay, () {
      _pendingInputFlushTimer = null;
      final idleMs =
          DateTime.now().millisecondsSinceEpoch - _lastSpeechDetectedMs;
      if (!_speechDetectedSinceLastFlush ||
          _channel == null ||
          !_sessionReady ||
          idleMs < 120) {
        return;
      }
      _speechDetectedSinceLastFlush = false;
      _sendControl(const <String, Object?>{'type': 'audio.flush'});
    });
  }

  void _bufferPreReadyAudio(Uint8List chunk) {
    _preReadyInputBuffer.add(chunk);
    const maxBufferedBytes = 64 * 1024;
    final bytes = _preReadyInputBuffer.toBytes();
    if (bytes.length <= maxBufferedBytes) {
      _preReadyInputBuffer.clear();
      _preReadyInputBuffer.add(bytes);
      return;
    }
    final trimmed = Uint8List.sublistView(
      bytes,
      bytes.length - maxBufferedBytes,
    );
    _preReadyInputBuffer.clear();
    _preReadyInputBuffer.add(trimmed);
  }

  void _flushBufferedInputAudio() {
    if (!_sessionReady ||
        _channel == null ||
        _preReadyInputBuffer.length == 0) {
      return;
    }
    final bytes = _preReadyInputBuffer.toBytes();
    _preReadyInputBuffer.clear();
    _inputAudioBuffer.add(bytes);
  }

  void _armMicrophoneStartupWatchdog() {
    _microphoneStartupWatchdog?.cancel();
    final startedAtMs = _microphoneStartAttemptAtMs;
    if (startedAtMs == 0) {
      return;
    }
    _microphoneStartupWatchdog = Timer(const Duration(milliseconds: 1200), () {
      _microphoneStartupWatchdog = null;
      if (_microphoneSubscription == null ||
          !_microphoneDesired ||
          _lastMicrophoneChunkAtMs >= startedAtMs ||
          _microphoneStartupRetryCount >= 1) {
        return;
      }
      _microphoneStartupRetryCount += 1;
      unawaited(_restartMicrophoneAfterStartupTimeout());
    });
  }

  Future<void> _restartMicrophoneAfterStartupTimeout() async {
    if (_microphoneSubscription == null || !_microphoneDesired) {
      return;
    }
    await _stopMicrophone(
      nextPhase: state.phase,
      shouldFlushServerAudio: false,
    );
    if (!_microphoneDesired) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await _startMicrophone();
  }

  void _setState(LiveVoiceUiState next) {
    if (_stateNotifier.value == next) {
      return;
    }
    _stateNotifier.value = next;
  }
}

List<LiveVoiceTranscriptEntry> _mergeTranscriptEntry(
  List<LiveVoiceTranscriptEntry> current,
  LiveVoiceTranscriptEntry next,
) {
  final updated = current.toList(growable: true);
  final index = updated.lastIndexWhere(
    (entry) => entry.turnId == next.turnId && entry.speaker == next.speaker,
  );
  if (index == -1) {
    updated.add(next);
  } else {
    updated[index] = updated[index].copyWith(
      text: next.text,
      isPartial: next.isPartial,
    );
  }
  return List<LiveVoiceTranscriptEntry>.unmodifiable(updated);
}

String _mergeTranscriptText(String previous, String incoming) {
  if (previous.isEmpty) {
    return incoming;
  }
  if (incoming.isEmpty || previous == incoming) {
    return previous;
  }
  if (incoming.startsWith(previous) || incoming.contains(previous)) {
    return incoming;
  }
  if (previous.startsWith(incoming) || previous.contains(incoming)) {
    return previous;
  }
  if (previous.endsWith(incoming)) {
    return previous;
  }
  return '$previous$incoming';
}

class DevicePcmAudioPlayer {
  DevicePcmAudioPlayer();

  final Queue<Uint8List> _queue = Queue<Uint8List>();
  static const _targetFeedBytes = 14_400;
  Future<void> Function()? onPlatformAudioReady;
  bool _initialized = false;
  bool _drainScheduled = false;
  bool _playbackStarted = false;
  int _queuedByteLength = 0;

  Future<void> enqueue(Uint8List bytes) async {
    if (bytes.isEmpty) {
      return;
    }
    await _ensureInitialized();
    _queue.add(bytes);
    _queuedByteLength += bytes.length;
    if (!_playbackStarted && _queuedByteLength < _targetFeedBytes) {
      return;
    }
    FlutterPcmSound.start();
    _playbackStarted = true;
    await _drain();
  }

  Future<void> stop() async {
    _queue.clear();
    _queuedByteLength = 0;
    _playbackStarted = false;
    if (_initialized) {
      await FlutterPcmSound.release();
      _initialized = false;
      FlutterPcmSound.setFeedCallback(null);
    }
  }

  Future<void> dispose() {
    return stop();
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await FlutterPcmSound.setup(
      sampleRate: 24000,
      channelCount: 1,
      iosAudioCategory: IosAudioCategory.playAndRecord,
      androidAudioUsage: AndroidAudioUsage.voiceCommunication,
      androidAudioContentType: AndroidAudioContentType.speech,
    );
    await onPlatformAudioReady?.call();
    await FlutterPcmSound.setFeedThreshold(9600);
    FlutterPcmSound.setFeedCallback((_) {
      if (_drainScheduled) {
        return;
      }
      _drainScheduled = true;
      scheduleMicrotask(() async {
        _drainScheduled = false;
        await _drain();
      });
    });
    _initialized = true;
  }

  Future<void> _drain() async {
    if (!_initialized || _queue.isEmpty) {
      return;
    }
    final builder = BytesBuilder(copy: false);
    while (_queue.isNotEmpty && builder.length < _targetFeedBytes) {
      final chunk = _queue.removeFirst();
      _queuedByteLength -= chunk.length;
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) {
      return;
    }
    await FlutterPcmSound.feed(_pcmBytesToFrames(bytes));
  }
}

class _LiveVoiceCallAudioConfigurator {
  audio_session.AudioSession? _session;
  audio_session.AndroidAudioManager? _androidAudioManager;

  Future<void> activate({bool refreshOutputRoute = false}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }

    final session = _session ??= await audio_session.AudioSession.instance;
    final configuration = _voiceCallAudioSessionConfiguration();
    await session.configure(configuration);
    await session.setActive(
      true,
      avAudioSessionSetActiveOptions:
          audio_session.AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: configuration.androidAudioAttributes,
      androidAudioFocusGainType: configuration.androidAudioFocusGainType,
      androidWillPauseWhenDucked: configuration.androidWillPauseWhenDucked,
    );

    if (Platform.isAndroid) {
      await _applyAndroidCommunicationRoute(
        refreshOutputRoute: refreshOutputRoute,
      );
    }
  }

  Future<void> deactivate() async {
    if (Platform.isAndroid) {
      final manager = _androidAudioManager ??=
          audio_session.AndroidAudioManager();
      try {
        await manager.clearCommunicationDevice();
      } catch (_) {}
      try {
        await manager.setSpeakerphoneOn(false);
      } catch (_) {}
      try {
        await manager.setMode(audio_session.AndroidAudioHardwareMode.normal);
      } catch (_) {}
    }

    final session = _session;
    if (session == null) {
      return;
    }
    try {
      await session.setActive(
        false,
        avAudioSessionSetActiveOptions: audio_session
            .AVAudioSessionSetActiveOptions
            .notifyOthersOnDeactivation,
      );
    } catch (_) {}
  }

  Future<void> _applyAndroidCommunicationRoute({
    required bool refreshOutputRoute,
  }) async {
    final manager = _androidAudioManager ??=
        audio_session.AndroidAudioManager();
    try {
      await manager.setMode(
        audio_session.AndroidAudioHardwareMode.inCommunication,
      );
    } catch (_) {}

    if (!refreshOutputRoute) {
      return;
    }

    try {
      final devices = await manager.getAvailableCommunicationDevices();
      final preferred = _pickPreferredCommunicationDevice(devices);
      if (preferred != null) {
        await manager.setCommunicationDevice(preferred);
        return;
      }
    } catch (_) {}

    try {
      await manager.setSpeakerphoneOn(false);
    } catch (_) {}
  }
}

audio_session.AndroidAudioDeviceInfo? _pickPreferredCommunicationDevice(
  List<audio_session.AndroidAudioDeviceInfo> devices,
) {
  for (final device in devices) {
    if (!device.isSink) {
      continue;
    }
    if (device.type == audio_session.AndroidAudioDeviceType.bluetoothSco ||
        device.type == audio_session.AndroidAudioDeviceType.usbHeadset ||
        device.type == audio_session.AndroidAudioDeviceType.wiredHeadset ||
        device.type == audio_session.AndroidAudioDeviceType.wiredHeadphones) {
      return device;
    }
  }

  for (final device in devices) {
    if (!device.isSink) {
      continue;
    }
    if (device.type == audio_session.AndroidAudioDeviceType.builtInEarpiece) {
      return device;
    }
  }

  for (final device in devices) {
    if (!device.isSink) {
      continue;
    }
    if (device.type == audio_session.AndroidAudioDeviceType.builtInSpeaker ||
        device.type ==
            audio_session.AndroidAudioDeviceType.builtInSpeakerSafe) {
      return device;
    }
  }

  return null;
}

audio_session.AudioSessionConfiguration _voiceCallAudioSessionConfiguration() {
  return audio_session.AudioSessionConfiguration(
    avAudioSessionCategory: audio_session.AVAudioSessionCategory.playAndRecord,
    avAudioSessionCategoryOptions:
        audio_session.AVAudioSessionCategoryOptions.allowBluetooth |
        audio_session.AVAudioSessionCategoryOptions.allowBluetoothA2dp |
        audio_session.AVAudioSessionCategoryOptions.defaultToSpeaker,
    avAudioSessionMode: audio_session.AVAudioSessionMode.voiceChat,
    avAudioSessionSetActiveOptions:
        audio_session.AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
    androidAudioAttributes: const audio_session.AndroidAudioAttributes(
      contentType: audio_session.AndroidAudioContentType.speech,
      usage: audio_session.AndroidAudioUsage.voiceCommunication,
    ),
    androidAudioFocusGainType: audio_session.AndroidAudioFocusGainType.gain,
    androidWillPauseWhenDucked: false,
  );
}

class VoiceControllerException implements Exception {
  const VoiceControllerException(this.message);

  final String message;

  @override
  String toString() => message;
}

Uri _resolveBackendWsUri() {
  const explicit = String.fromEnvironment('BACKEND_WS_URL', defaultValue: '');
  if (explicit.isNotEmpty) {
    return Uri.parse(explicit);
  }

  const baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  final baseUri = Uri.parse(baseUrl);
  final scheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
  return baseUri.replace(scheme: scheme, path: '/v1/live/voice');
}

PcmArrayInt16 _pcmBytesToFrames(Uint8List bytes) {
  final byteData = ByteData.sublistView(bytes);
  final values = List<int>.generate(
    bytes.length ~/ 2,
    (int index) => byteData.getInt16(index * 2, Endian.little),
    growable: false,
  );
  return PcmArrayInt16.fromList(values);
}
