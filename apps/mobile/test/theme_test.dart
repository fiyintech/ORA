import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/ora_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ORAThemeModeController defaults to dark mode', () {
    SharedPreferences.setMockInitialValues({});
    final controller = ORAThemeModeController();
    final mode = controller.build();
    expect(mode, ThemeMode.dark);
  });

  test('ORATheme.dark() produces dark brightness', () {
    final theme = ORATheme.dark();
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF0A0A0B));
  });

  test('ORATheme.light() produces light brightness', () {
    final theme = ORATheme.light();
    expect(theme.brightness, Brightness.light);
  });
}