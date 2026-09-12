import 'package:mobile/core/models/message.dart';
import 'package:mobile/core/models/chat.dart';

class ChatService {
  // TODO: Implement chat logic
  // - Send message
  // - Receive messages
  // - Get conversations
  // - Mark as read
  // - Delete conversation
  
  Future<void> sendMessage(String conversationId, String text) async {
    throw UnimplementedError('ChatService.sendMessage not implemented');
  }
  
  Future<List<Message>> getMessages(String conversationId) async {
    throw UnimplementedError('ChatService.getMessages not implemented');
  }
  
  Future<List<Chat>> getConversations() async {
    throw UnimplementedError('ChatService.getConversations not implemented');
  }
  
  Future<void> markAsRead(String conversationId) async {
    throw UnimplementedError('ChatService.markAsRead not implemented');
  }
}