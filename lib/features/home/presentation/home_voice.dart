import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordedVoiceClip {
  const RecordedVoiceClip({
    required this.audioBytes,
    required this.mimeType,
    required this.durationMs,
  });

  final Uint8List audioBytes;
  final String mimeType;
  final int durationMs;
}

abstract class VoiceRecorderController {
  Future<bool> ensurePermission();

  Future<void> start();

  Future<RecordedVoiceClip?> stop();

  Future<void> cancel();

  Future<void> dispose();
}

class DeviceVoiceRecorderController implements VoiceRecorderController {
  DeviceVoiceRecorderController() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  String? _activePath;
  DateTime? _startedAt;

  @override
  Future<bool> ensurePermission() {
    return _recorder.hasPermission();
  }

  @override
  Future<void> start() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) {
      throw const VoiceControllerException('マイクの権限がありません。');
    }

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}${Platform.pathSeparator}voice-input-${DateTime.now().microsecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: path,
    );
    _activePath = path;
    _startedAt = DateTime.now();
  }

  @override
  Future<RecordedVoiceClip?> stop() async {
    final startedAt = _startedAt;
    final path = await _recorder.stop();
    _startedAt = null;
    _activePath = null;
    if (path == null || startedAt == null) {
      return null;
    }

    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }

    final bytes = await file.readAsBytes();
    unawaited(_deleteIfExists(path));
    final durationMs = DateTime.now()
        .difference(startedAt)
        .inMilliseconds
        .clamp(0, 20000)
        .toInt();

    return RecordedVoiceClip(
      audioBytes: bytes,
      mimeType: 'audio/wav',
      durationMs: durationMs,
    );
  }

  @override
  Future<void> cancel() async {
    final activePath = _activePath;
    _activePath = null;
    _startedAt = null;
    await _recorder.cancel();
    if (activePath != null) {
      unawaited(_deleteIfExists(activePath));
    }
  }

  @override
  Future<void> dispose() {
    return _recorder.dispose();
  }
}

abstract class VoicePlayerController {
  Future<void> play(Uint8List audioBytes, {required String mimeType});

  Future<void> stop();

  Future<void> dispose();
}

class DeviceVoicePlayerController implements VoicePlayerController {
  DeviceVoicePlayerController() : _player = AudioPlayer();

  final AudioPlayer _player;
  String? _activePath;

  @override
  Future<void> play(Uint8List audioBytes, {required String mimeType}) async {
    await stop();
    final directory = await getTemporaryDirectory();
    final extension = switch (mimeType) {
      'audio/mpeg' => 'mp3',
      'audio/mp3' => 'mp3',
      'audio/wav' => 'wav',
      _ => 'bin',
    };
    final path =
        '${directory.path}${Platform.pathSeparator}assistant-voice-${DateTime.now().microsecondsSinceEpoch}.$extension';
    final file = File(path);
    await file.writeAsBytes(audioBytes, flush: true);
    _activePath = path;

    try {
      await _player.setFilePath(path);
      await _player.play();
    } finally {
      if (_activePath == path) {
        _activePath = null;
        await _deleteIfExists(path);
      }
    }
  }

  @override
  Future<void> stop() async {
    final activePath = _activePath;
    _activePath = null;
    await _player.stop();
    if (activePath != null) {
      await _deleteIfExists(activePath);
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}

class VoiceControllerException implements Exception {
  const VoiceControllerException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<void> _deleteIfExists(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    return;
  }
  await file.delete();
}
