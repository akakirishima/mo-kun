import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
       _backendUri = backendUri ?? _resolveBackendWsUri();

  final FirebaseAuth _auth;
  final AudioRecorder _recorder;
  final DevicePcmAudioPlayer _audioPlayer;
  final Uri _backendUri;
  final ValueNotifier<LiveVoiceUiState> _stateNotifier = ValueNotifier(
    LiveVoiceUiState.disconnected,
  );
  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _socketSubscription;
  StreamSubscription<Uint8List>? _microphoneSubscription;
  final BytesBuilder _inputAudioBuffer = BytesBuilder(copy: false);
  String? _activeTurnId;
  String? _threadId;
  String? _resumeSessionId;
  String? _resumeHandle;
  bool _disconnectRequested = false;
  int _reconnectAttempts = 0;

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
      _disconnectRequested = false;
      _reconnectAttempts = 0;
      _setState(
        state.copyWith(phase: LiveVoicePhase.connecting, clearErrorText: true),
      );

      await _openSocket();
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
  Future<void> toggleMicrophone() async {
    try {
      if (state.phase == LiveVoicePhase.connecting ||
          state.phase == LiveVoicePhase.reconnecting) {
        return;
      }

      if (_microphoneSubscription == null) {
        await _startMicrophone();
        return;
      }

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
    _reconnectAttempts = 0;
    await _stopMicrophone();
    await _closeSocket();
    await _audioPlayer.stop();
    _setState(
      LiveVoiceUiState.disconnected.copyWith(
        transcriptText: state.transcriptText,
        assistantText: state.assistantText,
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
  }

  Future<void> _handleSocketDone() async {
    _socketSubscription = null;
    _channel = null;
    final shouldReconnect =
        !_disconnectRequested && _threadId != null && _reconnectAttempts < 1;
    await _audioPlayer.stop();

    if (!shouldReconnect) {
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
    _setState(
      state.copyWith(
        phase: LiveVoicePhase.reconnecting,
        microphoneEnabled: false,
      ),
    );
    await _stopMicrophone();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _openSocket();
  }

  void _handleSocketEvent(dynamic event) {
    if (event is String) {
      final decoded = jsonDecode(event) as Map<String, dynamic>;
      final type = decoded['type'] as String? ?? '';
      switch (type) {
        case 'session.ready':
          _resumeSessionId = decoded['sessionId'] as String?;
          _setState(
            state.copyWith(
              phase: state.microphoneEnabled
                  ? LiveVoicePhase.listening
                  : LiveVoicePhase.listening,
              model: decoded['model'] as String?,
              fallbackUsed: decoded['fallbackUsed'] as bool? ?? false,
              acceptanceNotes: List<String>.from(
                decoded['acceptance'] as List? ?? const <String>[],
              ),
              clearErrorText: true,
            ),
          );
          return;
        case 'session.resumption':
          _resumeSessionId = decoded['sessionId'] as String?;
          _resumeHandle = decoded['handle'] as String?;
          return;
        case 'transcript.input.partial':
          final turnId = decoded['turnId'] as String?;
          if (turnId != null && turnId != _activeTurnId) {
            _activeTurnId = turnId;
            _setState(
              state.copyWith(
                clearPartialTranscriptText: true,
                clearPartialAssistantText: true,
              ),
            );
          }
          _setState(
            state.copyWith(
              partialTranscriptText: decoded['text'] as String?,
              clearPartialAssistantText: true,
            ),
          );
          return;
        case 'transcript.input.final':
          _activeTurnId = decoded['turnId'] as String? ?? _activeTurnId;
          _setState(
            state.copyWith(
              transcriptText: decoded['text'] as String?,
              clearPartialTranscriptText: true,
            ),
          );
          return;
        case 'transcript.output.partial':
          _activeTurnId = decoded['turnId'] as String? ?? _activeTurnId;
          unawaited(_prepareAssistantPlayback());
          _setState(
            state.copyWith(
              partialAssistantText: decoded['text'] as String?,
              phase: LiveVoicePhase.speaking,
              clearPartialTranscriptText: true,
            ),
          );
          return;
        case 'transcript.output.final':
          _activeTurnId = decoded['turnId'] as String? ?? _activeTurnId;
          _setState(
            state.copyWith(
              assistantText: decoded['text'] as String?,
              clearPartialAssistantText: true,
              clearPartialTranscriptText: true,
            ),
          );
          return;
        case 'assistant.interrupted':
          unawaited(_audioPlayer.stop());
          _setState(
            state.copyWith(
              phase: state.microphoneEnabled
                  ? LiveVoicePhase.listening
                  : LiveVoicePhase.listening,
            ),
          );
          return;
        case 'assistant.turn_complete':
          _activeTurnId = null;
          _setState(
            state.copyWith(
              phase: LiveVoicePhase.listening,
              clearPartialTranscriptText: true,
              clearPartialAssistantText: true,
            ),
          );
          return;
        case 'session.waiting_for_input':
          _activeTurnId = null;
          _setState(
            state.copyWith(
              phase: state.microphoneEnabled
                  ? LiveVoicePhase.listening
                  : LiveVoicePhase.listening,
              clearPartialTranscriptText: true,
              clearPartialAssistantText: true,
            ),
          );
          return;
        case 'error':
          _setState(
            state.copyWith(
              phase: LiveVoicePhase.error,
              errorText:
                  decoded['detail'] as String? ?? decoded['code'] as String?,
              microphoneEnabled: false,
            ),
          );
          return;
        case 'session.closed':
          unawaited(_closeSocket());
          final reason = decoded['reason'] as String?;
          final code = decoded['code'];
          _setState(
            state.copyWith(
              phase: LiveVoicePhase.disconnected,
              microphoneEnabled: false,
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
      _setState(state.copyWith(phase: LiveVoicePhase.speaking));
      unawaited(_audioPlayer.enqueue(bytes));
    }
  }

  Future<void> _prepareAssistantPlayback() async {
    if (_microphoneSubscription != null) {
      await _stopMicrophone(nextPhase: LiveVoicePhase.speaking);
      return;
    }
    _setState(
      state.copyWith(microphoneEnabled: false, phase: LiveVoicePhase.speaking),
    );
  }

  Future<void> _startMicrophone() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw const VoiceControllerException('マイクの権限がありません。');
    }

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    _microphoneSubscription = stream.listen((Uint8List chunk) {
      _appendInputChunk(chunk);
    });
    _setState(
      state.copyWith(
        microphoneEnabled: true,
        phase: LiveVoicePhase.listening,
        clearErrorText: true,
      ),
    );
  }

  Future<void> _stopMicrophone({
    LiveVoicePhase nextPhase = LiveVoicePhase.listening,
  }) async {
    await _microphoneSubscription?.cancel();
    _microphoneSubscription = null;
    _inputAudioBuffer.clear();
    try {
      await _recorder.stop();
    } catch (_) {}
    if (_channel != null) {
      _sendControl(const <String, Object?>{'type': 'audio.flush'});
    }
    _setState(state.copyWith(microphoneEnabled: false, phase: nextPhase));
  }

  void _appendInputChunk(Uint8List chunk) {
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

  void _sendControl(Map<String, Object?> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void _setState(LiveVoiceUiState next) {
    if (_stateNotifier.value == next) {
      return;
    }
    _stateNotifier.value = next;
  }
}

class DevicePcmAudioPlayer {
  DevicePcmAudioPlayer();

  final Queue<Uint8List> _queue = Queue<Uint8List>();
  static const _targetFeedBytes = 9_600;
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
    );
    await FlutterPcmSound.setFeedThreshold(4800);
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
