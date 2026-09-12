import 'dart:convert';
import 'package:mobile/core/models/comment.dart';
import 'package:mobile/core/models/post.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Concrete implementation of FeedRepository using local persistence.
class PostRepository {
  /// Uploads an image to storage and returns the public URL.
  Future<Result<String>> uploadImage(String userId, String filePath) async {
    return Result.failure(const Failure('Not implemented in local repository'));
  }

  static const String _postsKey = 'posts';
  static const String _likesKey = 'post_likes';

  /// Retrieves a single post by ID.
  Future<Result<Post?>> getPost(String postId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsString = prefs.getString(_postsKey);

      if (postsString == null) {
        return Result.success(null);
      }

      final List<dynamic> postsList = jsonDecode(postsString);
      for (final json in postsList) {
        final post = Post.fromJson(json as Map<String, dynamic>);
        if (post.id == postId) {
          return Result.success(post);
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure('Failed to load post: $e'));
    }
  }

  /// Retrieves all posts for a user's feed.
  Future<Result<List<Post>>> loadPosts(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsString = prefs.getString(_postsKey);
      
      if (postsString == null) {
        return Result.success([]);
      }

      final List<dynamic> postsList = jsonDecode(postsString);
      final posts = postsList
          .map((json) => Post.fromJson(json as Map<String, dynamic>))
          .toList();

      return Result.success(posts);
    } catch (e) {
      return Result.failure(Failure('Failed to load posts: $e'));
    }
  }

  /// Creates a new post.
  Future<Result<Post>> createPost(Post post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsString = prefs.getString(_postsKey);
      
      List<dynamic> postsList = [];
      if (postsString != null) {
        postsList = jsonDecode(postsString);
      }

      postsList.add(post.toJson());
      
      await prefs.setString(_postsKey, jsonEncode(postsList));
      
      return Result.success(post);
    } catch (e) {
      return Result.failure(Failure('Failed to create post: $e'));
    }
  }

  /// Updates an existing post.
  Future<Result<Post>> updatePost(Post post) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsString = prefs.getString(_postsKey);
      
      if (postsString == null) {
        return Result.failure(Failure('Post not found'));
      }

      List<dynamic> postsList = jsonDecode(postsString);
      final postIndex = postsList.indexWhere((json) => json['id'] == post.id);
      
      if (postIndex == -1) {
        return Result.failure(Failure('Post not found'));
      }

      postsList[postIndex] = post.toJson();
      
      await prefs.setString(_postsKey, jsonEncode(postsList));
      
      return Result.success(post);
    } catch (e) {
      return Result.failure(Failure('Failed to update post: $e'));
    }
  }

  /// Deletes a post.
  Future<Result<void>> deletePost(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsString = prefs.getString(_postsKey);
      
      if (postsString == null) {
        return Result.failure(Failure('Post not found'));
      }

      List<dynamic> postsList = jsonDecode(postsString);
      postsList.removeWhere((json) => json['id'] == postId);
      
      await prefs.setString(_postsKey, jsonEncode(postsList));
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure('Failed to delete post: $e'));
    }
  }

  /// Toggles a like on a post.
  ///
  /// Adds the user to the likedBy set if not already present,
  /// or removes them if they already liked the post.
  /// Returns the updated like count and whether the post is now liked.
  ///
  /// TODO: Award Aura points to the post author when a post receives a like.
  /// TODO: Deduct Aura points from the post author when a like is removed.
  Future<Result<LikeToggleResult>> toggleLike(String postId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsString = prefs.getString(_postsKey);
      
      if (postsString == null) {
        return Result.failure(Failure('Post not found'));
      }

      List<dynamic> postsList = jsonDecode(postsString);
      final postIndex = postsList.indexWhere((json) => json['id'] == postId);
      
      if (postIndex == -1) {
        return Result.failure(Failure('Post not found'));
      }

      final post = Post.fromJson(postsList[postIndex] as Map<String, dynamic>);
      
      final isLiked = post.likedBy.contains(userId);
      final updatedLikedBy = Set<String>.from(post.likedBy);
      
      if (isLiked) {
        updatedLikedBy.remove(userId);
      } else {
        updatedLikedBy.add(userId);
      }

      final updatedPost = post.copyWith(
        likes: updatedLikedBy.length,
        likedBy: updatedLikedBy,
      );

      postsList[postIndex] = updatedPost.toJson();
      await prefs.setString(_postsKey, jsonEncode(postsList));

      return Result.success(LikeToggleResult(
        isLiked: !isLiked,
        likes: updatedLikedBy.length,
      ));
    } catch (e) {
      return Result.failure(Failure('Failed to toggle like: $e'));
    }
  }

  /// Legacy like method — kept for backward compatibility.
  /// Prefer [toggleLike] for new code.
  Future<Result<void>> likePost(String postId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likesString = prefs.getString(_likesKey);
      
      Map<String, List<String>> likesMap = {};
      if (likesString != null) {
        final Map<String, dynamic> decoded = jsonDecode(likesString);
        likesMap = decoded.map((key, value) => 
          MapEntry(key, List<String>.from(value)));
      }

      if (!likesMap.containsKey(postId)) {
        likesMap[postId] = [];
      }

      if (!likesMap[postId]!.contains(userId)) {
        likesMap[postId]!.add(userId);
      }

      await prefs.setString(_likesKey, jsonEncode(likesMap));
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure('Failed to like post: $e'));
    }
  }

  /// Legacy unlike method — kept for backward compatibility.
  /// Prefer [toggleLike] for new code.
  Future<Result<void>> unlikePost(String postId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likesString = prefs.getString(_likesKey);
      
      if (likesString == null) {
        return Result.success(null);
      }

      Map<String, dynamic> likesMap = jsonDecode(likesString);
      
      if (likesMap.containsKey(postId)) {
        List<String> likes = List<String>.from(likesMap[postId]);
        likes.remove(userId);
        likesMap[postId] = likes;
        
        await prefs.setString(_likesKey, jsonEncode(likesMap));
      }
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure('Failed to unlike post: $e'));
    }
  }

  /// Creates a new comment on a post.
  Future<Result<Comment>> createComment(Comment comment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsString = prefs.getString('comments');
      
      List<dynamic> commentsList = [];
      if (commentsString != null) {
        commentsList = jsonDecode(commentsString);
      }

      commentsList.add(comment.toJson());
      
      await prefs.setString('comments', jsonEncode(commentsList));
      
      // Update post comment count
      await _incrementCommentCount(comment.postId);
      
      return Result.success(comment);
    } catch (e) {
      return Result.failure(Failure('Failed to create comment: $e'));
    }
  }

  /// Edits an existing comment.
  Future<Result<Comment>> editComment(Comment comment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsString = prefs.getString('comments');
      
      if (commentsString == null) {
        return Result.failure(Failure('Comment not found'));
      }

      List<dynamic> commentsList = jsonDecode(commentsString);
      final commentIndex = commentsList.indexWhere((json) => json['id'] == comment.id);
      
      if (commentIndex == -1) {
        return Result.failure(Failure('Comment not found'));
      }

      // Update comment with edited flag
      final updatedComment = comment.copyWith(
        isEdited: true,
        updatedAt: DateTime.now(),
      );
      
      commentsList[commentIndex] = updatedComment.toJson();
      
      await prefs.setString('comments', jsonEncode(commentsList));
      
      return Result.success(updatedComment);
    } catch (e) {
      return Result.failure(Failure('Failed to edit comment: $e'));
    }
  }

  /// Soft deletes a comment.
  Future<Result<void>> deleteComment(String commentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsString = prefs.getString('comments');
      
      if (commentsString == null) {
        return Result.failure(Failure('Comment not found'));
      }

      List<dynamic> commentsList = jsonDecode(commentsString);
      final commentIndex = commentsList.indexWhere((json) => json['id'] == commentId);
      
      if (commentIndex == -1) {
        return Result.failure(Failure('Comment not found'));
      }

      // Soft delete
      final comment = Comment.fromJson(commentsList[commentIndex]);
      final deletedComment = comment.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      
      commentsList[commentIndex] = deletedComment.toJson();
      
      await prefs.setString('comments', jsonEncode(commentsList));
      
      // Update post comment count
      await _decrementCommentCount(comment.postId);
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(Failure('Failed to delete comment: $e'));
    }
  }

  /// Gets all comments for a post.
  Future<Result<List<Comment>>> getComments(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsString = prefs.getString('comments');
      
      if (commentsString == null) {
        return Result.success([]);
      }

      List<dynamic> commentsList = jsonDecode(commentsString);
      final comments = commentsList
          .map((json) => Comment.fromJson(json as Map<String, dynamic>))
          .where((comment) => comment.postId == postId && !comment.isDeleted)
          .toList();

      // Sort by newest first
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return Result.success(comments);
    } catch (e) {
      return Result.failure(Failure('Failed to load comments: $e'));
    }
  }

  /// Checks if a post is bookmarked by a user.
  Future<Result<bool>> isBookmarked(String postId, String userId) async {
    return Result.success(false);
  }

  /// Bookmarks a post for a user.
  Future<Result<void>> bookmarkPost(String postId, String userId) async {
    return Result.success(null);
  }

  /// Removes a bookmark from a post for a user.
  Future<Result<void>> removeBookmark(String postId, String userId) async {
    return Result.success(null);
  }

  /// Loads all bookmarked posts for a user.
  Future<Result<List<Post>>> loadBookmarks(String userId) async {
    return Result.success([]);
  }

  /// Toggles a like on a comment.
  Future<Result<LikeToggleResult>> toggleCommentLike(String commentId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likesString = prefs.getString('comment_likes');
      
      Map<String, List<String>> likesMap = {};
      if (likesString != null) {
        final Map<String, dynamic> decoded = jsonDecode(likesString);
        likesMap = decoded.map((key, value) => 
          MapEntry(key, List<String>.from(value)));
      }

      if (!likesMap.containsKey(commentId)) {
        likesMap[commentId] = [];
      }

      final isLiked = likesMap[commentId]!.contains(userId);
      
      if (isLiked) {
        likesMap[commentId]!.remove(userId);
      } else {
        likesMap[commentId]!.add(userId);
      }

      await prefs.setString('comment_likes', jsonEncode(likesMap));
      
      // Update comment likes count
      await _updateCommentLikesCount(commentId, likesMap[commentId]!.length);
      
      return Result.success(LikeToggleResult(
        isLiked: !isLiked,
        likes: likesMap[commentId]!.length,
      ));
    } catch (e) {
      return Result.failure(Failure('Failed to toggle comment like: $e'));
    }
  }

  /// Helper to increment comment count on a post.
  Future<void> _incrementCommentCount(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsString = prefs.getString(_postsKey);
      
      if (postsString == null) return;

      List<dynamic> postsList = jsonDecode(postsString);
      final postIndex = postsList.indexWhere((json) => json['id'] == postId);
      
      if (postIndex != -1) {
        final post = Post.fromJson(postsList[postIndex]);
        final updatedPost = post.copyWith(
          comments: post.comments + 1,
        );
        postsList[postIndex] = updatedPost.toJson();
        await prefs.setString(_postsKey, jsonEncode(postsList));
      }
    } catch (e) {
      // Silently fail - comment count update is not critical
    }
  }

  /// Helper to decrement comment count on a post.
  Future<void> _decrementCommentCount(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsString = prefs.getString(_postsKey);
      
      if (postsString == null) return;

      List<dynamic> postsList = jsonDecode(postsString);
      final postIndex = postsList.indexWhere((json) => json['id'] == postId);
      
      if (postIndex != -1) {
        final post = Post.fromJson(postsList[postIndex]);
        final updatedPost = post.copyWith(
          comments: post.comments > 0 ? post.comments - 1 : 0,
        );
        postsList[postIndex] = updatedPost.toJson();
        await prefs.setString(_postsKey, jsonEncode(postsList));
      }
    } catch (e) {
      // Silently fail - comment count update is not critical
    }
  }

  /// Helper to update comment likes count.
  Future<void> _updateCommentLikesCount(String commentId, int likesCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final commentsString = prefs.getString('comments');
      
      if (commentsString == null) return;

      List<dynamic> commentsList = jsonDecode(commentsString);
      final commentIndex = commentsList.indexWhere((json) => json['id'] == commentId);
      
      if (commentIndex != -1) {
        final comment = Comment.fromJson(commentsList[commentIndex]);
        final updatedComment = comment.copyWith(
          likesCount: likesCount,
        );
        commentsList[commentIndex] = updatedComment.toJson();
        await prefs.setString('comments', jsonEncode(commentsList));
      }
    } catch (e) {
      // Silently fail - likes count update is not critical
    }
  }
}

/// Result of a toggle like operation.
class LikeToggleResult {
  final bool isLiked;
  final int likes;

  const LikeToggleResult({
    required this.isLiked,
    required this.likes,
  });
}
