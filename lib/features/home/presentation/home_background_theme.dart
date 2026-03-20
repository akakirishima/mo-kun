class HomeBackgroundTheme {
  const HomeBackgroundTheme({
    required this.id,
    required this.label,
    required this.description,
    required this.backgroundAssetPath,
  });

  final String id;
  final String label;
  final String description;
  final String backgroundAssetPath;

  static const daytime = HomeBackgroundTheme(
    id: 'hiru',
    label: '昼',
    description: 'やわらかい昼の光',
    backgroundAssetPath: 'assets/images/home_backgrounds/hiru.png',
  );

  static const sunset = HomeBackgroundTheme(
    id: 'yuuyake',
    label: '夕焼け',
    description: '暖色の夕暮れ',
    backgroundAssetPath: 'assets/images/home_backgrounds/yuuyake.png',
  );

  static const night = HomeBackgroundTheme(
    id: 'yoru',
    label: '夜空',
    description: '静かな夜の空気',
    backgroundAssetPath: 'assets/images/home_backgrounds/yoru.png',
  );

  static const values = [daytime, sunset, night];

  static HomeBackgroundTheme resolve(String? id) {
    return values.firstWhere(
      (theme) => theme.id == id,
      orElse: () => sunset,
    );
  }
}
