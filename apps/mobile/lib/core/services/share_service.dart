import 'package:share_plus/share_plus.dart';

/// Service for sharing content from the ORA app.
class ShareService {
  /// Share a profile link.
  Future<void> shareProfile(String userId, String username) async {
    final text = 'Check out @$username on ORA!\nUser ID: $userId';
    await _share(text);
  }

  /// Share a post.
  Future<void> sharePost(String postId, String username, String content) async {
    final text = 'Check out this post by @$username on ORA!\n\n$content\n\nPost ID: $postId';
    await _share(text);
  }

  /// Share a hood.
  Future<void> shareHood(String hoodId, String hoodName) async {
    final text = 'Join $hoodName on ORA!\nHood ID: $hoodId';
    await _share(text);
  }

  /// Generic share method.
  Future<void> _share(String text) async {
    try {
      await Share.share(text);
    } catch (e) {
      // If share_plus fails, we could fallback to clipboard
      // For now, just rethrow
      rethrow;
    }
  }
}