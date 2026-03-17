import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gdgoc_2026_prototype/core/app/app_models.dart';
import 'package:gdgoc_2026_prototype/core/app/app_repository.dart';
import 'package:gdgoc_2026_prototype/firebase_options.dart';
import 'package:http/http.dart' as http;

class FirebaseAppRepository implements AppRepository {
  FirebaseAppRepository._({
    required this.auth,
    required this.firestore,
    required this.client,
    required this.baseUri,
  });

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
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
    return AppSession(
      userId: auth.currentUser!.uid,
      needsOnboarding: false,
      characterId: response['characterId'] as String?,
      threadId: response['threadId'] as String?,
    );
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
  }) async {
    await _post('/v1/chat/messages', {
      'threadId': threadId,
      'text': text,
      'clientMessageId': clientMessageId,
    });
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
        name: data['name'] as String? ?? 'Mori',
        personaPrompt: data['personaPrompt'] as String? ?? '',
        visualPromptBase: data['visualPromptBase'] as String? ?? '',
        imageStatus: _parseImageStatus(
          data['imageGenerationStatus'] as String?,
        ),
        latestImageUrl: data['lastGeneratedImageUrl'] as String?,
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
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return CharacterImageVersion(
                  id: doc.id,
                  title: data['title'] as String? ?? 'AI refresh',
                  promptExcerpt: data['promptExcerpt'] as String? ?? '',
                  status: _parseImageStatus(data['status'] as String?),
                  generatedAt:
                      _parseTimestamp(data['generatedAt']) ?? DateTime.now(),
                  imageUrl: data['imageUrl'] as String?,
                );
              })
              .toList(growable: false);
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
          final data = snapshot.data()!;
          return DailySummary(
            dateKey: snapshot.id,
            title: data['title'] as String? ?? '今日のまとめ',
            mood: data['mood'] as String? ?? '',
            doneThings: List<String>.from(
              data['doneThings'] as List? ?? const [],
            ),
            reflection: data['reflection'] as String? ?? '',
            tomorrowNote: data['tomorrowNote'] as String? ?? '',
            generatedAt: _parseTimestamp(data['generatedAt']),
          );
        });
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

  DateTime? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
