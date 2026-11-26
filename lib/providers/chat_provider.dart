import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';

/// State chat: daftar ruang dan pesan per ruang.
class ChatProvider extends ChangeNotifier {
  ChatProvider(this._service);

  final ChatService _service;

  final List<ChatRoom> _rooms = [];
  bool _loadingRooms = false;
  String? _roomsError;

  final Map<String, List<ChatMessage>> _messagesByRoom = {};
  bool _loadingMessages = false;
  String? _messagesError;
  bool _sending = false;
  String? _actionError;

  List<ChatRoom> get rooms => List.unmodifiable(_rooms);
  bool get loadingRooms => _loadingRooms;
  String? get roomsError => _roomsError;

  /// Pesan diambil per ruang supaya dua ruang tidak saling menimpa.
  List<ChatMessage> messagesFor(String roomId) =>
      List.unmodifiable(_messagesByRoom[roomId] ?? const []);

  bool get loadingMessages => _loadingMessages;
  String? get messagesError => _messagesError;
  bool get sending => _sending;
  String? get actionError => _actionError;

  Future<void> loadRooms() async {
    _loadingRooms = true;
    _roomsError = null;
    notifyListeners();

    try {
      final result = await _service.rooms();
      _rooms
        ..clear()
        ..addAll(result);
    } on ApiException catch (error) {
      _roomsError = error.message;
    } finally {
      _loadingRooms = false;
      notifyListeners();
    }
  }

  /// Versi senyap untuk polling: tidak menyalakan indikator loading supaya
  /// daftar tidak berkedip setiap tiga detik.
  Future<void> refreshRooms() async {
    try {
      final result = await _service.rooms();
      _rooms
        ..clear()
        ..addAll(result);
      notifyListeners();
    } on ApiException {
      // Polling gagal tidak perlu mengganggu pengguna; retry berikutnya cukup.
    }
  }

  /// Membuka (atau membuat) ruang privat untuk satu properti.
  Future<ChatRoom?> startDirect(String propertyId) async {
    _actionError = null;
    _sending = true;
    notifyListeners();

    try {
      final room = await _service.startDirect(propertyId);
      _upsertRoom(room);
      return room;
    } on ApiException catch (error) {
      _actionError = error.message;
      return null;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<bool> openRoom(String roomId) async {
    _loadingMessages = true;
    _messagesError = null;
    _messagesByRoom.remove(roomId);
    notifyListeners();

    try {
      final result = await _service.messages(roomId);
      _mergeMessages(roomId, result);
      _markRoomRead(roomId);
      return true;
    } on ApiException catch (error) {
      _messagesError = error.message;
      return false;
    } finally {
      _loadingMessages = false;
      notifyListeners();
    }
  }

  /// Polling pesan. Tidak menimpa pesan yang baru saja dikirim pengguna.
  Future<void> refreshMessages(String roomId) async {
    try {
      final result = await _service.messages(roomId);
      _mergeMessages(roomId, result);
      _markRoomRead(roomId);
      notifyListeners();
    } on ApiException {
      // Sengaja diabaikan: pesan snackbar tiap tiga detik sangat mengganggu.
    }
  }

  Future<bool> sendMessage(String roomId, String content) async {
    final text = content.trim();
    if (text.isEmpty) return false;

    _sending = true;
    _actionError = null;
    notifyListeners();

    try {
      final message = await _service.sendMessage(roomId, text);
      _mergeMessages(roomId, [message]);
      _updateRoomSummary(roomId, message);
      return true;
    } on ApiException catch (error) {
      _actionError = error.message;
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  /// Hanya pemilik yang memanggil ini; backend tetap memeriksa peran.
  Future<bool> deleteMessage(String roomId, String messageId) async {
    _sending = true;
    _actionError = null;
    notifyListeners();

    try {
      await _service.deleteMessage(roomId, messageId);
      _messagesByRoom[roomId] =
          (_messagesByRoom[roomId] ?? []).where((item) => item.id != messageId).toList();
      return true;
    } on ApiException catch (error) {
      _actionError = error.message;
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  /// Dikosongkan saat sesi berakhir, supaya akun berikutnya di perangkat yang
  /// sama tidak melihat pesan milik akun sebelumnya.
  void reset() {
    _rooms.clear();
    _loadingRooms = false;
    _roomsError = null;
    _messagesByRoom.clear();
    _loadingMessages = false;
    _messagesError = null;
    _sending = false;
    _actionError = null;
    notifyListeners();
  }

  void _mergeMessages(String roomId, List<ChatMessage> incoming) {
    final merged = <ChatMessage>[];
    final seen = <String>{};
    for (final message in [..._messagesByRoom[roomId] ?? const <ChatMessage>[], ...incoming]) {
      // Pesan yang sama bisa muncul di hasil kirim dan di polling berikutnya.
      if (!seen.add(message.id)) continue;
      merged.add(message);
    }
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _messagesByRoom[roomId] = merged;
  }

  void _upsertRoom(ChatRoom room) {
    final index = _rooms.indexWhere((item) => item.id == room.id);
    if (index == -1) {
      _rooms.insert(0, room);
    } else {
      _rooms[index] = room;
    }
  }

  void _markRoomRead(String roomId) {
    final index = _rooms.indexWhere((item) => item.id == roomId);
    if (index != -1 && _rooms[index].unreadCount != 0) {
      _rooms[index] = _rooms[index].copyWith(unreadCount: 0);
    }
  }

  void _updateRoomSummary(String roomId, ChatMessage message) {
    final index = _rooms.indexWhere((item) => item.id == roomId);
    if (index == -1) return;
    _rooms[index] = _rooms[index].copyWith(
      lastMessage: message.content,
      lastMessageAt: message.createdAt,
    );
  }
}
