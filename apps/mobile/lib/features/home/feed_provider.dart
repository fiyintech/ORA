import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/aura/aura_action.dart';
import 'package:mobile/core/aura/aura_engine.dart';
import 'package:mobile/core/models/comment.dart';
import 'package:mobile/core/models/post.dart';
import 'package:mobile/core/backend/repositories/post_repository.dart';
import 'package:mobile/core/backend/repositories/impl/post_repository_impl.dart';

class FeedState {
  final List<Post> posts;
  final bool loading;
  final bool refreshing;
  final String? error;

  const FeedState({
    this.posts = const [],
    this.loading = false,
    this.refreshing = false,
    this.error,
  });

  FeedState copyWith({
    List<Post>? posts,
    bool? loading,
    bool? refreshing,
    String? error,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      error: error ?? this.error,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final PostRepository _postRepository;

  FeedNotifier(this._postRepository) : super(const FeedState());

  Future<void> loadFeed(String userId) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final result = await _postRepository.loadPosts(userId);

      result.when(
        success: (posts) {
          state = state.copyWith(posts: posts, loading: false);
        },
        failure: (failure) {
          state = state.copyWith(loading: false, error: failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> refreshFeed(String userId) async {
    state = state.copyWith(refreshing: true, error: null);

    try {
      final result = await _postRepository.loadPosts(userId);

      result.when(
        success: (posts) {
          state = state.copyWith(posts: posts, refreshing: false);
        },
        failure: (failure) {
          state = state.copyWith(refreshing: false, error: failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(refreshing: false, error: e.toString());
    }
  }

  Future<Post> createPost(Post post) async {
    try {
      final result = await _postRepository.createPost(post);

      return result.when(
        success: (createdPost) {
          state = state.copyWith(
            posts: [createdPost, ...state.posts],
            error: null,
          );
          return createdPost;
        },
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          throw Exception(failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Updates a post with optimistic update and rollback on failure.
  ///
  /// - Updates the UI immediately (optimistic).
  /// - Preserves likes/comments/shares.
  /// - Rolls back if persistence fails.
  Future<void> updatePost(Post post) async {
    final postIndex = state.posts.indexWhere((p) => p.id == post.id);
    if (postIndex == -1) return;

    final originalPost = state.posts[postIndex];

    // Optimistic update — preserve likes/comments/shares from the original.
    final optimisticPost = post.copyWith(
      likes: originalPost.likes,
      comments: originalPost.comments,
      shares: originalPost.shares,
      likedBy: originalPost.likedBy,
      updatedAt: DateTime.now(),
    );

    final updatedPosts = [...state.posts];
    updatedPosts[postIndex] = optimisticPost;
    state = state.copyWith(posts: updatedPosts);

    // Persist
    final result = await _postRepository.updatePost(optimisticPost);

    result.whenOrNull(
      success: (updatedPost) {
        // Replace with the server-confirmed post.
        final confirmedPosts = [...state.posts];
        final confirmedIndex = confirmedPosts.indexWhere(
          (p) => p.id == post.id,
        );
        if (confirmedIndex != -1) {
          confirmedPosts[confirmedIndex] = updatedPost;
          state = state.copyWith(posts: confirmedPosts);
        }
      },
      failure: (failure) {
        // Rollback on failure
        final rolledBackPosts = [...state.posts];
        rolledBackPosts[postIndex] = originalPost;
        state = state.copyWith(posts: rolledBackPosts, error: failure.message);
        throw Exception(failure.message);
      },
    );
  }

  Future<void> deletePost(String postId) async {
    try {
      final result = await _postRepository.deletePost(postId);

      result.when(
        success: (_) {
          state = state.copyWith(
            posts: state.posts.where((p) => p.id != postId).toList(),
          );
        },
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          throw Exception(failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Toggles a like on a post with optimistic update.
  ///
  /// - Updates the UI immediately (optimistic).
  /// - Persists the change locally.
  /// - Rolls back if persistence fails.
  ///
  /// Awards Aura to the post owner when liked, removes when unliked.
  Future<void> toggleLike(String postId, String userId) async {
    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = state.posts[postIndex];
    final wasLiked = post.isLikedBy(userId);
    final postOwnerId = post.userId;

    // Optimistic update
    final updatedLikedBy = Set<String>.from(post.likedBy);
    if (wasLiked) {
      updatedLikedBy.remove(userId);
    } else {
      updatedLikedBy.add(userId);
    }

    final optimisticPost = post.copyWith(
      likes: updatedLikedBy.length,
      likedBy: updatedLikedBy,
    );

    final updatedPosts = [...state.posts];
    updatedPosts[postIndex] = optimisticPost;
    state = state.copyWith(posts: updatedPosts);

    // Award/remove Aura for the post owner
    final auraEngine = AuraEngine();
    if (!wasLiked) {
      auraEngine.award(postOwnerId, AuraAction.receiveLike);
    } else {
      auraEngine.remove(postOwnerId, AuraAction.receiveLike);
    }

    // Persist
    final result = await _postRepository.toggleLike(postId, userId);

    result.whenOrNull(
      success: (_) {
        // Replace the optimistic post with the server-confirmed version.
        _refreshSinglePost(postId, userId);
      },
      failure: (failure) {
        // Rollback on failure
        final rolledBackPosts = [...state.posts];
        rolledBackPosts[postIndex] = post;
        state = state.copyWith(posts: rolledBackPosts, error: failure.message);
        throw Exception(failure.message);
      },
    );
  }

  /// Refreshes a single post from the server and replaces it in the feed.
  ///
  /// Used after like/comment operations to reconcile the optimistic
  /// update with the server-confirmed state without refreshing the
  /// entire feed.
  Future<void> _refreshSinglePost(String postId, String userId) async {
    final result = await _postRepository.getPost(postId, userId);

    result.whenOrNull(
      success: (serverPost) {
        if (serverPost == null) return;

        final updatedPosts = [...state.posts];
        final index = updatedPosts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          updatedPosts[index] = serverPost;
          state = state.copyWith(posts: updatedPosts);
        }
      },
    );
  }

  /// Legacy like method — kept for backward compatibility.
  /// Prefer [toggleLike] for new code.
  Future<void> likePost(String postId) async {
    try {
      if (state.posts.isEmpty) return;

      final userId = state.posts.first.userId;
      final result = await _postRepository.likePost(postId, userId);

      result.when(
        success: (_) {
          final updatedPosts = state.posts.map((post) {
            if (post.id == postId) {
              return post.copyWith(likes: post.likes + 1);
            }
            return post;
          }).toList();

          state = state.copyWith(posts: updatedPosts);
        },
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          throw Exception(failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Legacy unlike method — kept for backward compatibility.
  /// Prefer [toggleLike] for new code.
  Future<void> unlikePost(String postId) async {
    try {
      if (state.posts.isEmpty) return;

      final userId = state.posts.first.userId;
      final result = await _postRepository.unlikePost(postId, userId);

      result.when(
        success: (_) {
          final updatedPosts = state.posts.map((post) {
            if (post.id == postId && post.likes > 0) {
              return post.copyWith(likes: post.likes - 1);
            }
            return post;
          }).toList();

          state = state.copyWith(posts: updatedPosts);
        },
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          throw Exception(failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Loads comments for a post.
  Future<List<Comment>> loadComments(String postId) async {
    try {
      final result = await _postRepository.getComments(postId);

      return result.when(
        success: (comments) => comments,
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          throw Exception(failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Creates a new comment on a post.
  Future<void> createComment(Comment comment) async {
    try {
      final result = await _postRepository.createComment(comment);

      result.when(
        success: (createdComment) {
          // Update post comment count optimistically
          final updatedPosts = state.posts.map((post) {
            if (post.id == comment.postId) {
              return post.copyWith(comments: post.comments + 1);
            }
            return post;
          }).toList();

          state = state.copyWith(posts: updatedPosts);

          // Award Aura to post owner for receiving comment.
          final postIndex = state.posts.indexWhere(
            (p) => p.id == comment.postId,
          );
          if (postIndex != -1) {
            final auraEngine = AuraEngine();
            auraEngine.award(
              state.posts[postIndex].userId,
              AuraAction.receiveComment,
            );
          }

          // Replace the optimistic post with the server-confirmed version.
          _refreshSinglePost(comment.postId, comment.userId);
        },
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          throw Exception(failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Edits an existing comment.
  Future<void> editComment(Comment comment) async {
    try {
      final result = await _postRepository.editComment(comment);

      result.when(
        success: (updatedComment) {
          // TODO: Update comment in UI if we maintain comment state
        },
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          throw Exception(failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Deletes a comment.
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      final result = await _postRepository.deleteComment(commentId);

      result.when(
        success: (_) {
          // Update post comment count optimistically
          final updatedPosts = state.posts.map((post) {
            if (post.id == postId && post.comments > 0) {
              return post.copyWith(comments: post.comments - 1);
            }
            return post;
          }).toList();

          state = state.copyWith(posts: updatedPosts);
        },
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          throw Exception(failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Checks if a post is bookmarked by a user.
  Future<bool> isBookmarked(String postId, String userId) async {
    final result = await _postRepository.isBookmarked(postId, userId);
    return result.value ?? false;
  }

  /// Bookmarks a post for a user.
  Future<void> bookmarkPost(String postId, String userId) async {
    final result = await _postRepository.bookmarkPost(postId, userId);
    result.whenOrNull(
      failure: (failure) {
        state = state.copyWith(error: failure.message);
        throw Exception(failure.message);
      },
    );
  }

  /// Removes a bookmark from a post for a user.
  Future<void> removeBookmark(String postId, String userId) async {
    final result = await _postRepository.removeBookmark(postId, userId);
    result.whenOrNull(
      failure: (failure) {
        state = state.copyWith(error: failure.message);
        throw Exception(failure.message);
      },
    );
  }

  /// Loads all bookmarked posts for a user.
  Future<List<Post>> loadBookmarks(String userId) async {
    try {
      final result = await _postRepository.loadBookmarks(userId);

      return result.when(
        success: (posts) => posts,
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          throw Exception(failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Toggles a like on a comment.
  Future<void> toggleCommentLike(String commentId, String userId) async {
    try {
      final result = await _postRepository.toggleCommentLike(commentId, userId);

      result.whenOrNull(
        success: (likeResult) {
          // TODO: Update comment likes in UI if we maintain comment state
        },
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          throw Exception(failure.message);
        },
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl();
});

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final postRepository = ref.watch(postRepositoryProvider);
  return FeedNotifier(postRepository);
});
