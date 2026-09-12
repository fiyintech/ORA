import 'package:flutter/material.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';

/// ORA Design System — Comment Composer
///
/// Bottom input field for creating comments.
/// Supports typing, send button, character counter, and loading state.
class ORACommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final String currentUserId;
  final String currentUserFullName;
  final int maxCharacters;

  const ORACommentComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.isSending = false,
    required this.currentUserId,
    required this.currentUserFullName,
    this.maxCharacters = 500,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.all(ORASpacing.md),
      decoration: BoxDecoration(
        color: ORAColors.surface(brightness),
        border: Border(
          top: BorderSide(
            color: ORAColors.border(brightness),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar
            ORAAvatar(
              letter: currentUserFullName.isNotEmpty
                  ? currentUserFullName[0].toUpperCase()
                  : 'U',
              size: 32,
            ),
            const SizedBox(width: ORASpacing.md),
            // Text input
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                maxLength: maxCharacters,
                onChanged: (value) {
                  // Trigger rebuild for character counter
                  (context as Element).markNeedsBuild();
                },
                style: ORATypography.body(context).copyWith(
                  color: ORAColors.textPrimary(brightness),
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: ORATypography.body(context).copyWith(
                    color: ORAColors.textTertiary(brightness),
                  ),
                  border: InputBorder.none,
                  counterText: '',
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (hasText && !isSending) {
                    onSend();
                  }
                },
              ),
            ),
            const SizedBox(width: ORASpacing.sm),
            // Character counter
            if (controller.text.isNotEmpty)
              Text(
                '${controller.text.length}/$maxCharacters',
                style: ORATypography.caption(context).copyWith(
                  color: controller.text.length > maxCharacters
                      ? ORAColors.error(brightness)
                      : ORAColors.textTertiary(brightness),
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: ORASpacing.sm),
            // Send button
            GestureDetector(
              onTap: (hasText && !isSending) ? onSend : null,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasText && !isSending
                      ? ORAColors.primary(brightness)
                      : ORAColors.surface(brightness),
                  shape: BoxShape.circle,
                ),
                child: isSending
                    ? Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ORAColors.textPrimary(brightness),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: hasText && !isSending
                            ? Colors.white
                            : ORAColors.textTertiary(brightness),
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
