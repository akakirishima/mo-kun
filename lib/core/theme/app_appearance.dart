import 'package:flutter/material.dart';

enum AppAppearancePreset {
  blossom(
    storageValue: 'blossom',
    label: 'Blossom',
    description: 'やわらかいピンクとクリーム',
  ),
  sky(storageValue: 'sky', label: 'Sky', description: '空気感のあるブルーとミスト'),
  forest(storageValue: 'forest', label: 'Forest', description: '落ち着いたグリーンとセージ'),
  sunset(storageValue: 'sunset', label: 'Sunset', description: '夕方っぽいピーチとアンバー');

  const AppAppearancePreset({
    required this.storageValue,
    required this.label,
    required this.description,
  });

  final String storageValue;
  final String label;
  final String description;

  static AppAppearancePreset fromStorageValue(String? value) {
    return AppAppearancePreset.values.firstWhere(
      (preset) => preset.storageValue == value,
      orElse: () => AppAppearancePreset.blossom,
    );
  }
}

class AppAppearancePalette {
  const AppAppearancePalette({
    required this.preset,
    required this.displayName,
    required this.shortDescription,
    required this.previewGradient,
    required this.previewSurface,
    required this.previewAccent,
    required this.seedColor,
    required this.scaffoldBackgroundColor,
    required this.home,
    required this.chat,
    required this.diary,
    required this.image,
    required this.settings,
  });

  final AppAppearancePreset preset;
  final String displayName;
  final String shortDescription;
  final List<Color> previewGradient;
  final Color previewSurface;
  final Color previewAccent;
  final Color seedColor;
  final Color scaffoldBackgroundColor;
  final HomeAppearanceColors home;
  final ChatAppearanceColors chat;
  final DiaryAppearanceColors diary;
  final ImageAppearanceColors image;
  final SettingsAppearanceColors settings;

