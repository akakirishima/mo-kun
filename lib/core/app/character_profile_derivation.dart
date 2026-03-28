import 'package:gdgoc_2026_prototype/core/app/app_models.dart';

const defaultRoomVisualPromptBase = [
  'cute pastel pixel-art isometric room',
  'fixed cozy bedroom layout viewed from a slightly top-down angle',
  'soft cozy room with gentle light and warm lived-in atmosphere',
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
    'character age hint: ${_agePromptHint(profile.age)}',
    'character presentation hint: ${profile.characterGender.promptHint}',
    'room palette hint: ${_appearancePromptHint(profile.appearancePreset.storageValue)}',
  ].join(', ');

  return DerivedCharacterProfileFields(
    personaPrompt: personaPrompt,
    visualPromptBase: visualPromptBase,
  );
}

String _agePromptHint(int age) {
  if (age <= 12) {
    return 'childlike young presentation';
  }
  if (age <= 17) {
    return 'teen presentation';
  }
  if (age <= 24) {
    return 'young adult presentation';
  }
  if (age <= 39) {
    return 'adult presentation';
  }
  if (age <= 59) {
    return 'mature adult presentation';
  }
  return 'older adult presentation';
}

String _appearancePromptHint(String preset) {
  switch (preset) {
    case 'sky':
      return 'pale blue and mist-white room palette with airy clear light';
    case 'forest':
      return 'sage green and natural wood room palette with calm grounded light';
    case 'sunset':
      return 'peach amber room palette with warm late-afternoon glow';
    case 'blossom':
    default:
      return 'soft pink and cream room palette with airy sweet pastel light';
  }
}
