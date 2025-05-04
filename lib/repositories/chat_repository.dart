// lib/repositories/chat_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/storage_service.dart';

class ChatRepository {
  final String baseUrl = 'http://192.168.2.101:8080/api';
  final String wsUrl = 'ws://192.168.2.101:8080/ws';
  final StorageService _storageService = StorageService();
  StompClient? _stompClient;

  // Callbacks for WebSocket events
  Function(Message)? onMessageReceived;
  Function(Message)? onMessageStatusChanged;
  Function(int, bool)? onUserStatusChanged;
  Function()? onConnectionChanged;

  bool get isConnected => _stompClient?.connected ?? false;

  // Connect to WebSocket
  Future<void> connect(int userId) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }
    final sockJsUrl = '$baseUrl/ws/info?t=';
    _stompClient = StompClient(
      config: StompConfig(
        url: sockJsUrl,
        onConnect: (StompFrame frame) {
          print('Connected to WebSocket');

          // Subscribe to personal queue for direct messages
          _stompClient?.subscribe(
            destination: '/user/$userId/queue/messages',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                final message = Message.fromJson(jsonDecode(frame.body!));
                if (onMessageReceived != null) {
                  onMessageReceived!(message);
                }
              }
            },
          );

          // Subscribe to message status updates
          _stompClient?.subscribe(
            destination: '/user/$userId/queue/message-status',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                final message = Message.fromJson(jsonDecode(frame.body!));
                if (onMessageStatusChanged != null) {
                  onMessageStatusChanged!(message);
                }
              }
            },
          );

          // Subscribe to user status updates
          _stompClient?.subscribe(
            destination: '/user/$userId/queue/user-status',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                final status = jsonDecode(frame.body!);
                if (onUserStatusChanged != null && status['userId'] != null) {
                  onUserStatusChanged!(
                    status['userId'],
                    status['online'] ?? false,
                  );
                }
              }
            },
          );

          // Subscribe to typing indicator
          _stompClient?.subscribe(
            destination: '/user/$userId/queue/typing',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                final data = jsonDecode(frame.body!);
                if (onUserStatusChanged != null &&
                    data['userId'] != null &&
                    data['conversationId'] != null) {
                  // Handle typing indicator (implementation specific)
                  print('User ${data['userId']} is typing: ${data['typing']}');
                }
              }
            },
          );

          // Send presence message
          _sendUserPresence(userId);

          if (onConnectionChanged != null) {
            onConnectionChanged!();
          }
        },
        onDisconnect: (StompFrame frame) {
          print('Disconnected from WebSocket');
          if (onConnectionChanged != null) {
            onConnectionChanged!();
          }
        },
        onWebSocketError: (dynamic error) {
          print('Error connecting to WebSocket: $error');
        },
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    _stompClient?.activate();
  }

  void disconnect() {
    _stompClient?.deactivate();
  }

  // Send user presence heartbeat
  void _sendUserPresence(int userId) {
    if (_stompClient?.connected ?? false) {
      _stompClient?.send(
        destination: '/app/chat.presence',
        body: jsonEncode({'userId': userId}),
      );

      // Schedule next heartbeat
      Future.delayed(const Duration(seconds: 30), () {
        if (_stompClient?.connected ?? false) {
          _sendUserPresence(userId);
        }
      });
    }
  }

  Future<List<Conversation>> getConversations() async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load conversations: $e');
    }
  }

  Future<List<Message>> getMessages(int conversationId, {int page = 0, int size = 20}) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversations/$conversationId/messages?page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  Future<Message> sendMessage(Message message) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    // First try to send via WebSocket if connected
    if (_stompClient?.connected ?? false) {
      _stompClient?.send(
        destination: '/app/chat.send',
        body: jsonEncode(message.toJson()),
      );

      // Return the original message for immediate UI update
      // The actual saved message will come through the WebSocket subscription
      return message;
    }

    // Fallback to REST API if WebSocket is not connected
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/send/${message.receiverId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(message.toJson()),
      );

      if (response.statusCode == 200) {
        return Message.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to send message: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<Message> sendMediaMessage(Message message, File mediaFile) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      // Create multipart request
      final uri = Uri.parse('$baseUrl/chat/media/${message.receiverId}');
      final request = http.MultipartRequest('POST', uri);

      // Add file
      final fileStream = http.ByteStream(mediaFile.openRead());
      final fileLength = await mediaFile.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: mediaFile.path.split('/').last,
      );

      request.files.add(multipartFile);

      // Add message data as fields
      request.fields['content'] = message.content;
      request.fields['conversationId'] = message.conversationId.toString();
      request.fields['type'] = message.type.toString().split('.').last;

      // Add authorization
      request.headers['Authorization'] = 'Bearer $token';

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return Message.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to send media: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to send media: $e');
    }
  }

  Future<void> markMessagesAsRead(int conversationId) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/conversations/$conversationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  Future<void> setTypingStatus(int conversationId, int receiverId, bool isTyping) async {
    if (!(_stompClient?.connected ?? false)) {
      return; // Silently fail if not connected
    }

    try {
      _stompClient?.send(
        destination: '/app/chat.typing',
        body: jsonEncode({
          'conversationId': conversationId,
          'receiverId': receiverId,
          'typing': isTyping,
        }),
      );
    } catch (e) {
      print('Failed to send typing status: $e');
    }
  }
}