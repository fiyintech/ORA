import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';

/// ORA Design System — Reusable Text Field
///
/// Supports both dark and light themes automatically.
class ORATextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const ORATextField({
    super.key,
    required this.label,
    this.hintText,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ORATypography.label(context)),
        const SizedBox(height: ORASpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: ORATypography.body(context),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: ORATypography.caption(context),
            filled: true,
            fillColor: ORAColors.surface(brightness),
            border: OutlineInputBorder(
              borderRadius: ORARadius.mediumAll,
              borderSide: BorderSide(color: ORAColors.border(brightness)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: ORARadius.mediumAll,
              borderSide: BorderSide(color: ORAColors.border(brightness)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: ORARadius.mediumAll,
              borderSide: BorderSide(color: ORAColors.primary(brightness)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: ORARadius.mediumAll,
              borderSide: BorderSide(color: ORAColors.error(brightness)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ORASpacing.lg,
              vertical: ORASpacing.lg,
            ),
          ),
        ),
      ],
    );
  }
}