import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a saved draft post.
class DraftPost {
  final String text;
  final String visibility;
  final String? hoodId;
  final String? imagePath;

  const DraftPost({
    required this.text,
    required this.visibility,
    this.hoodId,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'visibility': visibility,
      'hoodId': hoodId,
      'imagePath': imagePath,
    };
  }

  factory DraftPost.fromJson(Map<String, dynamic> json) {
    return DraftPost(
      text: json['text'] as String? ?? '',
      visibility: json['visibility'] as String? ?? 'Public',
      hoodId: json['hoodId'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }
}

/// Service for persisting and restoring draft posts locally.
class DraftService {
  static const String _draftKey = 'draft_post';

  /// Saves the current draft to local storage.
  Future<void> saveDraft(DraftPost draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  /// Loads a saved draft from local storage, if one exists.
  Future<DraftPost?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftString = prefs.getString(_draftKey);
    if (draftString == null) return null;

    try {
      final json = jsonDecode(draftString) as Map<String, dynamic>;
      final draft = DraftPost.fromJson(json);
      // Only restore non-empty drafts
      if (draft.text.isEmpty && draft.imagePath == null) return null;
      return draft;
    } catch (_) {
      return null;
    }
  }

  /// Deletes the saved draft from local storage.
  Future<void> deleteDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }
}