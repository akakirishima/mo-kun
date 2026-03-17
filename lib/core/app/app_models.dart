enum ChatRole { user, assistant }

enum CharacterImageStatus { idle, generating, ready, failed }

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
    this.latestImageUrl,
    this.lastGeneratedAt,
    this.starterGreeting,
  });

  final String id;
  final String name;
  final String personaPrompt;
  final String visualPromptBase;
  final CharacterImageStatus imageStatus;
  final String? latestImageUrl;
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
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  final String? clientMessageId;
}

class PendingChatMessage {
  const PendingChatMessage({
    required this.clientMessageId,
    required this.threadId,
    required this.text,
    required this.createdAt,
    required this.failed,
  });

  final String clientMessageId;
  final String threadId;
  final String text;
  final DateTime createdAt;
  final bool failed;

  PendingChatMessage copyWith({bool? failed}) {
    return PendingChatMessage(
      clientMessageId: clientMessageId,
      threadId: threadId,
      text: text,
      createdAt: createdAt,
      failed: failed ?? this.failed,
    );
  }
}

class DailySummary {
  const DailySummary({
    required this.dateKey,
    required this.title,
    required this.mood,
    required this.doneThings,
    required this.reflection,
    required this.tomorrowNote,
    this.generatedAt,
  });

  final String dateKey;
  final String title;
  final String mood;
  final List<String> doneThings;
  final String reflection;
  final String tomorrowNote;
  final DateTime? generatedAt;
}

class CharacterImageVersion {
  const CharacterImageVersion({
    required this.id,
    required this.title,
    required this.promptExcerpt,
    required this.status,
    required this.generatedAt,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String promptExcerpt;
  final CharacterImageStatus status;
  final DateTime generatedAt;
  final String? imageUrl;
}
