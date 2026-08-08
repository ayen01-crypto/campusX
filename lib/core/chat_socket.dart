import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_client.dart';
import 'models.dart';

class ChatSocket {
  ChatSocket(this.client);

  final ApiClient client;
  io.Socket? _socket;

  Future<void> connect({
    required String conversationId,
    required String currentUserId,
    required void Function(ChatMessage message) onMessage,
    void Function(bool connected)? onConnectionChanged,
  }) async {
    dispose();
    final token = await client.readAuthToken();
    if (token == null || token.isEmpty) return;

    final socket = io.io(
      '${client.socketUrl}/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(800)
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      onConnectionChanged?.call(true);
      socket.emit('conversation:join', conversationId);
    });
    socket.onDisconnect((_) => onConnectionChanged?.call(false));
    socket.onConnectError((_) => onConnectionChanged?.call(false));
    socket.onError((_) => onConnectionChanged?.call(false));
    socket.on('message:new', (raw) {
      if (raw is! Map) return;
      final map = Map<String, dynamic>.from(raw);
      final message = ChatMessage(
        id: map['clientId'] as String? ?? map['id'] as String? ?? '',
        text: map['body'] as String? ?? '',
        sentAt: DateTime.tryParse(map['sentAt'] as String? ?? '') ?? DateTime.now(),
        isMine: map['senderId'] == currentUserId,
        pending: false,
      );
      if (message.id.isNotEmpty) onMessage(message);
    });

    socket.connect();
  }

  void markRead(String conversationId) {
    _socket?.emit('conversation:read', conversationId);
  }

  void dispose() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    socket.clearListeners();
    socket.disconnect();
    socket.dispose();
  }
}
