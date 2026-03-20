import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gdgoc_2026_prototype/core/app/app_date.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_repository.dart';
import 'package:gdgoc_2026_prototype/core/app/character_profile_derivation.dart';
import 'package:gdgoc_2026_prototype/firebase_options.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FirebaseAppRepository implements AppRepository {
  FirebaseAppRepository._({
    required this.auth,
    required this.firestore,
    required this.storage,
    required this.client,
    required this.baseUri,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final http.Client client;
  final Uri baseUri;

  static Future<FirebaseAppRepository> create() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    final baseUrl = const String.fromEnvironment(
      'BACKEND_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );
    return FirebaseAppRepository._(
      auth: auth,
      firestore: FirebaseFirestore.instance,
      storage: FirebaseStorage.instance,
      client: http.Client(),
      baseUri: Uri.parse(baseUrl),
    );
  }

  @override
  Future<AppSession> initializeSession() async {
    final response = await _post('/v1/session/initialize', const {});
    return AppSession(
      userId: response['userId'] as String? ?? auth.currentUser!.uid,
      needsOnboarding: response['needsOnboarding'] as bool? ?? true,
      characterId: response['characterId'] as String?,
      threadId: response['threadId'] as String?,
    );
  }

  @override
  Future<AppSession> completeOnboarding(UserProfileInput input) async {
    final response = await _post('/v1/characters', {
      'displayName': input.displayName,
      'goal': input.goal,
      'partnerStyle': input.partnerStyle,
      'weakPoints': input.weakPoints,
    });
    await updateUserProfile(userId: auth.currentUser!.uid, profile: input);
    return AppSession(
      userId: auth.currentUser!.uid,
      needsOnboarding: false,
      characterId: response['characterId'] as String?,
      threadId: response['threadId'] as String?,
    );
  }

  @override
  Stream<UserProfileInput?> watchUserProfile(String userId) {
    return _userProfileDoc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      final data = snapshot.data() ?? const <String, dynamic>{};
      return UserProfileInput(
        displayName: data['displayName'] as String? ?? '',
        goal: data['goal'] as String? ?? '',
        partnerStyle: data['partnerStyle'] as String? ?? '',
        weakPoints: List<String>.from(data['weakPoints'] as List? ?? const []),
      );
    });
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required UserProfileInput profile,
  }) async {
    final derived = deriveCharacterProfileFields(profile);
    await _userProfileDoc(userId).set({
      'displayName': profile.displayName,
      'goal': profile.goal,
      'partnerStyle': profile.partnerStyle,
      'weakPoints': profile.weakPoints,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await firestore.collection('characters').doc(userId).set({
      'personaPrompt': derived.personaPrompt,
      'visualPromptBase': derived.visualPromptBase,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<List<ChatMessage>> watchChatMessages(String threadId) {
    return firestore
        .collection('chatThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(_mapMessage).toList(growable: false);
        });
  }

  @override
  Future<void> sendChatMessage({
    required String threadId,
    required String text,
    required String clientMessageId,
    Uint8List? imageBytes,
    String? imageMimeType,
    String? imageFilename,
  }) async {
    final token = await auth.currentUser!.getIdToken();
    final request =
        http.MultipartRequest('POST', baseUri.resolve('/v1/chat/messages'))
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['threadId'] = threadId
          ..fields['clientMessageId'] = clientMessageId;

    if (text.isNotEmpty) {
      request.fields['text'] = text;
    }
    if (imageBytes != null && imageBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: imageFilename ?? 'photo-input.jpg',
          contentType: _mediaTypeForImage(imageMimeType),
        ),
      );
    }

    final streamed = await client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Backend request failed: ${response.statusCode}');
    }
  }

  @override
  Future<VoiceChatResult> sendVoiceMessage({
    required String threadId,
    required Uint8List audioBytes,
    required String mimeType,
    required int durationMs,
    required String clientMessageId,
  }) async {
    final token = await auth.currentUser!.getIdToken();
    final request =
        http.MultipartRequest('POST', baseUri.resolve('/v1/chat/voice'))
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['threadId'] = threadId
          ..fields['clientMessageId'] = clientMessageId
          ..fields['durationMs'] = '$durationMs'
          ..files.add(
            http.MultipartFile.fromBytes(
              'audio',
              audioBytes,
              filename: 'voice-input.wav',
            ),
          );

    final streamed = await client.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Backend request failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final audioBase64 = decoded['assistantAudioBase64'] as String?;

    return VoiceChatResult(
      transcriptText: decoded['transcriptText'] as String? ?? '',
      assistantText: decoded['assistantText'] as String? ?? '',
      audioStatus: (decoded['audioStatus'] as String?) == 'ready'
          ? VoiceChatAudioStatus.ready
          : VoiceChatAudioStatus.failed,
      assistantAudioBytes: audioBase64 == null
          ? null
          : base64Decode(audioBase64),
      assistantAudioMimeType: decoded['assistantAudioMimeType'] as String?,
      userMessageId: decoded['userMessageId'] as String?,
      assistantMessageId: decoded['assistantMessageId'] as String?,
    );
  }

  @override
  Future<void> regenerateCharacterImage({
    String? title,
    String? reportText,
  }) async {
    await _post('/v1/characters/image', {
      if (title != null && title.isNotEmpty) 'title': title,
      if (reportText != null && reportText.isNotEmpty) 'reportText': reportText,
    });
  }

  @override
  Stream<CharacterSnapshot?> watchCharacter(String characterId) {
    return firestore.collection('characters').doc(characterId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        return null;
      }
      final data = snapshot.data()!;
      return CharacterSnapshot(
        id: snapshot.id,
        name: data['name'] as String? ?? 'Self',
        personaPrompt: data['personaPrompt'] as String? ?? '',
        visualPromptBase: data['visualPromptBase'] as String? ?? '',
        imageStatus: _parseImageStatus(
          data['imageGenerationStatus'] as String?,
        ),
        videoStatus: _parseVideoStatus(
          data['videoGenerationStatus'] as String?,
        ),
        latestImageUrl: data['lastGeneratedImageUrl'] as String?,
        latestVideoUrl: data['lastGeneratedVideoUrl'] as String?,
        latestSquareVideoUrl: data['lastGeneratedSquareVideoUrl'] as String?,
        posterImageUrl: data['lastVideoPosterImageUrl'] as String?,
        lastGeneratedAt: _parseTimestamp(data['lastImageGeneratedAt']),
        starterGreeting: data['starterGreeting'] as String?,
      );
    });
  }

  @override
  Stream<List<CharacterImageVersion>> watchImageHistory(String characterId) {
    return firestore
        .collection('characters')
        .doc(characterId)
        .collection('imageHistory')
        .orderBy('generatedAt', descending: true)
        .limit(12)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(_mapImageHistory).toList(growable: false);
        });
  }

  @override
  Stream<List<CharacterImageVersion>> watchDiaryImageHistory({
    required String characterId,
    required DateTime month,
  }) {
    final endBoundary = appDayBoundaryUtc(
      DateTime(month.year, month.month + 1, 1),
    );

    return firestore
        .collection('characters')
        .doc(characterId)
        .collection('imageHistory')
        .orderBy('generatedAt')
        .endAt([
          Timestamp.fromDate(
            endBoundary.subtract(const Duration(milliseconds: 1)),
          ),
        ])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(_mapImageHistory).toList(growable: false);
        });
  }

  @override
  Stream<DailySummary?> watchDailySummary({
    required String userId,
    required String dateKey,
  }) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('dailySummaries')
        .doc(dateKey)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }
          return _mapDailySummary(snapshot);
        });
  }

  @override
  Stream<DailyBubble?> watchDailyBubble({
    required String userId,
    required String dateKey,
  }) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('dailyBubbles')
        .doc(dateKey)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }
          final data = snapshot.data() ?? const <String, dynamic>{};
          return DailyBubble(
            dateKey: snapshot.id,
            text: data['text'] as String? ?? '',
            generatedAt: _parseTimestamp(data['generatedAt']),
            sourceDateKey: data['sourceDateKey'] as String?,
          );
        });
  }

  @override
  Stream<List<DailySummary>> watchMonthlyDailySummaries({
    required String userId,
    required DateTime month,
  }) {
    final firstDay = DateTime(month.year, month.month);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    return firestore
        .collection('users')
        .doc(userId)
        .collection('dailySummaries')
        .orderBy(FieldPath.documentId)
        .startAt([_dateKey(firstDay)])
        .endAt([_dateKey(lastDay)])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(_mapDailySummary).toList(growable: false);
        });
  }

  @override
  Stream<HomeBackgroundPreference?> watchHomeBackgroundPreference({
    required String userId,
  }) {
    return _homeBackgroundPreferencesDoc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      final data = snapshot.data() ?? const <String, dynamic>{};
      return HomeBackgroundPreference(
        themeId: data['homeBackgroundThemeId'] as String? ?? 'yuuyake',
        customImageUrl: data['homeBackgroundCustomImageUrl'] as String?,
        updatedAt: _parseTimestamp(data['updatedAt']),
      );
    });
  }

  @override
  Future<void> updateCharacterSettings({
    required String characterId,
    required CharacterSettings settings,
  }) async {
    await firestore.collection('characters').doc(characterId).set({
      'name': settings.name,
      'starterGreeting': settings.starterGreeting,
      'personaPrompt': settings.personaPrompt,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> selectHomeBackgroundTheme({
    required String userId,
    required String themeId,
  }) async {
    await _homeBackgroundPreferencesDoc(userId).set({
      'homeBackgroundThemeId': themeId,
      'homeBackgroundCustomImageUrl': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> uploadCustomHomeBackground({
    required String userId,
    required Uint8List imageBytes,
    required String imageMimeType,
    required String imageFilename,
  }) async {
    final preferencesRef = _homeBackgroundPreferencesDoc(userId);
    final existing = await preferencesRef.get();
    final existingData = existing.data() ?? const <String, dynamic>{};
    final currentThemeId =
        existingData['homeBackgroundThemeId'] as String? ?? 'yuuyake';
    final extension = _inferFileExtension(imageFilename, imageMimeType);
    final fileRef = storage.ref(
      'users/$userId/home_backgrounds/custom-${DateTime.now().microsecondsSinceEpoch}$extension',
    );

    await fileRef.putData(
      imageBytes,
      SettableMetadata(contentType: _normalizeImageContentType(imageMimeType)),
    );
    final downloadUrl = await fileRef.getDownloadURL();

    await preferencesRef.set({
      'homeBackgroundThemeId': currentThemeId,
      'homeBackgroundCustomImageUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> dispose() async {
    client.close();
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await auth.currentUser!.getIdToken();
    final response = await client.post(
      baseUri.resolve(path),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Backend request failed: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  ChatMessage _mapMessage(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return ChatMessage(
      id: snapshot.id,
      role: (data['role'] as String?) == 'assistant'
          ? ChatRole.assistant
          : ChatRole.user,
      text: data['text'] as String? ?? '',
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      clientMessageId: data['clientMessageId'] as String?,
      inputType: switch (data['inputType'] as String?) {
        'voice' => ChatInputType.voice,
        'photo' => ChatInputType.photo,
        _ => ChatInputType.text,
      },
      imageUrl: data['imageUrl'] as String?,
      imageAnalysis: _parsePhotoAnalysis(data['imageAnalysis']),
    );
  }

  CharacterImageStatus _parseImageStatus(String? value) {
    switch (value) {
      case 'generating':
        return CharacterImageStatus.generating;
      case 'ready':
        return CharacterImageStatus.ready;
      case 'failed':
        return CharacterImageStatus.failed;
      default:
        return CharacterImageStatus.idle;
    }
  }

  CharacterVideoStatus _parseVideoStatus(String? value) {
    switch (value) {
      case 'generating':
        return CharacterVideoStatus.generating;
      case 'ready':
        return CharacterVideoStatus.ready;
      case 'failed':
        return CharacterVideoStatus.failed;
      default:
        return CharacterVideoStatus.idle;
    }
  }

  DateTime? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  DailySummary _mapDailySummary(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return DailySummary(
      dateKey: snapshot.id,
      title: data['title'] as String? ?? '今日のまとめ',
      diaryBody: data['diaryBody'] as String? ?? '',
      mood: data['mood'] as String? ?? '',
      doneThings: List<String>.from(data['doneThings'] as List? ?? const []),
      reflection: data['reflection'] as String? ?? '',
      tomorrowNote: data['tomorrowNote'] as String? ?? '',
      generatedAt: _parseTimestamp(data['generatedAt']),
    );
  }

  String _dateKey(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }

  CharacterImageVersion _mapImageHistory(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    final generatedAt = _parseTimestamp(data['generatedAt']) ?? DateTime.now();
    return CharacterImageVersion(
      id: snapshot.id,
      title: data['title'] as String? ?? 'AI refresh',
      promptExcerpt: data['promptExcerpt'] as String? ?? '',
      status: _parseImageStatus(data['status'] as String?),
      generatedAt: generatedAt,
      imageUrl: data['imageUrl'] as String?,
      dateKey:
          data['dateKey'] as String? ??
          buildAppDateKeyFromDateTime(generatedAt),
    );
  }

  PhotoAnalysis? _parsePhotoAnalysis(Object? value) {
    if (value is! Map) {
      return null;
    }
    final data = Map<String, dynamic>.from(value);
    return PhotoAnalysis(
      category: data['category'] as String? ?? 'unknown',
      summary: data['summary'] as String? ?? '',
      activity: data['activity'] as String? ?? '',
      food: data['food'] as String? ?? '',
      locationGuess: data['locationGuess'] as String? ?? '',
      confidence: data['confidence'] as String? ?? 'low',
      needsConfirmation: data['needsConfirmation'] as bool? ?? false,
      confirmationPrompt: data['confirmationPrompt'] as String? ?? '',
      reactionHint: data['reactionHint'] as String? ?? '',
    );
  }

  MediaType _mediaTypeForImage(String? mimeType) {
    final normalized = mimeType?.trim();
    if (normalized == null || normalized.isEmpty) {
      return MediaType('image', 'jpeg');
    }

    final parts = normalized.split('/');
    if (parts.length != 2) {
      return MediaType('image', 'jpeg');
    }

    return MediaType(parts[0], parts[1]);
  }

  DocumentReference<Map<String, dynamic>> _homeBackgroundPreferencesDoc(
    String userId,
  ) {
    return firestore.collection('users').doc(userId).collection('preferences').doc('ui');
  }

  DocumentReference<Map<String, dynamic>> _userProfileDoc(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('profile');
  }

  String _normalizeImageContentType(String? mimeType) {
    final normalized = mimeType?.trim();
    if (normalized == null || normalized.isEmpty) {
      return 'image/jpeg';
    }
    return normalized;
  }

  String _inferFileExtension(String filename, String? mimeType) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < filename.length - 1) {
      return filename.substring(dotIndex);
    }
    return switch (_normalizeImageContentType(mimeType)) {
      'image/png' => '.png',
      'image/webp' => '.webp',
      _ => '.jpg',
    };
  }
}