  static AppAppearancePalette fromPreset(AppAppearancePreset preset) {
    switch (preset) {
      case AppAppearancePreset.blossom:
        return AppAppearancePalette(
          preset: AppAppearancePreset.blossom,
          displayName: 'Blossom',
          shortDescription: 'Mori の部屋を甘めのパステルでまとめる',
          previewGradient: const [Color(0xFFFFE3EE), Color(0xFFFFF3F7)],
          previewSurface: const Color(0xFFFFD8E9),
          previewAccent: const Color(0xFFE275A9),
          seedColor: const Color(0xFFE089AF),
          scaffoldBackgroundColor: const Color(0xFFFFF3F7),
          home: const HomeAppearanceColors(
            pageTop: Color(0xFFFFE3EE),
            pageBottom: Color(0xFFFFF3F7),
            panelFill: Color(0xFFFFD8E9),
            panelGlow: Color(0xFFD0F5FF),
            panelOutline: Color(0xFFE8A0C4),
            panelShadow: Color(0x22E8A0C4),
            panelGradientTop: Color(0xFFFFE9F3),
            panelGradientBottom: Color(0xFFFFD5E6),
            headerText: Color(0xFFB0698F),
            settingsIcon: Color(0xFFAF6489),
            talkButtonFill: Color(0xFFF2AFCB),
            talkButtonOutline: Color(0xFFFFF4A6),
            talkButtonText: Colors.white,
            transcriptOuterBorder: Color(0xFFD4F4FF),
            transcriptInnerBorder: Color(0xFFF1B6D0),
            transcriptFill: Color(0xFFFFEAF2),
            transcriptHighlight: Color(0xFFFFF7FB),
            transcriptShadow: Color(0x18A6E9FF),
            transcriptTitle: Color(0xFFCF7BA8),
            transcriptText: Color(0xFF8E5E77),
            transcriptBadgeFill: Color(0xFFFFD6E7),
            transcriptBadgeBorder: Color(0xFFF4AECF),
            transcriptBadgeIcon: Color(0xFFE275A9),
          ),
          chat: const ChatAppearanceColors(
            backgroundTop: Color(0xFFFFDCEB),
            backgroundBottom: Color(0xFFFFF0F7),
            barIcon: Color(0xFF7E4B66),
            dateChipFill: Color(0x337E4B66),
            dateChipText: Colors.white,
            composerShell: Color(0xFFFFFBFD),
            composerShadow: Color(0x1FD285AA),
            composerFieldFill: Color(0xFFFFF2F8),
            composerHint: Color(0xFFB17E98),
            composerIcon: Color(0xFF7E4B66),
            composerText: Color(0xFF5E3450),
            userBubbleFill: Color(0xFFF2A8C9),
            userText: Color(0xFF5B2944),
            characterBubbleFill: Color(0xFFFFF9FC),
            characterText: Color(0xFF5E3450),
            metaText: Color(0xFF9A6781),
            bubbleShadow: Color(0x1AD285AA),
            avatarGradient: [Color(0xFFF7B4D0), Color(0xFFE284B0)],
            avatarBorder: Color(0xFFFFF3F8),
            avatarText: Color(0xFF6D3656),
          ),
          diary: const DiaryAppearanceColors(
            backgroundTop: Color(0xFFFFEEF5),
            backgroundBottom: Color(0xFFFFFAFD),
            cardFill: Color(0xFFFFFDFF),
            settingsIcon: Color(0xFF9B6482),
            titleText: Color(0xFF7F4F67),
            subtitleText: Color(0xFFB07A95),
            cardShadow: Color(0x18D58BAD),
            cardTitle: Color(0xFF85546C),
            bodyLead: Color(0xFF905A74),
            bodyDetail: Color(0xFFA36E87),
            cardAccents: [
              Color(0xFFF0A7C4),
              Color(0xFFF4BCD3),
              Color(0xFFE8A8D5),
              Color(0xFFDDA8E8),
              Color(0xFFF4B2BD),
            ],
            bookBackdrop: Color(0xFFF6E5EF),
            coverFill: Color(0xFFD89BB4),
            coverAccent: Color(0xFFF9DCE8),
            paperFill: Color(0xFFFFFCF8),
            paperEdge: Color(0xFFE4C7D0),
            ruleLine: Color(0xFFD9BCD1),
            ink: Color(0xFF876077),
            pageShadow: Color(0x1FC481A7),
            spineShadow: Color(0x33A86184),
          ),
          image: const ImageAppearanceColors(
            backgroundColor: Color(0xFFFFFAFD),
            titleText: Color(0xFF6A3952),
            subtitleText: Color(0xFFA07189),
            settingsIcon: Color(0xFF6A3952),
            fabFill: Color(0xFFE28BAF),
            fabForeground: Colors.white,
            modeActive: Color(0xFFD778A3),
            modeInactive: Color(0xFFC9A4B6),
            modeInactiveDivider: Color(0xFFF0D5E2),
            highlightText: Color(0xFF6A3952),
            highlightAccent: Color(0xFFF1C9DB),
            highlightGradients: [
              [Color(0xFFFFD8E6), Color(0xFFF0A1C1)],
              [Color(0xFFF7D7EC), Color(0xFFDDA2D8)],
              [Color(0xFFFFD6F0), Color(0xFFF3A8C8)],
              [Color(0xFFFFE4EE), Color(0xFFDFA6CA)],
            ],
            aiTileGradients: [
              [Color(0xFFE887AF), Color(0xFFF8C0D6)],
              [Color(0xFFD487E5), Color(0xFFF1B9E9)],
              [Color(0xFFF2A1B5), Color(0xFFFFD1C9)],
              [Color(0xFFC981C6), Color(0xFFEAB5D5)],
              [Color(0xFFE58DB2), Color(0xFFF1C0E6)],
              [Color(0xFFF0A3A9), Color(0xFFFFD8C7)],
            ],
            aiTileAccent: Color(0xFFFFF1F7),
            aiTileText: Colors.white,
            aiTileOverlay: Color(0x99653257),
            aiTileIconTint: Color(0xCCFFFFFF),
          ),
          settings: const SettingsAppearanceColors(
            backgroundTop: Color(0xFFFFF4FA),
            backgroundBottom: Color(0xFFFFECF5),
            sectionCard: Color(0xFFFFFDFF),
            headerText: Color(0xFF6E3F59),
            sectionTitle: Color(0xFF8C5A73),
            tileIconChipFill: Color(0xFFF7E4EE),
            tileIconColor: Color(0xFFD278A5),
            tileTitle: Color(0xFF6E4158),
            tileSubtitle: Color(0xFFA2768D),
            trailing: Color(0xFFB892A6),
            shadowColor: Color(0x16D78BAE),
          ),
        );
      case AppAppearancePreset.sky:
        return AppAppearancePalette(
          preset: AppAppearancePreset.sky,
          displayName: 'Sky',
          shortDescription: '空気感のあるブルーで軽さを出す',
          previewGradient: const [Color(0xFFDCEEFF), Color(0xFFF6FBFF)],
          previewSurface: const Color(0xFFE2F0FF),
          previewAccent: const Color(0xFF4E88D8),
          seedColor: const Color(0xFF5D90D6),
          scaffoldBackgroundColor: const Color(0xFFF5FAFF),
          home: const HomeAppearanceColors(
            pageTop: Color(0xFFDCEEFF),
            pageBottom: Color(0xFFF6FBFF),
            panelFill: Color(0xFFE2F0FF),
            panelGlow: Color(0xFFF7E5FF),
            panelOutline: Color(0xFFAACFF5),
            panelShadow: Color(0x1A8BB9F1),
            panelGradientTop: Color(0xFFF0F8FF),
            panelGradientBottom: Color(0xFFDDEEFF),
            headerText: Color(0xFF5A82B6),
            settingsIcon: Color(0xFF5A82B6),
            talkButtonFill: Color(0xFF86B7F3),
            talkButtonOutline: Color(0xFFE7F6FF),
            talkButtonText: Colors.white,
            transcriptOuterBorder: Color(0xFFB8DEFF),
            transcriptInnerBorder: Color(0xFFC7CCFF),
            transcriptFill: Color(0xFFEFF6FF),
            transcriptHighlight: Color(0xFFFFFFFF),
            transcriptShadow: Color(0x1491B8EB),
            transcriptTitle: Color(0xFF6A87C4),
            transcriptText: Color(0xFF587197),
            transcriptBadgeFill: Color(0xFFDDEFFF),
            transcriptBadgeBorder: Color(0xFFBEDBFF),
            transcriptBadgeIcon: Color(0xFF4E88D8),
          ),
          chat: const ChatAppearanceColors(
            backgroundTop: Color(0xFFD6E9FF),
            backgroundBottom: Color(0xFFF2F8FF),
            barIcon: Color(0xFF3D628A),
            dateChipFill: Color(0x334A76A8),
            dateChipText: Colors.white,
            composerShell: Color(0xFFFDFFFF),
            composerShadow: Color(0x184779A9),
            composerFieldFill: Color(0xFFF0F7FF),
            composerHint: Color(0xFF7792B3),
            composerIcon: Color(0xFF3D628A),
            composerText: Color(0xFF29496B),
            userBubbleFill: Color(0xFFA6D2FF),
            userText: Color(0xFF1E456B),
            characterBubbleFill: Color(0xFFFDFEFF),
            characterText: Color(0xFF274A70),
            metaText: Color(0xFF6F89A8),
            bubbleShadow: Color(0x184A76A8),
            avatarGradient: [Color(0xFF8EC4FF), Color(0xFF5D90D6)],
            avatarBorder: Color(0xFFF2F7FF),
            avatarText: Color(0xFF23476F),
          ),
          diary: const DiaryAppearanceColors(
            backgroundTop: Color(0xFFF0F7FF),
            backgroundBottom: Color(0xFFFBFDFF),
            cardFill: Color(0xFFFEFFFF),
            settingsIcon: Color(0xFF47627D),
            titleText: Color(0xFF2B4358),
            subtitleText: Color(0xFF7288A0),
            cardShadow: Color(0x123B79AA),
            cardTitle: Color(0xFF30506A),
            bodyLead: Color(0xFF34556D),
            bodyDetail: Color(0xFF687F92),
            cardAccents: [
              Color(0xFF7AA7E8),
              Color(0xFF91C8F2),
              Color(0xFF7ED8C8),
              Color(0xFFB6C8FF),
              Color(0xFFE0B4F6),
            ],
            bookBackdrop: Color(0xFFEAF1F9),
            coverFill: Color(0xFF91AAC8),
            coverAccent: Color(0xFFD7E6F7),
            paperFill: Color(0xFFFFFCF8),
            paperEdge: Color(0xFFD1DCEC),
            ruleLine: Color(0xFFC1D1E4),
            ink: Color(0xFF4A6278),
            pageShadow: Color(0x163B79AA),
            spineShadow: Color(0x29486F95),
          ),
          image: const ImageAppearanceColors(
            backgroundColor: Color(0xFFF7FBFF),
            titleText: Color(0xFF1F3550),
            subtitleText: Color(0xFF69829A),
            settingsIcon: Color(0xFF1F3550),
            fabFill: Color(0xFF3F6FA8),
            fabForeground: Colors.white,
            modeActive: Color(0xFF3F6FA8),
            modeInactive: Color(0xFF93ABC2),
            modeInactiveDivider: Color(0xFFD7E6F5),
            highlightText: Color(0xFF1F3550),
            highlightAccent: Color(0xFFCBE0F5),
            highlightGradients: [
              [Color(0xFFB8DAFF), Color(0xFF6BA8E8)],
              [Color(0xFFCBE7FF), Color(0xFF7DA8D6)],
              [Color(0xFFD4ECFF), Color(0xFF7CC7E8)],
              [Color(0xFFE0F3FF), Color(0xFF8DBCE8)],
            ],
            aiTileGradients: [
              [Color(0xFF5E8ECF), Color(0xFF9DD0FF)],
              [Color(0xFF4F6FA7), Color(0xFF9ABDE8)],
              [Color(0xFF5A88B4), Color(0xFFAADDE8)],
              [Color(0xFF4A8DB0), Color(0xFF9DE6D5)],
              [Color(0xFF5C8FD7), Color(0xFFC4DFFF)],
              [Color(0xFF6B95C0), Color(0xFFD3E9F5)],
            ],
            aiTileAccent: Color(0xFFF1F7FF),
            aiTileText: Colors.white,
            aiTileOverlay: Color(0x8A224A72),
            aiTileIconTint: Color(0xCCFFFFFF),
          ),
          settings: const SettingsAppearanceColors(
            backgroundTop: Color(0xFFF2F8FF),
            backgroundBottom: Color(0xFFEAF2FF),
            sectionCard: Colors.white,
            headerText: Color(0xFF26384D),
            sectionTitle: Color(0xFF3A4F68),
            tileIconChipFill: Color(0xFFEAF3FF),
            tileIconColor: Color(0xFF4D7FB8),
            tileTitle: Color(0xFF2B4258),
            tileSubtitle: Color(0xFF70839A),
            trailing: Color(0xFF8BA0B8),
            shadowColor: Color(0x123E6C93),
          ),
        );
      case AppAppearancePreset.forest:
        return AppAppearancePalette(
          preset: AppAppearancePreset.forest,
          displayName: 'Forest',
          shortDescription: 'セージとモスで静かな雰囲気に寄せる',
          previewGradient: const [Color(0xFFE5F3E8), Color(0xFFF8FCF6)],
          previewSurface: const Color(0xFFD7EBD7),
          previewAccent: const Color(0xFF4F8B63),
          seedColor: const Color(0xFF4F8B63),
          scaffoldBackgroundColor: const Color(0xFFF6FBF6),
          home: const HomeAppearanceColors(
            pageTop: Color(0xFFE5F3E8),
            pageBottom: Color(0xFFF8FCF6),
            panelFill: Color(0xFFD7EBD7),
            panelGlow: Color(0xFFE9F7E0),
            panelOutline: Color(0xFFA5D1AE),
            panelShadow: Color(0x183F8F64),
            panelGradientTop: Color(0xFFEFF8EC),
            panelGradientBottom: Color(0xFFD4EAD6),
            headerText: Color(0xFF4F7D5B),
            settingsIcon: Color(0xFF4F7D5B),
            talkButtonFill: Color(0xFF76B386),
            talkButtonOutline: Color(0xFFE9F7D4),
            talkButtonText: Colors.white,
            transcriptOuterBorder: Color(0xFFC5E5CA),
            transcriptInnerBorder: Color(0xFFB9DDBA),
            transcriptFill: Color(0xFFF0F8F0),
            transcriptHighlight: Color(0xFFFFFFFF),
            transcriptShadow: Color(0x143F8F64),
            transcriptTitle: Color(0xFF62896B),
            transcriptText: Color(0xFF4E6C55),
            transcriptBadgeFill: Color(0xFFDCEFD9),
            transcriptBadgeBorder: Color(0xFFBFDDBE),
            transcriptBadgeIcon: Color(0xFF4F8B63),
          ),
          chat: const ChatAppearanceColors(
            backgroundTop: Color(0xFFD8ECD9),
            backgroundBottom: Color(0xFFF1F8F0),
            barIcon: Color(0xFF345642),
            dateChipFill: Color(0x334F8B63),
            dateChipText: Colors.white,
            composerShell: Color(0xFFFDFFFD),
            composerShadow: Color(0x18458A58),
            composerFieldFill: Color(0xFFF0F7F0),
            composerHint: Color(0xFF7C9780),
            composerIcon: Color(0xFF345642),
            composerText: Color(0xFF274231),
            userBubbleFill: Color(0xFFA7D7A8),
            userText: Color(0xFF1D3A24),
            characterBubbleFill: Color(0xFFFBFEFB),
            characterText: Color(0xFF274231),
            metaText: Color(0xFF69836D),
            bubbleShadow: Color(0x18458A58),
            avatarGradient: [Color(0xFFA2D1AE), Color(0xFF5A936E)],
            avatarBorder: Color(0xFFF1F8F2),
            avatarText: Color(0xFF274231),
          ),
          diary: const DiaryAppearanceColors(
            backgroundTop: Color(0xFFF2F8EF),
            backgroundBottom: Color(0xFFFBFDF9),
            cardFill: Colors.white,
            settingsIcon: Color(0xFF45634A),
            titleText: Color(0xFF2E4732),
            subtitleText: Color(0xFF6E8A71),
            cardShadow: Color(0x123A7B48),
            cardTitle: Color(0xFF34543B),
            bodyLead: Color(0xFF3D5E44),
            bodyDetail: Color(0xFF667C69),
            cardAccents: [
              Color(0xFF85B97E),
              Color(0xFFA8C86E),
              Color(0xFF65B68C),
              Color(0xFF81C1A2),
              Color(0xFFC1D9A6),
            ],
            bookBackdrop: Color(0xFFE7EEDD),
            coverFill: Color(0xFF94A67A),
            coverAccent: Color(0xFFDDE9CE),
            paperFill: Color(0xFFFFFCF7),
            paperEdge: Color(0xFFD7DFC7),
            ruleLine: Color(0xFFC1D0B4),
            ink: Color(0xFF556651),
            pageShadow: Color(0x173A7B48),
            spineShadow: Color(0x2B506E46),
          ),
          image: const ImageAppearanceColors(
            backgroundColor: Color(0xFFF7FBF6),
            titleText: Color(0xFF243A28),
            subtitleText: Color(0xFF6C826F),
            settingsIcon: Color(0xFF243A28),
            fabFill: Color(0xFF3F6C48),
            fabForeground: Colors.white,
            modeActive: Color(0xFF3F6C48),
            modeInactive: Color(0xFF89A38C),
            modeInactiveDivider: Color(0xFFDDE9DD),
            highlightText: Color(0xFF243A28),
            highlightAccent: Color(0xFFC8D8C6),
            highlightGradients: [
              [Color(0xFFCFE8CE), Color(0xFF86B07D)],
              [Color(0xFFD8ECD3), Color(0xFF76A586)],
              [Color(0xFFD6F0E3), Color(0xFF6FB69B)],
              [Color(0xFFE3F4DE), Color(0xFFA5C786)],
            ],
            aiTileGradients: [
              [Color(0xFF56825A), Color(0xFFA5D0A6)],
              [Color(0xFF3E6A50), Color(0xFF7FB49D)],
              [Color(0xFF4F845D), Color(0xFFB9D59A)],
              [Color(0xFF447B62), Color(0xFF9ED5BD)],
              [Color(0xFF598E69), Color(0xFFB9E0C2)],
              [Color(0xFF5F7B49), Color(0xFFC8DCA4)],
            ],
            aiTileAccent: Color(0xFFF0F8F0),
            aiTileText: Colors.white,
            aiTileOverlay: Color(0x8A24412A),
            aiTileIconTint: Color(0xCCFFFFFF),
          ),
          settings: const SettingsAppearanceColors(
            backgroundTop: Color(0xFFF5FAF4),
            backgroundBottom: Color(0xFFEEF6ED),
            sectionCard: Colors.white,
            headerText: Color(0xFF243B27),
            sectionTitle: Color(0xFF3E5B41),
            tileIconChipFill: Color(0xFFEAF4E8),
            tileIconColor: Color(0xFF56825A),
            tileTitle: Color(0xFF28412B),
            tileSubtitle: Color(0xFF708574),
            trailing: Color(0xFF8AA18D),
            shadowColor: Color(0x123A7B48),
          ),
        );
      case AppAppearancePreset.sunset:
        return AppAppearancePalette(
          preset: AppAppearancePreset.sunset,
          displayName: 'Sunset',
          shortDescription: 'オレンジとクリームで少し温度を上げる',
          previewGradient: const [Color(0xFFFFE4D5), Color(0xFFFFF6F0)],
          previewSurface: const Color(0xFFFFD7BF),
          previewAccent: const Color(0xFFD97A52),
          seedColor: const Color(0xFFD67A52),
          scaffoldBackgroundColor: const Color(0xFFFFF7F1),
          home: const HomeAppearanceColors(
            pageTop: Color(0xFFFFE4D5),
            pageBottom: Color(0xFFFFF6F0),
            panelFill: Color(0xFFFFD7BF),
            panelGlow: Color(0xFFFFF0C8),
            panelOutline: Color(0xFFE7A179),
            panelShadow: Color(0x22D88957),
            panelGradientTop: Color(0xFFFFEDE1),
            panelGradientBottom: Color(0xFFFFD7BF),
            headerText: Color(0xFFB56D4D),
            settingsIcon: Color(0xFFB56D4D),
            talkButtonFill: Color(0xFFF1A37F),
            talkButtonOutline: Color(0xFFFFE3A4),
            talkButtonText: Colors.white,
            transcriptOuterBorder: Color(0xFFFFD0B5),
            transcriptInnerBorder: Color(0xFFF3C2A3),
            transcriptFill: Color(0xFFFFF0E7),
            transcriptHighlight: Color(0xFFFFFFFF),
            transcriptShadow: Color(0x16D88957),
            transcriptTitle: Color(0xFFC0785B),
            transcriptText: Color(0xFF8B5B4A),
            transcriptBadgeFill: Color(0xFFFFDEC9),
            transcriptBadgeBorder: Color(0xFFF3BE9A),
            transcriptBadgeIcon: Color(0xFFD97A52),
          ),
          chat: const ChatAppearanceColors(
            backgroundTop: Color(0xFFFFE1D2),
            backgroundBottom: Color(0xFFFFF4EC),
            barIcon: Color(0xFF7A4A35),
            dateChipFill: Color(0x338E5B3E),
            dateChipText: Colors.white,
            composerShell: Color(0xFFFFFEFD),
            composerShadow: Color(0x18C9754C),
            composerFieldFill: Color(0xFFFFF2EA),
            composerHint: Color(0xFFAE816F),
            composerIcon: Color(0xFF7A4A35),
            composerText: Color(0xFF5E3425),
            userBubbleFill: Color(0xFFF4B38D),
            userText: Color(0xFF4C2616),
            characterBubbleFill: Color(0xFFFFFCFA),
            characterText: Color(0xFF5E3425),
            metaText: Color(0xFF906856),
            bubbleShadow: Color(0x18C9754C),
            avatarGradient: [Color(0xFFFFC7A8), Color(0xFFD97A52)],
            avatarBorder: Color(0xFFFFF4EA),
            avatarText: Color(0xFF6A3B24),
          ),
          diary: const DiaryAppearanceColors(
            backgroundTop: Color(0xFFFFF3EA),
            backgroundBottom: Color(0xFFFFFCF8),
            cardFill: Colors.white,
            settingsIcon: Color(0xFF7B5647),
            titleText: Color(0xFF5F3E32),
            subtitleText: Color(0xFF9A7666),
            cardShadow: Color(0x14B26C47),
            cardTitle: Color(0xFF6C473A),
            bodyLead: Color(0xFF7A5143),
            bodyDetail: Color(0xFF8F7263),
            cardAccents: [
              Color(0xFFE6A16B),
              Color(0xFFF1B86D),
              Color(0xFFD9C06E),
              Color(0xFFE5A68C),
              Color(0xFFF0C2A2),
            ],
            bookBackdrop: Color(0xFFF3E4D8),
            coverFill: Color(0xFFD29B73),
            coverAccent: Color(0xFFF5DABC),
            paperFill: Color(0xFFFFFCF7),
            paperEdge: Color(0xFFE4D2C5),
            ruleLine: Color(0xFFD8C4B3),
            ink: Color(0xFF7A5C4B),
            pageShadow: Color(0x18B26C47),
            spineShadow: Color(0x2E8D5A44),
          ),
          image: const ImageAppearanceColors(
            backgroundColor: Color(0xFFFFFAF6),
            titleText: Color(0xFF4B2C21),
            subtitleText: Color(0xFF8C6B60),
            settingsIcon: Color(0xFF4B2C21),
            fabFill: Color(0xFFB8653F),
            fabForeground: Colors.white,
            modeActive: Color(0xFFB8653F),
            modeInactive: Color(0xFFA0887E),
            modeInactiveDivider: Color(0xFFF0DDD0),
            highlightText: Color(0xFF4B2C21),
            highlightAccent: Color(0xFFE8CCBC),
            highlightGradients: [
              [Color(0xFFFFD3BA), Color(0xFFE6A16B)],
              [Color(0xFFFFDFC8), Color(0xFFD89061)],
              [Color(0xFFFFD9C1), Color(0xFFDF8D78)],
              [Color(0xFFFFE7C6), Color(0xFFE0B178)],
            ],
            aiTileGradients: [
              [Color(0xFFCF7F55), Color(0xFFF2B286)],
              [Color(0xFFB46F4C), Color(0xFFDDA17B)],
              [Color(0xFFC88755), Color(0xFFF0BF8C)],
              [Color(0xFFC07B4A), Color(0xFFE5AF78)],
              [Color(0xFFD59661), Color(0xFFF3C89A)],
              [Color(0xFFA76A4A), Color(0xFFD89A78)],
            ],
            aiTileAccent: Color(0xFFFFF4EA),
            aiTileText: Colors.white,
            aiTileOverlay: Color(0x8A5B321E),
            aiTileIconTint: Color(0xCCFFFFFF),
          ),
          settings: const SettingsAppearanceColors(
            backgroundTop: Color(0xFFFFF6F0),
            backgroundBottom: Color(0xFFFFEEE3),
            sectionCard: Colors.white,
            headerText: Color(0xFF4A3229),
            sectionTitle: Color(0xFF6C4B40),
            tileIconChipFill: Color(0xFFFFEADF),
            tileIconColor: Color(0xFFC7754C),
            tileTitle: Color(0xFF4B3027),
            tileSubtitle: Color(0xFF907166),
            trailing: Color(0xFFB2978B),
            shadowColor: Color(0x14B26C47),
          ),
        );
    }
  }
}

