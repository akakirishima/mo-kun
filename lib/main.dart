import 'package:flutter/widgets.dart';
import 'package:gdgoc_2026_prototype/app/app.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appearanceController = AppearanceController();
  await appearanceController.load();

  runApp(App(appearanceController: appearanceController));
}
