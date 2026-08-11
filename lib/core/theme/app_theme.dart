import 'package:flutter/material.dart';

class AppTheme {
  static const double radiusXs = 4;
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 10;

  static Brightness _activeBrightness = Brightness.light;

  static void setBrightness(Brightness brightness) {
    _activeBrightness = brightness;
  }

  static bool get isDark => _activeBrightness == Brightness.dark;
  static _AppPalette get _active => isDark ? _darkPalette : _lightPalette;

  static const _AppPalette _lightPalette = _AppPalette(
    primary: Color(0xFF006B43),
    primaryDark: Color(0xFF004A31),
    primarySoft: Color(0xFFE7F3ED),
    secondary: Color(0xFF2F3A35),
    tertiary: Color(0xFF6D746F),
    tertiarySoft: Color(0xFFE9EEEB),
    sidebarBackground: Color(0xFFFFFFFF),
    sidebarSelected: Color(0xFFE8F4EE),
    background: Color(0xFFF5F7F5),
    subtle: Color(0xFFEBF0ED),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF15211B),
    textSecondary: Color(0xFF607067),
    textMuted: Color(0xFF96A29B),
    borderLight: Color(0xFFDDE6E1),
    borderStrong: Color(0xFFB8C8BF),
    success: Color(0xFF007A4D),
    successBg: Color(0xFFE5F4EC),
    warning: Color(0xFFE26E12),
    warningBg: Color(0xFFFFEEE0),
    danger: Color(0xFFC22919),
    dangerBg: Color(0xFFFFE7E2),
  );

  static const _AppPalette _darkPalette = _AppPalette(
    primary: Color(0xFF7CE0AC),
    primaryDark: Color(0xFFE6FFF1),
    primarySoft: Color(0xFF143424),
    secondary: Color(0xFFB8C9C0),
    tertiary: Color(0xFF8D9B93),
    tertiarySoft: Color(0xFF18241D),
    sidebarBackground: Color(0xFF08100C),
    sidebarSelected: Color(0xFF143424),
    background: Color(0xFF070C09),
    subtle: Color(0xFF101A14),
    card: Color(0xFF0D1510),
    textPrimary: Color(0xFFF1F8F3),
    textSecondary: Color(0xFFB8C8BF),
    textMuted: Color(0xFF77877F),
    borderLight: Color(0xFF1F3228),
    borderStrong: Color(0xFF385143),
    success: Color(0xFF7CE0AC),
    successBg: Color(0xFF143424),
    warning: Color(0xFFFFA24A),
    warningBg: Color(0xFF38220D),
    danger: Color(0xFFFF7A69),
    dangerBg: Color(0xFF3A1813),
  );

  static Color get primaryTeal => _active.primary;
  static Color get primaryTealDark => _active.primaryDark;
  static Color get primaryTealLight => _active.primarySoft;

  static Color get emeraldGreen => _active.success;
  static Color get emeraldLight => _active.successBg;

  static Color get cyanAccent => _active.secondary;
  static Color get indigo => _active.tertiary;
  static Color get indigoLight => _active.tertiarySoft;

  static Color get sidebarBackground => _active.sidebarBackground;
  static Color get sidebarSelected => _active.sidebarSelected;

  static Color get bgLight => _active.background;
  static Color get bgSubtle => _active.subtle;
  static Color get cardBg => _active.card;

  static Color get textPrimary => _active.textPrimary;
  static Color get textSecondary => _active.textSecondary;
  static Color get textMuted => _active.textMuted;

  static Color get borderLight => _active.borderLight;
  static Color get borderStrong => _active.borderStrong;

  static Color get warningOrange => _active.warning;
  static Color get warningBg => _active.warningBg;

  static Color get dangerRed => _active.danger;
  static Color get dangerBg => _active.dangerBg;

  static Color get successGreen => _active.success;
  static Color get successBg => _active.successBg;

  static ThemeData get lightTheme =>
      _buildTheme(brightness: Brightness.light, palette: _lightPalette);

  static ThemeData get darkTheme =>
      _buildTheme(brightness: Brightness.dark, palette: _darkPalette);

  static ThemeData _buildTheme({
    required Brightness brightness,
    required _AppPalette palette,
  }) {
    const fontFamily = 'Segoe UI';
    final baseTextTheme =
        (brightness == Brightness.dark
                ? Typography.material2021().white
                : Typography.material2021().black)
            .apply(
              fontFamily: fontFamily,
              bodyColor: palette.textPrimary,
              displayColor: palette.textPrimary,
            );

    final isDarkTheme = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      primaryColor: palette.primary,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: isDarkTheme ? Colors.black : Colors.white,
        secondary: palette.secondary,
        onSecondary: isDarkTheme ? Colors.black : Colors.white,
        error: palette.danger,
        onError: Colors.white,
        surface: palette.card,
        onSurface: palette.textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: palette.textPrimary,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: palette.textPrimary,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: palette.textPrimary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: palette.textPrimary,
          height: 1.35,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
          height: 1.35,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.borderLight,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: palette.borderLight, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.textPrimary,
        contentTextStyle: TextStyle(color: palette.card),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: TextStyle(
          color: palette.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: palette.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: palette.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: palette.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: palette.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: palette.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: isDarkTheme ? Colors.black : Colors.white,
          elevation: 0,
          disabledBackgroundColor: palette.borderLight,
          disabledForegroundColor: palette.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          side: BorderSide(color: palette.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return palette.primary;
          return palette.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primarySoft;
          }
          return palette.subtle;
        }),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          color: palette.textPrimary,
          fontSize: 12,
        ),
        dataTextStyle: TextStyle(color: palette.textPrimary, fontSize: 12),
        headingRowColor: WidgetStatePropertyAll(palette.subtle),
        dividerThickness: 0.6,
      ),
    );
  }
}

class _AppPalette {
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color secondary;
  final Color tertiary;
  final Color tertiarySoft;
  final Color sidebarBackground;
  final Color sidebarSelected;
  final Color background;
  final Color subtle;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderLight;
  final Color borderStrong;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;

  const _AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.secondary,
    required this.tertiary,
    required this.tertiarySoft,
    required this.sidebarBackground,
    required this.sidebarSelected,
    required this.background,
    required this.subtle,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderLight,
    required this.borderStrong,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
  });
}