class HomeAppearanceColors {
  const HomeAppearanceColors({
    required this.pageTop,
    required this.pageBottom,
    required this.panelFill,
    required this.panelGlow,
    required this.panelOutline,
    required this.panelShadow,
    required this.panelGradientTop,
    required this.panelGradientBottom,
    required this.headerText,
    required this.settingsIcon,
    required this.talkButtonFill,
    required this.talkButtonOutline,
    required this.talkButtonText,
    required this.transcriptOuterBorder,
    required this.transcriptInnerBorder,
    required this.transcriptFill,
    required this.transcriptHighlight,
    required this.transcriptShadow,
    required this.transcriptTitle,
    required this.transcriptText,
    required this.transcriptBadgeFill,
    required this.transcriptBadgeBorder,
    required this.transcriptBadgeIcon,
  });

  final Color pageTop;
  final Color pageBottom;
  final Color panelFill;
  final Color panelGlow;
  final Color panelOutline;
  final Color panelShadow;
  final Color panelGradientTop;
  final Color panelGradientBottom;
  final Color headerText;
  final Color settingsIcon;
  final Color talkButtonFill;
  final Color talkButtonOutline;
  final Color talkButtonText;
  final Color transcriptOuterBorder;
  final Color transcriptInnerBorder;
  final Color transcriptFill;
  final Color transcriptHighlight;
  final Color transcriptShadow;
  final Color transcriptTitle;
  final Color transcriptText;
  final Color transcriptBadgeFill;
  final Color transcriptBadgeBorder;
  final Color transcriptBadgeIcon;
}

