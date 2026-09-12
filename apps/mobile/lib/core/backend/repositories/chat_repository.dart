import 'package:mobile/core/utils/result.dart';

/// Contract for chat repository operations.
///
/// This interface defines the contract for chat/message data operations.
/// Network logic will be implemented in a future sprint.
///
/// Current behavior:
/// - Read/write locally.
/// - Backend sync will be added later.
///
/// TODO: Implement Supabase sync when backend is ready.
abstract class ChatRepository {
  /// Retrieves conversations for a user.
  ///
  /// TODO: Fetch from Supabase `conversations` table via `conversation_members`.
  Future<Result<List<Map<String, dynamic>>>> getConversations(String userId);

  /// Retrieves messages for a conversation.
  ///
  /// TODO: Fetch from Supabase `messages` table with read receipt updates.
  Future<Result<List<Map<String, dynamic>>>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  });

  /// Sends a message.
  ///
  /// TODO: Insert into Supabase `messages` table.
  /// TODO: Trigger realtime broadcast via Supabase Realtime.
  Future<Result<Map<String, dynamic>>> sendMessage(
    String conversationId,
    String senderId,
    String text,
  );

  /// Creates a new conversation.
  ///
  /// TODO: Insert into Supabase `conversations` and `conversation_members` tables.
  Future<Result<String>> createConversation(
    String userId,
    String otherUserId,
  );

  /// Marks messages as read.
  ///
  /// TODO: Update `messages` table with read receipts.
  Future<Result<void>> markAsRead(String conversationId, String userId);
}
