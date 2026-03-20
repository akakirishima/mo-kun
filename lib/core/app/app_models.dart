import 'dart:typed_data';

enum ChatRole { user, assistant }

enum CharacterImageStatus { idle, generating, ready, failed }

enum CharacterVideoStatus { idle, generating, ready, failed }

enum ChatInputType { text, voice, photo }

enum VoiceChatAudioStatus { ready, failed }

class PhotoAnalysis {
  const PhotoAnalysis({
    required this.category,
    required this.summary,
    required this.activity,
    required this.food,
    required this.locationGuess,
    required this.confidence,
    required this.needsConfirmation,
    required this.confirmationPrompt,
    required this.reactionHint,
  });

  final String category;
  final String summary;
  final String activity;
  final String food;
  final String locationGuess;
  final String confidence;
  final bool needsConfirmation;
  final String confirmationPrompt;
  final String reactionHint;
}

class AppSession {
  const AppSession({
    required this.userId,
    required this.needsOnboarding,
    this.characterId,
    this.threadId,
  });

  final String userId;
  final bool needsOnboarding;
  final String? characterId;
  final String? threadId;

  AppSession copyWith({
    String? userId,
    bool? needsOnboarding,
    String? characterId,
    String? threadId,
  }) {
    return AppSession(
      userId: userId ?? this.userId,
      needsOnboarding: needsOnboarding ?? this.needsOnboarding,
      characterId: characterId ?? this.characterId,
      threadId: threadId ?? this.threadId,
    );
  }
}

class UserProfileInput {
  const UserProfileInput({
    required this.displayName,
    required this.goal,
    required this.partnerStyle,
    required this.weakPoints,
  });

  final String displayName;
  final String goal;
  final String partnerStyle;
  final List<String> weakPoints;
}

class CharacterSnapshot {
  const CharacterSnapshot({
    required this.id,
    required this.name,
    required this.personaPrompt,
    required this.visualPromptBase,
    required this.imageStatus,
    this.videoStatus = CharacterVideoStatus.idle,
    this.latestImageUrl,
    this.latestVideoUrl,
    this.posterImageUrl,
    this.lastGeneratedAt,
    this.starterGreeting,
  });

  final String id;
  final String name;
  final String personaPrompt;
  final String visualPromptBase;
  final CharacterImageStatus imageStatus;
  final CharacterVideoStatus videoStatus;
  final String? latestImageUrl;
  final String? latestVideoUrl;
  final String? posterImageUrl;
  final DateTime? lastGeneratedAt;
  final String? starterGreeting;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.clientMessageId,
    this.inputType = ChatInputType.text,
    this.imageUrl,
    this.imageAnalysis,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  final String? clientMessageId;
  final ChatInputType inputType;
  final String? imageUrl;
  final PhotoAnalysis? imageAnalysis;
}

class PendingChatMessage {
  const PendingChatMessage({
    required this.clientMessageId,
    required this.threadId,
    required this.text,
    required this.createdAt,
    required this.failed,
    this.localImagePath,
  });

  final String clientMessageId;
  final String threadId;
  final String text;
  final DateTime createdAt;
  final bool failed;
  final String? localImagePath;

  PendingChatMessage copyWith({bool? failed, String? localImagePath}) {
    return PendingChatMessage(
      clientMessageId: clientMessageId,
      threadId: threadId,
      text: text,
      createdAt: createdAt,
      failed: failed ?? this.failed,
      localImagePath: localImagePath ?? this.localImagePath,
    );
  }
}

class DailySummary {
  const DailySummary({
    required this.dateKey,
    required this.title,
    required this.diaryBody,
    required this.mood,
    required this.doneThings,
    required this.reflection,
    required this.tomorrowNote,
    this.generatedAt,
  });

  final String dateKey;
  final String title;
  final String diaryBody;
  final String mood;
  final List<String> doneThings;
  final String reflection;
  final String tomorrowNote;
  final DateTime? generatedAt;
}

class DailyBubble {
  const DailyBubble({
    required this.dateKey,
    required this.text,
    this.generatedAt,
    this.sourceDateKey,
  });

  final String dateKey;
  final String text;
  final DateTime? generatedAt;
  final String? sourceDateKey;
}

class CharacterImageVersion {
  const CharacterImageVersion({
    required this.id,
    required this.title,
    required this.promptExcerpt,
    required this.status,
    required this.generatedAt,
    this.imageUrl,
    this.dateKey,
  });

  final String id;
  final String title;
  final String promptExcerpt;
  final CharacterImageStatus status;
  final DateTime generatedAt;
  final String? imageUrl;
  final String? dateKey;
}

class VoiceChatResult {
  const VoiceChatResult({
    required this.transcriptText,
    required this.assistantText,
    required this.audioStatus,
    this.assistantAudioBytes,
    this.assistantAudioMimeType,
    this.userMessageId,
    this.assistantMessageId,
  });

  final String transcriptText;
  final String assistantText;
  final VoiceChatAudioStatus audioStatus;
  final Uint8List? assistantAudioBytes;
  final String? assistantAudioMimeType;
  final String? userMessageId;
  final String? assistantMessageId;
}
