import '../core/formatters.dart';
import '../core/json_utils.dart';

/// Status percakapan: `direct` adalah chat pribadi, `group` adalah grup kos.
class ChatRoomType {
  const ChatRoomType._();

  static const direct = 'direct';
  static const group = 'group';

  static String label(String type) {
    switch (type) {
      case direct:
        return 'Chat pribadi';
      case group:
        return 'Grup kos';
      default:
        return type;
    }
  }
}

/// Satu ruang percakapan yang dikirim backend di `/api/chat/rooms`.
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.type,
    required this.name,
    required this.propertyId,
    required this.propertyName,
    this.roomBadge,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String id;
  final String type;
  final String name;
  final String propertyId;
  final String propertyName;
  final String? roomBadge;
  final String? lastMessage;
  final String? lastMessageAt;
  final int unreadCount;

  bool get isDirect => type == ChatRoomType.direct;
  bool get isGroup => type == ChatRoomType.group;

  /// Judul yang dipakai AppBar; nama properti lebih dikenal pengguna.
  String get displayName {
    if (propertyName.isNotEmpty && propertyName != '-') return propertyName;
    if (name.isNotEmpty && name != '-') return name;
    return 'Percakapan';
  }

  String get lastMessageTime => Formatters.dateTime(lastMessageAt);

  /// Dipakai provider setelah pesan dibaca atau dikirim agar ringkasan ruang
  /// tetap cocok dengan isi percakapan tanpa menunggu poll berikutnya.
  ChatRoom copyWith({
    String? id,
    String? type,
    String? name,
    String? propertyId,
    String? propertyName,
    String? roomBadge,
    String? lastMessage,
    String? lastMessageAt,
    int? unreadCount,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      roomBadge: roomBadge ?? this.roomBadge,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: asString(json['id']) ?? '',
      type: asString(json['type']) ?? ChatRoomType.direct,
      name: asString(json['name']) ?? '-',
      propertyId: asString(json['property_id']) ?? '',
      propertyName: asString(json['property_name']) ?? '-',
      roomBadge: asString(json['room_badge']),
      lastMessage: asString(json['last_message']),
      lastMessageAt: asString(json['last_message_at']),
      unreadCount: asInt(json['unread_count']) ?? 0,
    );
  }
}

/// Satu pesan di dalam ruang percakapan.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.roomBadge,
    this.isSystemMessage = false,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String? roomBadge;
  final String content;
  final bool isSystemMessage;
  final String createdAt;

  String get timeLabel => Formatters.dateTime(createdAt);

  /// Dipakai untuk membedakan bubble kanan (kita) dan kiri (orang lain).
  bool isFrom(String? userId) {
    if (userId == null || userId.isEmpty || senderId.isEmpty) return false;
    return senderId == userId;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: asString(json['id']) ?? '',
      senderId: asString(json['sender_id']) ?? '',
      senderName: asString(json['sender_name']) ?? '-',
      roomBadge: asString(json['room_badge']),
      content: asString(json['content']) ?? '',
      isSystemMessage: asBool(json['is_system_message']),
      createdAt: asString(json['created_at']) ?? '',
    );
  }
}
