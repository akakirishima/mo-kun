import 'package:flutter/widgets.dart';
import 'package:gdgoc_2026_prototype/app/app.dart';
import 'package:gdgoc_2026_prototype/core/app/app_repository.dart';
import 'package:gdgoc_2026_prototype/core/app/fake_app_repository.dart';
import 'package:gdgoc_2026_prototype/core/app/firebase_app_repository.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appearanceController = AppearanceController();
  await appearanceController.load();
  final repository = await _createRepository();

  runApp(
    App(appearanceController: appearanceController, repository: repository),
  );
}

Future<AppRepository> _createRepository() async {
  try {
    return await FirebaseAppRepository.create();
  } catch (_) {
    return FakeAppRepository();
  }
}
