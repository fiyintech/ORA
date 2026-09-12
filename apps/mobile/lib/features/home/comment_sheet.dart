import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/comment.dart';
import 'package:mobile/core/models/post.dart';
import 'package:mobile/core/theme/ora_colors.dart';
import 'package:mobile/core/theme/ora_radius.dart';
import 'package:mobile/core/theme/ora_spacing.dart';
import 'package:mobile/core/theme/ora_typography.dart';
import 'package:mobile/features/home/feed_provider.dart';
import 'package:mobile/features/session/session_provider.dart';
import 'package:mobile/shared/widgets/ora_comment_composer.dart';
import 'package:mobile/shared/widgets/ora_comment_item.dart';
import 'package:mobile/shared/widgets/ora_empty_state.dart';
import 'package:mobile/shared/widgets/ora_loading_indicator.dart';

/// ORA Comment Sheet
///
/// A draggable bottom sheet that displays comments for a post.
/// Supports loading, empty states, and a composer for new comments.
class CommentSheet extends ConsumerStatefulWidget {
  final Post post;

  const CommentSheet({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isSendingReply = false;
  String? _error;
  String? _replyingToCommentId;
  final Set<String> _likedCommentIds = {};
  final Set<String> _likingCommentIds = {};

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final comments = await ref.read(feedProvider.notifier).loadComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
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

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSending = true);

    final comment = Comment(
      id: '',
      postId: widget.post.id,
      userId: currentUser.id,
      username: currentUser.username,
      content: text,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(feedProvider.notifier).createComment(comment);
      
      if (mounted) {
        _commentController.clear();
        _loadComments();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  /// Toggles a like on a comment with optimistic UI update.
  ///
  /// Updates the like icon/count immediately, calls the provider to persist,
  /// and rolls back if persistence fails.
  Future<void> _toggleCommentLike(Comment comment) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final commentId = comment.id;
    final wasLiked = _likedCommentIds.contains(commentId);

    // Prevent concurrent toggles on the same comment.
    if (_likingCommentIds.contains(commentId)) return;

    // Optimistic update.
    setState(() {
      _likingCommentIds.add(commentId);
      if (wasLiked) {
        _likedCommentIds.remove(commentId);
      } else {
        _likedCommentIds.add(commentId);
      }
      _comments = _comments.map((c) {
        if (c.id == commentId) {
          return c.copyWith(
            likesCount: wasLiked ? (c.likesCount > 0 ? c.likesCount - 1 : 0) : c.likesCount + 1,
          );
        }
        return c;
      }).toList();
    });

    try {
      await ref.read(feedProvider.notifier).toggleCommentLike(commentId, currentUser.id);
      // Keep the optimistic state; the provider persisted successfully.
    } catch (e) {
      // Rollback on failure.
      if (mounted) {
        setState(() {
          if (wasLiked) {
            _likedCommentIds.add(commentId);
          } else {
            _likedCommentIds.remove(commentId);
          }
          _comments = _comments.map((c) {
            if (c.id == commentId) {
              return c.copyWith(likesCount: comment.likesCount);
            }
            return c;
          }).toList();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _likingCommentIds.remove(commentId));
      }
    }
  }

  /// Shows the inline reply composer for a comment.
  void _startReply(Comment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
      _replyController.clear();
    });
  }

  /// Submits a reply to the given parent comment.
  Future<void> _sendReply(Comment parent) async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSendingReply) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isSendingReply = true);

    final reply = Comment(
      id: '',
      postId: widget.post.id,
      userId: currentUser.id,
      username: currentUser.username,
      content: text,
      parentId: parent.id,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(feedProvider.notifier).createComment(reply);
      if (mounted) {
        _replyController.clear();
        setState(() => _replyingToCommentId = null);
        await _loadComments();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingReply = false);
      }
    }
  }

  /// Returns the list of top-level comments (no parent).
  List<Comment> _getTopLevelComments() {
    return _comments.where((c) => c.parentId == null).toList();
  }

  /// Returns replies belonging to a parent comment, sorted oldest first.
  List<Comment> _getReplies(Comment parent) {
    final replies = _comments.where((c) => c.parentId == parent.id).toList();
    replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return replies;
  }

  Future<void> _editComment(Comment comment) async {
    final result = await _showEditDialog(comment);
    if (result != null) {
      final updatedComment = comment.copyWith(
        content: result,
        isEdited: true,
        updatedAt: DateTime.now(),
      );
      await ref.read(feedProvider.notifier).editComment(updatedComment);
      _loadComments();
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    await ref.read(feedProvider.notifier).deleteComment(comment.id, comment.postId);
    _loadComments();
  }

  Future<String?> _showEditDialog(Comment comment) {
    final controller = TextEditingController(text: comment.text);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ORAColors.surface(Theme.of(context).brightness),
        title: Text(
          'Edit Comment',
          style: ORATypography.title(context),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: ORATypography.body(context),
          decoration: InputDecoration(
            hintText: 'Edit your comment...',
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
            onPressed: () => Navigator.pop(context, controller.text.trim()),
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
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      decoration: BoxDecoration(
        color: ORAColors.background(brightness),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ORARadius.large),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: ORASpacing.sm, bottom: ORASpacing.sm),
            decoration: BoxDecoration(
              color: ORAColors.border(brightness),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments',
                  style: ORATypography.title(context).copyWith(
                    color: ORAColors.textPrimary(brightness),
                  ),
                ),
                Text(
                  '${_comments.length} replies',
                  style: ORATypography.caption(context).copyWith(
                    color: ORAColors.textTertiary(brightness),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ORASpacing.sm),
          // Content
          Expanded(
            child: _isLoading
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
                    : _comments.isEmpty
                        ? ORAEmptyState(
                            title: 'No comments yet',
                            description: 'Be the first to share your thoughts!',
                            icon: Icons.comment_outlined,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ORASpacing.lg,
                              vertical: ORASpacing.sm,
                            ),
                            itemCount: _getTopLevelComments().length,
                            itemBuilder: (context, index) {
                              final comment = _getTopLevelComments()[index];
                              return _buildCommentWithReplies(context, comment, currentUser);
                            },
                          ),
          ),
          // Inline reply composer (shown beneath the selected comment)
          if (currentUser != null && _replyingToCommentId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ORASpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Replying',
                        style: ORATypography.caption(context).copyWith(
                          color: ORAColors.textSecondary(brightness),
                        ),
                      ),
                      const SizedBox(width: ORASpacing.sm),
                      Expanded(
                        child: Text(
                          _comments
                              .firstWhere(
                                 (c) => c.id == _replyingToCommentId,
                                 orElse: () => _comments.isNotEmpty ? _comments.first : Comment(
                                   id: '',
                                   postId: widget.post.id,
                                   userId: '',
                                   username: '',
                                   content: '',
                                   createdAt: DateTime.now(),
                                 ),
                               )
                              .username,
                          style: ORATypography.caption(context).copyWith(
                            color: ORAColors.primary(brightness),
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: ORAColors.textTertiary(brightness),
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _replyingToCommentId = null),
                      ),
                    ],
                  ),
                  ORACommentComposer(
                    controller: _replyController,
                    onSend: () {
                      final parent = _comments.firstWhere(
                        (c) => c.id == _replyingToCommentId,
                        orElse: () => _comments.isNotEmpty ? _comments.first : Comment(
                          id: '',
                          postId: widget.post.id,
                          userId: '',
                          username: '',
                          content: '',
                          createdAt: DateTime.now(),
                        ),
                      );
                      _sendReply(parent);
                    },
                    isSending: _isSendingReply,
                    currentUserId: currentUser.id,
                    currentUserFullName: currentUser.fullName,
                  ),
                ],
              ),
            ),
          // Composer
          if (currentUser != null && _replyingToCommentId == null)
            ORACommentComposer(
              controller: _commentController,
              onSend: _sendComment,
              isSending: _isSending,
              currentUserId: currentUser.id,
              currentUserFullName: currentUser.fullName,
            ),
        ],
      ),
    );
  }

  /// Builds a top-level comment with its nested replies indented beneath it.
  Widget _buildCommentWithReplies(
    BuildContext context,
    Comment comment,
    dynamic currentUser,
  ) {
    final isOwnComment = currentUser?.id == comment.userId;
    final replies = _getReplies(comment);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ORACommentItem(
          comment: comment,
          isOwnComment: isOwnComment,
          isLiked: _likedCommentIds.contains(comment.id),
          isLiking: _likingCommentIds.contains(comment.id),
          onLike: () => _toggleCommentLike(comment),
          onReply: () => _startReply(comment),
          onEdit: isOwnComment ? () => _editComment(comment) : null,
          onDelete: isOwnComment ? () => _deleteComment(comment) : null,
        ),
        // Nested replies, indented beneath the parent comment.
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: ORASpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: replies.map((reply) {
                final isOwnReply = currentUser?.id == reply.userId;
                return ORACommentItem(
                  comment: reply,
                  isOwnComment: isOwnReply,
                  isLiked: _likedCommentIds.contains(reply.id),
                  isLiking: _likingCommentIds.contains(reply.id),
                  onLike: () => _toggleCommentLike(reply),
                  onReply: () => _startReply(reply),
                  onEdit: isOwnReply ? () => _editComment(reply) : null,
                  onDelete: isOwnReply ? () => _deleteComment(reply) : null,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

/// Shows the comment sheet as a draggable bottom sheet.
Future<void> showCommentSheet(BuildContext context, Post post) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => CommentSheet(
        post: post,
      ),
    ),
  );
}
