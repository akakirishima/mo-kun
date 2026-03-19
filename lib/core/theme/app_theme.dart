import 'package:flutter/material.dart';
import 'package:gdgoc_2026_prototype/core/theme/app_appearance.dart';
import 'package:nes_ui/nes_ui.dart';

class AppTheme {
  const AppTheme._();

  static const _appFontFamily = 'NotoSansJP';

  static ThemeData light(AppAppearancePalette palette) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.seedColor,
      brightness: Brightness.light,
    );
    final baseTextTheme = ThemeData.light().textTheme.apply(
      fontFamily: _appFontFamily,
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    final textTheme = baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.4,
      ),
    );
    final theme = flutterNesTheme(
      primaryColor: palette.seedColor,
      brightness: Brightness.light,
      nesTheme: const NesTheme(pixelSize: 3),
      textTheme: textTheme,
      nesButtonTheme: NesButtonTheme(
        normal: Colors.white,
        primary: palette.seedColor,
        success: palette.home.talkButtonFill,
        warning: palette.image.highlightAccent,
        error: const Color(0xFFD96C5F),
        lightLabelColor: Colors.white,
        darkLabelColor: colorScheme.onSurface,
        lightIconTheme: const NesIconTheme(
          primary: Colors.white,
          secondary: Color(0xFF2B2B2B),
          accent: Color(0xFFF4E3A2),
          shadow: Color(0xFF8A5568),
        ),
        darkIconTheme: NesIconTheme(
          primary: colorScheme.onSurface,
          secondary: Colors.white,
          accent: palette.seedColor,
          shadow: colorScheme.outline,
        ),
        borderColor: colorScheme.onSurface,
      ),
      nesIconTheme: NesIconTheme(
        primary: colorScheme.onSurface,
        secondary: Colors.white,
        accent: palette.seedColor,
        shadow: colorScheme.outline,
        size: 28,
      ),
      nesContainerTheme: NesContainerTheme(
        backgroundColor: Colors.white,
        borderColor: colorScheme.onSurface,
        labelTextStyle:
            textTheme.labelLarge?.copyWith(color: colorScheme.onSurface) ??
            TextStyle(
              fontFamily: _appFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
        padding: const EdgeInsets.all(16),
        painter: NesContainerSquareCornerPainter.new,
      ),
      nesInputDecorationTheme: NesInputDecorationTheme(
        borderColor: colorScheme.onSurface,
        enabledBorderColor: colorScheme.outline,
        focusedBorderColor: palette.seedColor,
        errorBorderColor: colorScheme.error,
        focusedErrorBorderColor: colorScheme.error,
      ),
    );

    return theme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.scaffoldBackgroundColor,
      cardColor: Colors.white,
      textTheme: textTheme,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.settings.sectionCard,
        indicatorColor: colorScheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.seedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: colorScheme.onSurface),
          ),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          side: BorderSide(color: colorScheme.onSurface, width: 2),
          shape: const RoundedRectangleBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface,
        thickness: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.onSurface, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurface,
        textColor: colorScheme.onSurface,
      ),
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        fillColor: Colors.white,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      splashFactory: NoSplash.splashFactory,
    );
  }
}
