import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';

/// ORA Design System — Typography
///
/// Defines text styles for the app.
/// Use these constants instead of creating inline text styles.
class ORATypography {
  // ──────────────────────────────────────────────
  // Font Families
  // ──────────────────────────────────────────────
  static const String _defaultFont = '';

  // ──────────────────────────────────────────────
  // Display (largest, for hero sections)
  // ──────────────────────────────────────────────
  static TextStyle display(BuildContext context) => TextStyle(
        fontFamily: _defaultFont,
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: ORAColors.textPrimary(Theme.of(context).brightness),
        height: 1.2,
      );

  // ──────────────────────────────────────────────
  // Heading (section titles)
  // ──────────────────────────────────────────────
  static TextStyle heading(BuildContext context) => TextStyle(
        fontFamily: _defaultFont,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ORAColors.textPrimary(Theme.of(context).brightness),
        height: 1.3,
      );

  // ──────────────────────────────────────────────
  // Title (card titles, app bar)
  // ──────────────────────────────────────────────
  static TextStyle title(BuildContext context) => TextStyle(
        fontFamily: _defaultFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ORAColors.textPrimary(Theme.of(context).brightness),
        height: 1.4,
      );

  // ──────────────────────────────────────────────
  // Body (paragraphs, post content)
  // ──────────────────────────────────────────────
  static TextStyle body(BuildContext context) => TextStyle(
        fontFamily: _defaultFont,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: ORAColors.textPrimary(Theme.of(context).brightness),
        height: 1.5,
      );

  // ──────────────────────────────────────────────
  // Caption (timestamps, secondary info)
  // ──────────────────────────────────────────────
  static TextStyle caption(BuildContext context) => TextStyle(
        fontFamily: _defaultFont,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: ORAColors.textSecondary(Theme.of(context).brightness),
        height: 1.4,
      );

  // ──────────────────────────────────────────────
  // Label (form labels, badges)
  // ──────────────────────────────────────────────
  static TextStyle label(BuildContext context) => TextStyle(
        fontFamily: _defaultFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: ORAColors.textPrimary(Theme.of(context).brightness),
        height: 1.3,
      );
}