import 'package:flutter/material.dart';

class AppTheme {
  static const Color _ink = Color(0xFF16324A);
  static const Color _ocean = Color(0xFF255A84);
  static const Color _teal = Color(0xFF1F7A6E);
  static const Color _sand = Color(0xFFE8C98B);
  static const Color _canvas = Color(0xFFF7F8FC);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceAlt = Color(0xFFF3F6FA);
  static const Color _line = Color(0xFFD8E1EA);
  static const Color _muted = Color(0xFF5E7082);

  static ThemeData light() {
    final seedScheme = ColorScheme.fromSeed(
      seedColor: _ocean,
      brightness: Brightness.light,
    );

    final scheme = seedScheme.copyWith(
      primary: _ocean,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE5EDF7),
      onPrimaryContainer: _ink,
      secondary: _sand,
      onSecondary: const Color(0xFF46351A),
      secondaryContainer: const Color(0xFFF8EDD9),
      onSecondaryContainer: const Color(0xFF46351A),
      tertiary: _teal,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFE2F1EE),
      onTertiaryContainer: const Color(0xFF113E38),
      error: const Color(0xFFBE4A3A),
      onError: Colors.white,
      errorContainer: const Color(0xFFF9E0DB),
      onErrorContainer: const Color(0xFF5A211A),
      surface: _surface,
      onSurface: _ink,
      surfaceContainerHighest: _surfaceAlt,
      onSurfaceVariant: _muted,
      outline: _line,
      outlineVariant: const Color(0xFFE5EBF2),
      shadow: _ink.withValues(alpha: 0.12),
      scrim: _ink.withValues(alpha: 0.45),
      inverseSurface: _ink,
      onInverseSurface: _surface,
      inversePrimary: const Color(0xFFD7E6F4),
      surfaceTint: _ocean,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _canvas,
    );

    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: scheme.onSurface,
        height: 1.42,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: _muted,
        height: 1.42,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: _muted,
        height: 1.38,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        color: _muted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        indicatorColor: const Color(0xFFE7EEF7),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? _ink : _muted,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? _ocean : _muted,
            size: 24,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _ink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: _muted,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: _muted.withValues(alpha: 0.84),
        ),
        prefixIconColor: _muted,
        suffixIconColor: _muted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _ocean, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFBE4A3A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFBE4A3A), width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceAlt,
        selectedColor: const Color(0xFFE5EDF7),
        disabledColor: _surfaceAlt,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: _line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? _ocean : Colors.white,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: _line),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? _ocean : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFFD7E6F4)
              : const Color(0xFFE3E9F1),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _ocean,
        circularTrackColor: Color(0xFFD9E5F1),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _ink.withValues(alpha: 0.35),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: _line),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _ocean,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: textTheme.labelLarge?.copyWith(
            color: _ocean,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.zero,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
      ),
    );
  }
}
