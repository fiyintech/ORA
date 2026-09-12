import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/services/share_service.dart';
import 'package:mobile/core/models/post.dart';
import 'package:mobile/core/theme/ora_animations.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_shadows.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/home/comment_sheet.dart';
import 'package:mobile/features/home/feed_provider.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_avatar.dart';
import 'package:mobile/shared/widgets/ora_card.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';
import 'package:mobile/shared/widgets/ora_post_card.dart';
import 'package:mobile/shared/widgets/ora_empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: ORAColors.background(brightness),
      appBar: AppBar(
        backgroundColor: ORAColors.surface(brightness).withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: ORASpacing.lg,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ORAColors.primary(brightness),
                    ORAColors.secondary(brightness),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'O',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ORA',
              style: ORATypography.title(context).copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: ORAColors.textSecondary(brightness),
            ),
            onPressed: () => context.push("/search"),
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: ORAColors.textSecondary(brightness),
            ),
            onPressed: () => context.push("/notifications"),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ORAAvatar(
              letter: currentUser?.fullName ?? 'U',
              size: 32,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (currentUser != null) {
            await ref.read(feedProvider.notifier).refreshFeed(currentUser.id);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: ORASpacing.lg),
              // Create Post Card
              _buildCreatePostCard(context, ref),
              const SizedBox(height: ORASpacing.xxl),
              // Feed Section
              _buildFeedSection(context, ref),
              const SizedBox(height: ORASpacing.xxxl),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ORAColors.primary(brightness),
              ORAColors.secondary(brightness),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: ORAShadows.medium,
        ),
        child: FloatingActionButton(
          onPressed: () {
            context.push("/create-post");
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePostCard(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final currentUser = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
      child: GestureDetector(
        onTap: () {
          context.push("/create-post");
        },
        child: ORACard(
          padding: const EdgeInsets.all(ORASpacing.lg),
          child: Row(
            children: [
              ORAAvatar(
                letter: currentUser?.fullName ?? 'U',
                size: 40,
              ),
              const SizedBox(width: ORASpacing.md),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ORASpacing.lg,
                    vertical: ORASpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: ORAColors.surface(brightness).withValues(alpha: 0.5),
                    borderRadius: ORARadius.mediumAll,
                    border: Border.all(
                      color: ORAColors.border(brightness),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "What's happening today?",
                    style: ORATypography.caption(context).copyWith(
                      color: ORAColors.textTertiary(brightness),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedSection(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedProvider);
    final currentUser = ref.watch(currentUserProvider);
    final brightness = Theme.of(context).brightness;

    // Load feed on first build
    ref.listen<FeedState>(feedProvider, (previous, next) {
      if (previous == null && !next.loading && next.posts.isEmpty && currentUser != null) {
        ref.read(feedProvider.notifier).loadFeed(currentUser.id);
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: ORASpacing.xs, bottom: ORASpacing.md),
            child: Text(
              'Your World',
              style: ORATypography.title(context),
            ),
          ),
          // Loading state
          if (feedState.loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(ORASpacing.xxl),
                child: ORALoadingIndicator(
                  size: 40,
                  strokeWidth: 3,
                ),
              ),
            ),

          // Error state
          if (feedState.error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(ORASpacing.xxl),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: ORAColors.error(brightness),
                      size: 48,
                    ),
                    const SizedBox(height: ORASpacing.md),
                    Text(
                      'Failed to load posts',
                      style: ORATypography.body(context).copyWith(
                        color: ORAColors.textSecondary(brightness),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: ORASpacing.sm),
                    Text(
                      feedState.error!,
                      style: ORATypography.caption(context).copyWith(
                        color: ORAColors.textTertiary(brightness),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Empty state
          if (!feedState.loading && feedState.error == null && feedState.posts.isEmpty)
            ORAEmptyState(
              title: 'Your feed is waiting.',
              description: 'Share your first post or join a Hood.',
              icon: Icons.rocket_launch_rounded,
              buttonText: 'Create Post',
              onButtonPressed: () {
                context.push("/create-post");
              },
            ),

          // Posts list
          if (!feedState.loading && feedState.error == null)
            ...feedState.posts.map((post) {
              return Column(
                children: [
                  _buildFeedPost(context, post, ref: ref),
                  const SizedBox(height: ORASpacing.md),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFeedPost(BuildContext context, Post post, {required WidgetRef ref}) {
    final currentUser = ref.watch(currentUserProvider);
    final userId = currentUser?.id ?? '';
    final isLiked = post.isLikedBy(userId);
    final brightness = Theme.of(context).brightness;

    // Generate avatar letter from username (first letter)
    final avatarLetter = post.username.isNotEmpty ? post.username[0].toUpperCase() : '?';

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
      time = '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}';
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
              child: const Center(
                child: ORALoadingIndicator(),
              ),
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
      usernameTrailing: _buildPostOverflowMenu(context, post, ref, brightness),
      footerActions: [
        _AnimatedLikeButton(
          isLiked: isLiked,
          likes: post.likes,
          onTap: () => ref.read(feedProvider.notifier).toggleLike(post.id, userId),
        ),
        const SizedBox(width: ORASpacing.lg),
        _buildPostAction(
          context,
          icon: Icons.chat_bubble_outline_rounded,
          label: post.comments.toString(),
          activeColor: ORAColors.primary(brightness),
          onTap: () => showCommentSheet(context, post),
        ),
        const Spacer(),
          _buildPostAction(
            context,
            icon: Icons.share_outlined,
            label: 'Share',
            activeColor: ORAColors.accent(brightness),
            onTap: () {
              // TODO: Award Aura to post owner when shared via repository
              // final auraEngine = AuraEngine();
              // auraEngine.award(post.userId, AuraAction.receiveShare);
            },
          ),
      ],
    );
  }

  /// Builds the ⋮ overflow menu for a post.
  /// Owner sees: Edit, Delete, Copy Link, Share, Report.
  /// Non-owner sees: Copy Link, Share, Report.
  Widget _buildPostOverflowMenu(
    BuildContext context,
    Post post,
    WidgetRef ref,
    Brightness brightness,
  ) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser?.id == post.userId;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz_rounded,
        color: ORAColors.textTertiary(brightness),
        size: 20,
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editPost(context, ref, post);
            break;
          case 'delete':
            _deletePost(context, ref, post);
            break;
          case 'bookmark':
            _toggleBookmark(context, ref, post);
            break;
          case 'copy_link':
            _copyPostLink(context, post);
            break;
          case 'share':
            _sharePost(context, post);
            break;
          case 'report':
            _reportPost(context);
            break;
        }
      },
      itemBuilder: (context) => [
        if (isOwner) ...[
          const PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 12),
              Text('Edit'),
            ]),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline, size: 20),
              SizedBox(width: 12),
              Text('Delete'),
            ]),
          ),
        ],
        PopupMenuItem(
          value: 'bookmark',
          child: Row(children: [
            Icon(Icons.bookmark_outline, size: 20),
            const SizedBox(width: 12),
            const Text('Bookmark'),
          ]),
        ),
        const PopupMenuItem(
          value: 'copy_link',
          child: Row(children: [
            Icon(Icons.link_outlined, size: 20),
            SizedBox(width: 12),
            Text('Copy Link'),
          ]),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(children: [
            Icon(Icons.share_outlined, size: 20),
            SizedBox(width: 12),
            Text('Share'),
          ]),
        ),
        const PopupMenuItem(
          value: 'report',
          child: Row(children: [
            Icon(Icons.flag_outlined, size: 20),
            SizedBox(width: 12),
            Text('Report'),
          ]),
        ),
      ],
    );
  }

  /// Shows the edit post dialog, then optimistically updates the post.
  Future<void> _editPost(BuildContext context, WidgetRef ref, Post post) async {
    final textController = TextEditingController(text: post.content);

    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ORAColors.surface(Theme.of(context).brightness),
        title: Text(
          'Edit Post',
          style: ORATypography.title(context),
        ),
        content: TextField(
          controller: textController,
          maxLines: 4,
          maxLength: 500,
          style: ORATypography.body(context),
          decoration: InputDecoration(
            hintText: 'Edit your post...',
            border: OutlineInputBorder(
              borderRadius: ORARadius.mediumAll,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ORAColors.textSecondary(Theme.of(context).brightness),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, textController.text.trim()),
            child: Text(
              'Save',
              style: TextStyle(
                color: ORAColors.primary(Theme.of(context).brightness),
              ),
            ),
          ),
        ],
      ),
    );

    textController.dispose();

    if (newContent == null || newContent.isEmpty || newContent == post.content) return;

    // Optimistic update via feed provider (rolls back on failure).
    final updatedPost = post.copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(feedProvider.notifier).updatePost(updatedPost);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to edit post')),
        );
      }
    }
  }

  /// Shows a confirmation dialog and deletes the post optimistically.
  Future<void> _deletePost(BuildContext context, WidgetRef ref, Post post) async {
    final brightness = Theme.of(context).brightness;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ORAColors.surface(brightness),
        title: Text(
          'Delete Post?',
          style: ORATypography.title(context),
        ),
        content: Text(
          'This will permanently delete your post, media, comments, and likes.',
          style: ORATypography.body(context).copyWith(
            color: ORAColors.textSecondary(brightness),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ORAColors.textSecondary(brightness)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: ORAColors.error(brightness)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(feedProvider.notifier).deletePost(post.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete post')),
        );
      }
    }
  }

  /// Toggles a bookmark on a post with optimistic update.
  Future<void> _toggleBookmark(
    BuildContext context,
    WidgetRef ref,
    Post post,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final isBookmarked = await ref
          .read(feedProvider.notifier)
          .isBookmarked(post.id, currentUser.id);

      if (isBookmarked) {
        await ref
            .read(feedProvider.notifier)
            .removeBookmark(post.id, currentUser.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bookmark removed')),
          );
        }
      } else {
        await ref
            .read(feedProvider.notifier)
            .bookmarkPost(post.id, currentUser.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post bookmarked')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update bookmark')),
        );
      }
    }
  }

  /// Copies a temporary ORA link to the clipboard.
  Future<void> _copyPostLink(BuildContext context, Post post) async {
    final link = 'ora://post/${post.id}';
    await Clipboard.setData(ClipboardData(text: link));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  /// Shares the post using the platform share sheet.
  Future<void> _sharePost(BuildContext context, Post post) async {
    try {
      final shareService = ShareService();
      await shareService.sharePost(post.id, post.username, post.content);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share post')),
        );
      }
    }
  }

  /// Placeholder for post reporting.
  void _reportPost(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporting posts is coming soon.')),
    );
  }

  Widget _buildPostAction(BuildContext context, {
    required IconData icon,
    required String label,
    required Color activeColor,
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

class _AnimatedLikeButton extends StatelessWidget {
  final bool isLiked;
  final int likes;
  final VoidCallback onTap;

  const _AnimatedLikeButton({
    required this.isLiked,
    required this.likes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final activeColor = Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1,
        duration: ORAAnimations.fast,
        curve: Curves.easeInOut,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: ORAAnimations.fast,
              curve: Curves.easeInOut,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? activeColor : ORAColors.textTertiary(brightness),
                size: 18,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: ORAAnimations.fast,
              style: ORATypography.caption(context).copyWith(
                color: isLiked ? activeColor : ORAColors.textTertiary(brightness),
              ),
              child: Text(likes.toString()),
            ),
          ],
        ),
      ),
    );
  }
}