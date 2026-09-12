import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/post.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/home/comment_sheet.dart';
import 'package:mobile/features/home/feed_provider.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_empty_state.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';
import 'package:mobile/shared/widgets/ora_post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// ORA Bookmarks Page
///
/// Displays all posts bookmarked by the current user.
/// Reuses the existing [ORAPostCard] widget.
class BookmarksPage extends ConsumerStatefulWidget {
  const BookmarksPage({super.key});

  @override
  ConsumerState<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends ConsumerState<BookmarksPage> {
  List<Post> _bookmarks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookmarks = await ref
          .read(feedProvider.notifier)
          .loadBookmarks(currentUser.id);

      if (mounted) {
        setState(() {
          _bookmarks = bookmarks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      appBar: AppBar(
        backgroundColor: ORAColors.background(brightness),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Bookmarks',
          style: ORATypography.title(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: ORALoadingIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: ORATypography.body(context).copyWith(
                      color: ORAColors.error(brightness),
                    ),
                  ),
                )
              : _bookmarks.isEmpty
                  ? ORAEmptyState(
                      title: 'No bookmarked posts yet.',
                      description: 'Tap the ⋮ menu on a post to bookmark it.',
                      icon: Icons.bookmark_outline,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBookmarks,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(ORASpacing.lg),
                        itemCount: _bookmarks.length,
                        itemBuilder: (context, index) {
                          final post = _bookmarks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: ORASpacing.md),
                            child: _buildBookmarkCard(context, post),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildBookmarkCard(BuildContext context, Post post) {
    final brightness = Theme.of(context).brightness;
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';

    // Generate avatar letter from username (first letter)
    final avatarLetter =
        post.username.isNotEmpty ? post.username[0].toUpperCase() : '?';

    // Format timestamp
    final now = DateTime.now();
    final difference = now.difference(post.createdAt);
    String time;
    if (difference.inMinutes < 1) {
      time = 'Just now';
    } else if (difference.inMinutes < 60) {
      time = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      time = '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      time = '${difference.inDays}d ago';
    } else {
      time =
          '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}';
    }

    // Determine gradient colors based on user
    final gradientColors = post.userId.hashCode % 2 == 0
        ? [ORAColors.primary(brightness), ORAColors.secondary(brightness)]
        : [ORAColors.accent(brightness), ORAColors.accent(brightness)];

    // Build the media widget from the post's image URL, if present.
    final media = post.mediaUrls != null && post.mediaUrls!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: post.mediaUrls!.first,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: double.infinity,
              height: 200,
              color: ORAColors.surface(brightness).withValues(alpha: 0.5),
              child: const Center(child: ORALoadingIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              width: double.infinity,
              height: 200,
              color: ORAColors.surface(brightness).withValues(alpha: 0.5),
              child: Icon(
                Icons.broken_image_outlined,
                color: ORAColors.textTertiary(brightness),
                size: 48,
              ),
            ),
          )
        : null;

    return ORAPostCard(
      avatarLetter: avatarLetter,
      avatarGradientColors: gradientColors,
      username: post.username,
      time: time,
      content: post.content,
      media: media,
      showSyncingBadge: post.pendingSync,
      showVisibilityBadge: !post.isPublic,
      visibilityLabel: 'Friends',
      footerActions: [
        _buildBookmarkAction(
          context,
          icon: Icons.favorite_border,
          label: post.likes.toString(),
          onTap: () =>
              ref.read(feedProvider.notifier).toggleLike(post.id, userId),
        ),
        const SizedBox(width: ORASpacing.lg),
        _buildBookmarkAction(
          context,
          icon: Icons.chat_bubble_outline_rounded,
          label: post.comments.toString(),
          onTap: () => showCommentSheet(context, post),
        ),
        const Spacer(),
        _buildBookmarkAction(
          context,
          icon: Icons.bookmark_rounded,
          label: 'Saved',
          onTap: () async {
            if (currentUser == null) return;
            try {
              await ref
                  .read(feedProvider.notifier)
                  .removeBookmark(post.id, currentUser.id);
              if (!mounted || !context.mounted) return;
              setState(() {
                _bookmarks.removeWhere((p) => p.id == post.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bookmark removed')),
              );
            } catch (e) {
              if (!mounted || !context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to remove bookmark')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildBookmarkAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ORAColors.textTertiary(brightness), size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: ORATypography.caption(context).copyWith(
              color: ORAColors.textTertiary(brightness),
            ),
          ),
        ],
      ),
    );
  }
}