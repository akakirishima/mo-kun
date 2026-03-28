import 'dart:typed_data';

import 'package:gdgoc_2026_prototype/core/theme/app_appearance.dart';

enum ChatRole { user, assistant }

enum ChatTransport { http, live }

enum CharacterImageStatus { idle, generating, ready, failed }

enum CharacterVideoStatus { idle, generating, ready, failed }

enum ChatInputType { text, voice, photo }

enum VoiceChatAudioStatus { ready, failed }

const defaultAssistantVoiceName = 'Kore';

enum CharacterGender {
  female(
    storageValue: 'female',
    label: '女性',
    promptHint: 'feminine presentation with natural softness',
  ),
  male(
    storageValue: 'male',
    label: '男性',
    promptHint: 'masculine presentation with natural balance',
  ),
  nonBinary(
    storageValue: 'non_binary',
    label: 'どちらでもない',
    promptHint: 'androgynous non-binary presentation',
  );

  const CharacterGender({
    required this.storageValue,
    required this.label,
    required this.promptHint,
  });

  final String storageValue;
  final String label;
  final String promptHint;

  static CharacterGender fromStorageValue(String? value) {
    return CharacterGender.values.firstWhere(
      (gender) => gender.storageValue == value,
      orElse: () => CharacterGender.nonBinary,
    );
  }
}

class AssistantVoiceOption {
  const AssistantVoiceOption({
    required this.voiceName,
    required this.label,
    required this.description,
  });

  final String voiceName;
  final String label;
  final String description;
}

class AssistantVoicePreference {
  const AssistantVoicePreference({required this.voiceName, this.updatedAt});

  final String voiceName;
  final DateTime? updatedAt;
}

const assistantVoiceOptions = <AssistantVoiceOption>[
  AssistantVoiceOption(
    voiceName: 'Kore',
    label: 'Kore',
    description: '落ち着いていて芯のある声',
  ),
  AssistantVoiceOption(
    voiceName: 'Aoede',
    label: 'Aoede',
    description: '軽やかでやわらかい声',
  ),
  AssistantVoiceOption(
    voiceName: 'Puck',
    label: 'Puck',
    description: '明るく元気な声',
  ),
  AssistantVoiceOption(
    voiceName: 'Charon',
    label: 'Charon',
    description: '低めで情報が聞き取りやすい声',
  ),
  AssistantVoiceOption(
    voiceName: 'Achird',
    label: 'Achird',
    description: '親しみやすくフレンドリーな声',
  ),
  AssistantVoiceOption(
    voiceName: 'Sulafat',
    label: 'Sulafat',
    description: '温かく包むような声',
  ),
];

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
    required this.age,
    required this.characterGender,
    required this.appearancePreset,
  });

  final String displayName;
  final String goal;
  final String partnerStyle;
  final List<String> weakPoints;
  final int age;
  final CharacterGender characterGender;
  final AppAppearancePreset appearancePreset;
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
    this.latestSquareVideoUrl,
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
  final String? latestSquareVideoUrl;
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
    this.transport = ChatTransport.http,
    this.imageUrl,
    this.imageAnalysis,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  final String? clientMessageId;
  final ChatInputType inputType;
  final ChatTransport transport;
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

class DiaryShelfBook {
  const DiaryShelfBook({
    required this.monthStart,
    required this.monthLabel,
    required this.recordedDaysCount,
  });

  final DateTime monthStart;
  final String monthLabel;
  final int recordedDaysCount;
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

class HomeBackgroundPreference {
  const HomeBackgroundPreference({
    required this.themeId,
    this.customImageUrl,
    this.updatedAt,
  });

  final String themeId;
  final String? customImageUrl;
  final DateTime? updatedAt;

  bool get hasCustomImage =>
      customImageUrl != null && customImageUrl!.trim().isNotEmpty;

  HomeBackgroundPreference copyWith({
    String? themeId,
    String? customImageUrl,
    DateTime? updatedAt,
  }) {
    return HomeBackgroundPreference(
      themeId: themeId ?? this.themeId,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CharacterSettings {
  const CharacterSettings({
    required this.name,
    required this.starterGreeting,
    required this.personaPrompt,
  });

  final String name;
  final String starterGreeting;
  final String personaPrompt;
}
