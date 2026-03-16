import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_shell.dart';
import 'package:gdgoc_2026_prototype/app/shell/app_tab.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_scope.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key, this.appearanceController});

  static const _initialTabName = String.fromEnvironment(
    'INITIAL_TAB',
    defaultValue: 'home',
  );

  final AppearanceController? appearanceController;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppearanceController _appearanceController;

  @override
  void initState() {
    super.initState();
    _appearanceController =
        widget.appearanceController ?? AppearanceController();
    if (widget.appearanceController == null) {
      _appearanceController.load();
    }
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appearanceController,
      builder: (context, _) {
        return AppearanceScope(
          controller: _appearanceController,
          child: MaterialApp(
            title: 'GDGoC 2026 Prototype',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(_appearanceController.palette),
            home: AppShell(initialTab: AppTab.fromName(App._initialTabName)),
          ),
        );
      },
    );
  }
}
