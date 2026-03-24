import 'package:gdgoc_2026_prototype/core/app/app_models.dart';

const defaultRoomVisualPromptBase = [
  'cute pastel pixel-art isometric room',
  'fixed cozy bedroom layout viewed from a slightly top-down angle',
  'pink walls, mint furniture, warm wooden floor, soft daylight',
  'bed on the left, desk and computer on the back wall, two windows, round rug, small table, sofa, cabinet, framed wall art',
  'the same room layout stays consistent across daily updates',
  'a cute companion character stays near the center of the room as the main focus',
  'wide horizontal composition showing the whole room',
];

class DerivedCharacterProfileFields {
  const DerivedCharacterProfileFields({
    required this.personaPrompt,
    required this.visualPromptBase,
  });

  final String personaPrompt;
  final String visualPromptBase;
}

DerivedCharacterProfileFields deriveCharacterProfileFields(
  UserProfileInput profile,
) {
  final weakPoints = profile.weakPoints.isEmpty
      ? '継続が途切れないように見守る'
      : '特に ${profile.weakPoints.join('、')} を気にかける';

  final personaPrompt = [
    'あなたはユーザー自身を投影した内なる声です。',
    'ユーザーの目標: ${profile.goal}',
    '話し方の方向性: ${profile.partnerStyle}',
    '注意点: $weakPoints',
    '立ち位置: 自分を整理し、次の一歩を促す。',
  ].join('\n');

  final visualPromptBase = [
    ...defaultRoomVisualPromptBase,
    if (profile.goal.trim().isNotEmpty) 'goal mood hint: ${profile.goal.trim()}',
    if (profile.partnerStyle.trim().isNotEmpty)
      'inner voice tone hint: ${profile.partnerStyle.trim()}',
  ].join(', ');

  return DerivedCharacterProfileFields(
    personaPrompt: personaPrompt,
    visualPromptBase: visualPromptBase,
  );
}
