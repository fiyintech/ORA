import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';

/// ORA Design System — Full Theme Data
///
/// Provides ready-to-use [ThemeData] for both dark and light modes.
class ORATheme {
  static ThemeData dark() => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: ORAColors.darkPrimary,
          secondary: ORAColors.darkSecondary,
          surface: ORAColors.darkSurface,
          error: ORAColors.darkError,
        ),
        scaffoldBackgroundColor: ORAColors.darkBackground,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: ORAColors.darkBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: ORAColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: ORARadius.largeAll,
            side: const BorderSide(color: ORAColors.darkBorder),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: ORAColors.darkBackground,
          selectedItemColor: ORAColors.darkPrimary,
          unselectedItemColor: ORAColors.darkTextTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ORAColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: ORARadius.mediumAll,
            borderSide: const BorderSide(color: ORAColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: ORARadius.mediumAll,
            borderSide: const BorderSide(color: ORAColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: ORARadius.mediumAll,
            borderSide: const BorderSide(color: ORAColors.darkPrimary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: ORARadius.mediumAll,
            borderSide: const BorderSide(color: ORAColors.darkError),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: ORAColors.darkBorder,
          thickness: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: ORAColors.darkPrimary,
          foregroundColor: Colors.white,
        ),
      );

  static ThemeData light() => ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: ORAColors.lightPrimary,
          secondary: ORAColors.lightSecondary,
          surface: ORAColors.lightSurface,
          error: ORAColors.lightError,
        ),
        scaffoldBackgroundColor: ORAColors.lightBackground,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: ORAColors.lightBackground,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: ORAColors.lightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: ORARadius.largeAll,
            side: const BorderSide(color: ORAColors.lightBorder),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: ORAColors.lightBackground,
          selectedItemColor: ORAColors.lightPrimary,
          unselectedItemColor: ORAColors.lightTextTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ORAColors.lightSurface,
          border: OutlineInputBorder(
            borderRadius: ORARadius.mediumAll,
            borderSide: const BorderSide(color: ORAColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: ORARadius.mediumAll,
            borderSide: const BorderSide(color: ORAColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: ORARadius.mediumAll,
            borderSide: const BorderSide(color: ORAColors.lightPrimary),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: ORARadius.mediumAll,
            borderSide: const BorderSide(color: ORAColors.lightError),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: ORAColors.lightBorder,
          thickness: 1,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: ORAColors.lightPrimary,
          foregroundColor: Colors.white,
        ),
      );
}

/// Theme mode controller.
///
/// Manages the application theme mode (Dark / Light / Follow System)
/// and persists the selected mode locally via [SharedPreferences].
class ORAThemeModeController extends Notifier<ThemeMode> {
  static const String _themeModeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadThemeMode();
    // ORA is a dark-first brand. Default to dark mode so the app
    // renders dark even when the OS is in light mode.
    return ThemeMode.dark;
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeModeKey);
    if (stored == null) return;

    final parsed = ThemeMode.values.asNameMap()[stored];
    if (parsed != null) {
      state = parsed;
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _persistThemeMode(mode);
  }

  Future<void> _persistThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}

/// Provider for the ORA theme mode (Dark / Light / Follow System).
final oraThemeModeProvider =
    NotifierProvider<ORAThemeModeController, ThemeMode>(
  ORAThemeModeController.new,
);