class ChatAppearanceColors {
  const ChatAppearanceColors({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.barIcon,
    required this.dateChipFill,
    required this.dateChipText,
    required this.composerShell,
    required this.composerShadow,
    required this.composerFieldFill,
    required this.composerHint,
    required this.composerIcon,
    required this.composerText,
    required this.userBubbleFill,
    required this.userText,
    required this.characterBubbleFill,
    required this.characterText,
    required this.metaText,
    required this.bubbleShadow,
    required this.avatarGradient,
    required this.avatarBorder,
    required this.avatarText,
  });

  final Color backgroundTop;
  final Color backgroundBottom;
  final Color barIcon;
  final Color dateChipFill;
  final Color dateChipText;
  final Color composerShell;
  final Color composerShadow;
  final Color composerFieldFill;
  final Color composerHint;
  final Color composerIcon;
  final Color composerText;
  final Color userBubbleFill;
  final Color userText;
  final Color characterBubbleFill;
  final Color characterText;
  final Color metaText;
  final Color bubbleShadow;
  final List<Color> avatarGradient;
  final Color avatarBorder;
  final Color avatarText;
}

class DiaryAppearanceColors {
  const DiaryAppearanceColors({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.cardFill,
    required this.settingsIcon,
    required this.titleText,
    required this.subtitleText,
    required this.cardShadow,
    required this.cardTitle,
    required this.bodyLead,
    required this.bodyDetail,
    required this.cardAccents,
    required this.bookBackdrop,
    required this.coverFill,
    required this.coverAccent,
    required this.paperFill,
    required this.paperEdge,
    required this.ruleLine,
    required this.ink,
    required this.pageShadow,
    required this.spineShadow,
  });

