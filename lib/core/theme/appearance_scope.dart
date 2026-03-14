import 'package:flutter/widgets.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_appearance.dart';
import 'package:gdgoc_2026_prototype/core/theme/appearance_controller.dart';

class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({
    super.key,
    required AppearanceController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppearanceController? maybeControllerOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppearanceScope>()
        ?.notifier;
  }

  static AppearanceController controllerOf(BuildContext context) {
    final controller = maybeControllerOf(context);
    assert(controller != null, 'AppearanceScope was not found in context.');
    return controller!;
  }

  static AppAppearancePalette paletteOf(BuildContext context) {
    final controller = maybeControllerOf(context);
    return controller?.palette ??
        AppAppearancePalette.fromPreset(AppAppearancePreset.blossom);
  }
}
