import 'package:flutter/material.dart';
import 'package:mobile/core/models/comment.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';
import 'package:mobile/shared/widgets/ora_badge.dart';

/// ORA Design System — Reusable Comment Item
///
/// Displays a single comment with avatar, username, timestamp,
/// text, edited badge, like count, and action buttons.
class ORACommentItem extends StatelessWidget {
  final Comment comment;
  final bool isOwnComment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isLiked;
  final bool isLiking;

  const ORACommentItem({
    super.key,
    required this.comment,
    this.isOwnComment = false,
    this.onLike,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.isLiked = false,
    this.isLiking = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      margin: const EdgeInsets.only(bottom: ORASpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          ORAAvatar(
            letter: comment.username.isNotEmpty
                ? comment.username[0].toUpperCase()
                : '?',
            size: 32,
            gradientColors: comment.avatarColors ??
                [
                  ORAColors.primary(brightness),
                  ORAColors.secondary(brightness),
                ],
          ),
          const SizedBox(width: ORASpacing.md),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: username + timestamp + edited badge
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: ORATypography.label(context).copyWith(
                        color: ORAColors.textPrimary(brightness),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: ORASpacing.sm),
                    Text(
                      _formatTime(comment.createdAt),
                      style: ORATypography.caption(context).copyWith(
                        color: ORAColors.textTertiary(brightness),
                        fontSize: 12,
                      ),
                    ),
                    if (comment.isEdited) ...[
                      const SizedBox(width: ORASpacing.sm),
                      ORABadge(
                        text: 'edited',
                        color: ORAColors.textTertiary(brightness),
                        fontSize: 9,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Comment text
                Text(
                  comment.text,
                  style: ORATypography.body(context).copyWith(
                    color: ORAColors.textPrimary(brightness),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: ORASpacing.sm),
                // Action buttons
                Row(
                  children: [
                    // Like button
                    _buildActionButton(
                      context,
                      icon: isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: comment.likesCount.toString(),
                      isActive: isLiked,
                      isLoading: isLiking,
                      onTap: onLike,
                    ),
                    const SizedBox(width: ORASpacing.md),
                    // Reply button
                    _buildActionButton(
                      context,
                      icon: Icons.reply_outlined,
                      label: 'Reply',
                      onTap: onReply,
                    ),
                    // More menu (only for own comments)
                    if (isOwnComment) ...[
                      const SizedBox(width: ORASpacing.md),
                      _buildActionButton(
                        context,
                        icon: Icons.more_horiz,
                        label: '',
                        onTap: () => _showCommentMenu(context),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isActive = false,
    bool isLoading = false,
  }) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ORAColors.primary(brightness),
              ),
            )
          else
            Icon(
              icon,
              color: isActive
                  ? Colors.red
                  : ORAColors.textTertiary(brightness),
              size: 16,
            ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: ORATypography.caption(context).copyWith(
                color: isActive
                    ? Colors.red
                    : ORAColors.textTertiary(brightness),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCommentMenu(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    showModalBottomSheet(
      context: context,
      backgroundColor: ORAColors.surface(brightness),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ORARadius.medium),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: ORASpacing.sm),
              decoration: BoxDecoration(
                color: ORAColors.border(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: ORAColors.textSecondary(brightness),
              ),
              title: Text(
                'Edit',
                style: ORATypography.body(context).copyWith(
                  color: ORAColors.textPrimary(brightness),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: ORAColors.error(brightness),
              ),
              title: Text(
                'Delete',
                style: ORATypography.body(context).copyWith(
                  color: ORAColors.error(brightness),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
            const SizedBox(height: ORASpacing.sm),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