  final Color backgroundTop;
  final Color backgroundBottom;
  final Color cardFill;
  final Color settingsIcon;
  final Color titleText;
  final Color subtitleText;
  final Color cardShadow;
  final Color cardTitle;
  final Color bodyLead;
  final Color bodyDetail;
  final List<Color> cardAccents;
  final Color bookBackdrop;
  final Color coverFill;
  final Color coverAccent;
  final Color paperFill;
  final Color paperEdge;
  final Color ruleLine;
  final Color ink;
  final Color pageShadow;
  final Color spineShadow;
}

class ImageAppearanceColors {
  const ImageAppearanceColors({
    required this.backgroundColor,
    required this.titleText,
    required this.subtitleText,
    required this.settingsIcon,
    required this.fabFill,
    required this.fabForeground,
    required this.modeActive,
    required this.modeInactive,
    required this.modeInactiveDivider,
    required this.highlightText,
    required this.highlightAccent,
    required this.highlightGradients,
    required this.aiTileGradients,
    required this.aiTileAccent,
    required this.aiTileText,
    required this.aiTileOverlay,
    required this.aiTileIconTint,
  });

  final Color backgroundColor;
  final Color titleText;
  final Color subtitleText;
  final Color settingsIcon;
  final Color fabFill;
  final Color fabForeground;
  final Color modeActive;
  final Color modeInactive;
  final Color modeInactiveDivider;
  final Color highlightText;
  final Color highlightAccent;
  final List<List<Color>> highlightGradients;
  final List<List<Color>> aiTileGradients;
  final Color aiTileAccent;
  final Color aiTileText;
  final Color aiTileOverlay;
  final Color aiTileIconTint;
}

class SettingsAppearanceColors {
  const SettingsAppearanceColors({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.sectionCard,
    required this.headerText,
    required this.sectionTitle,
    required this.tileIconChipFill,
    required this.tileIconColor,
    required this.tileTitle,
    required this.tileSubtitle,
    required this.trailing,
    required this.shadowColor,
  });

  final Color backgroundTop;
  final Color backgroundBottom;
  final Color sectionCard;
  final Color headerText;
  final Color sectionTitle;
  final Color tileIconChipFill;
  final Color tileIconColor;
  final Color tileTitle;
  final Color tileSubtitle;
  final Color trailing;
  final Color shadowColor;
}
