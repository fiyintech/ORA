import 'package:flutter/material.dart';

/// ORA Design System — Color Palette
///
/// Defines both dark and light theme colors.
/// All screens should reference these constants instead of hardcoded values.
class ORAColors {
  // ──────────────────────────────────────────────
  // Dark Theme
  // ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0A0B);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2A2A2A);

  static const Color darkPrimary = Color(0xFF6B3FA0);
  static const Color darkSecondary = Color(0xFF8B5CF6);
  static const Color darkAccent = Color(0xFFD4AF37);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF6B6B6B);

  static const Color darkError = Color(0xFFE53935);
  static const Color darkSuccess = Color(0xFF4CAF50);
  static const Color darkWarning = Color(0xFFFF9800);

  // ──────────────────────────────────────────────
  // Light Theme
  // ──────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E0E0);

  static const Color lightPrimary = Color(0xFF6B3FA0);
  static const Color lightSecondary = Color(0xFF8B5CF6);
  static const Color lightAccent = Color(0xFFD4AF37);

  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightTextTertiary = Color(0xFF9E9E9E);

  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightSuccess = Color(0xFF388E3C);
  static const Color lightWarning = Color(0xFFF57C00);

  // ──────────────────────────────────────────────
  // Shared
  // ──────────────────────────────────────────────
  static const Color gold = Color(0xFFD4AF37);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  static const Color rare = Color(0xFF6B3FA0);
  static const Color epic = Color(0xFF2196F3);
  static const Color legendary = Color(0xFFD4AF37);
  static const Color mythic = Color(0xFFFF6B9D);

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  /// Returns the background color for the given brightness.
  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? darkBackground : lightBackground;

  /// Returns the surface color for the given brightness.
  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : lightSurface;

  /// Returns the card color for the given brightness.
  static Color card(Brightness brightness) =>
      brightness == Brightness.dark ? darkCard : lightCard;

  /// Returns the border color for the given brightness.
  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? darkBorder : lightBorder;

  /// Returns the primary color for the given brightness.
  static Color primary(Brightness brightness) =>
      brightness == Brightness.dark ? darkPrimary : lightPrimary;

  /// Returns the secondary color for the given brightness.
  static Color secondary(Brightness brightness) =>
      brightness == Brightness.dark ? darkSecondary : lightSecondary;

  /// Returns the accent color for the given brightness.
  static Color accent(Brightness brightness) =>
      brightness == Brightness.dark ? darkAccent : lightAccent;

  /// Returns the primary text color for the given brightness.
  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  /// Returns the secondary text color for the given brightness.
  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;

  /// Returns the tertiary text color for the given brightness.
  static Color textTertiary(Brightness brightness) =>
      brightness == Brightness.dark ? darkTextTertiary : lightTextTertiary;

  /// Returns the error color for the given brightness.
  static Color error(Brightness brightness) =>
      brightness == Brightness.dark ? darkError : lightError;

  /// Returns the success color for the given brightness.
  static Color success(Brightness brightness) =>
      brightness == Brightness.dark ? darkSuccess : lightSuccess;

  /// Returns the warning color for the given brightness.
  static Color warning(Brightness brightness) =>
      brightness == Brightness.dark ? darkWarning : lightWarning;
}