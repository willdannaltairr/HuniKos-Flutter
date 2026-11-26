import '../core/api_client.dart';
import '../models/chat.dart';

/// Endpoint chat: daftar ruang, pesan, dan moderasi oleh pemilik.
class ChatService {
  ChatService(this._api);

  final ApiClient _api;

  Future<List<ChatRoom>> rooms() async {
    final payload = await _api.get('/api/chat/rooms');
    return payload.asList.map(ChatRoom.fromJson).toList(growable: false);
  }

  Future<ChatRoom> startDirect(String propertyId) async {
    final payload = await _api.post(
      '/api/chat/direct',
      body: {'property_id': propertyId},
    );
    return ChatRoom.fromJson(payload.asMap);
  }

  /// Membuka pesan sekaligus menandai ruang sebagai dibaca di backend.
  Future<List<ChatMessage>> messages(String roomId, {String? before}) async {
    final payload = await _api.get(
      '/api/chat/rooms/$roomId/messages',
      query: {'before': before, 'limit': 30},
    );
    return payload.asList.map(ChatMessage.fromJson).toList(growable: false);
  }

  Future<ChatMessage> sendMessage(String roomId, String content) async {
    final payload = await _api.post(
      '/api/chat/rooms/$roomId/messages',
      body: {'content': content.trim()},
    );
    return ChatMessage.fromJson(payload.asMap);
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    await _api.delete('/api/chat/rooms/$roomId/messages/$messageId');
  }
}
