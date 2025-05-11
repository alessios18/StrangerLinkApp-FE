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
  // Schema URL corretto per WebSocket: ws:// invece di http://
  final String wsUrl = 'http://192.168.2.101:8080/ws';
  final StorageService _storageService = StorageService();
  StompClient? _stompClient;
  bool _isConnecting = false;
  int _userId = 0;

  // Callbacks per gli eventi WebSocket
  Function(Message)? onMessageReceived;
  Function(Message)? onMessageStatusChanged;
  Function(int, bool)? onUserStatusChanged;
  Function()? onConnectionChanged;
  Function()? onNewConversation;
  Function(int, int, bool)? onTypingIndicator;

  bool get isConnected => _stompClient?.connected ?? false;

  // Connessione WebSocket con debug migliorato
  Future<void> connect(int userId) async {
    _userId = userId;

    if (isConnected) {
      print('【WebSocket】 Già connesso');
      return;
    }

    if (_isConnecting) {
      print('【WebSocket】 Connessione già in corso...');
      return;
    }

    _isConnecting = true;

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        print('【WebSocket】 ERRORE: Token di autenticazione non trovato');
        _isConnecting = false;
        return;
      }

      print('【WebSocket】 Tentativo di connessione a $wsUrl');

      // Configurazione standard per StompClient
      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: wsUrl,  // Endpoint WebSocket diretto
          onConnect: (StompFrame frame) {
            print('【WebSocket】 CONNESSO! Frame: ${frame.headers}');
            _isConnecting = false;

            // Sottoscrizione per messaggi personali
            print('【WebSocket】 Sottoscrizione a /user/$userId/queue/messages');
            _stompClient?.subscribe(
              destination: '/user/$userId/queue/messages',
              callback: (StompFrame frame) {
                print('【WebSocket】 RICEVUTO MESSAGGIO: ${frame.body}');
                if (frame.body != null) {
                  try {
                    final message = Message.fromJson(jsonDecode(frame.body!));
                    print('【WebSocket】 Messaggio decodificato: ${message.id}, ${message.content}');

                    if (onMessageReceived != null) {
                      print('【WebSocket】 Chiamata a onMessageReceived');
                      onMessageReceived!(message);
                    } else {
                      print('【WebSocket】 ERRORE: onMessageReceived è null!');
                    }
                  } catch (e) {
                    print('【WebSocket】 ERRORE nel parsing del messaggio: $e');
                    print('【WebSocket】 Corpo del messaggio: ${frame.body}');
                  }
                } else {
                  print('【WebSocket】 Frame ricevuto con body null');
                }
              },
            );

            // Sottoscrizione per aggiornamenti di stato dei messaggi
            print('【WebSocket】 Sottoscrizione a /user/$userId/queue/message-status');
            _stompClient?.subscribe(
              destination: '/user/$userId/queue/message-status',
              callback: (StompFrame frame) {
                print('【WebSocket】 RICEVUTO STATO MESSAGGIO: ${frame.body}');
                if (frame.body != null) {
                  try {
                    final message = Message.fromJson(jsonDecode(frame.body!));
                    if (onMessageStatusChanged != null) {
                      onMessageStatusChanged!(message);
                    }
                  } catch (e) {
                    print('【WebSocket】 ERRORE nel parsing dello stato messaggio: $e');
                  }
                }
              },
            );

            // Sottoscrizione per notifiche di stato utente
            print('【WebSocket】 Sottoscrizione a /user/$userId/queue/user-status');
            _stompClient?.subscribe(
              destination: '/user/$userId/queue/user-status',
              callback: (StompFrame frame) {
                print('【WebSocket】 RICEVUTO STATO UTENTE: ${frame.body}');
                if (frame.body != null) {
                  try {
                    final status = jsonDecode(frame.body!);
                    if (onUserStatusChanged != null && status['userId'] != null) {
                      onUserStatusChanged!(
                        status['userId'],
                        status['online'] ?? false,
                      );
                    }
                  } catch (e) {
                    print('【WebSocket】 ERRORE nel parsing dello stato utente: $e');
                  }
                }
              },
            );

            // Sottoscrizione per nuove conversazioni
            print('【WebSocket】 Sottoscrizione a /user/$userId/queue/new-conversation');
            _stompClient?.subscribe(
              destination: '/user/$userId/queue/new-conversation',
              callback: (StompFrame frame) {
                print('【WebSocket】 RICEVUTA NUOVA CONVERSAZIONE');
                if (onNewConversation != null) {
                  onNewConversation!();
                }
              },
            );

            // Sottoscrizione per indicatori di digitazione
            print('【WebSocket】 Sottoscrizione a /user/$userId/queue/typing');
            _stompClient?.subscribe(
              destination: '/user/$userId/queue/typing',
              callback: (StompFrame frame) {
                print('【WebSocket】 RICEVUTO INDICATORE DIGITAZIONE: ${frame.body}');
                if (frame.body != null) {
                  try {
                    final data = jsonDecode(frame.body!);
                    if (data['conversationId'] != null &&
                        data['userId'] != null &&
                        data.containsKey('typing')) {

                      if (onTypingIndicator != null) {
                        onTypingIndicator!(
                            data['conversationId'],
                            data['userId'],
                            data['typing'] ?? false
                        );
                      }
                    }
                  } catch (e) {
                    print('【WebSocket】 ERRORE nel parsing dell\'indicatore di digitazione: $e');
                  }
                }
              },
            );

            // Invia messaggio di presenza
            _sendUserPresence(userId);

            if (onConnectionChanged != null) {
              onConnectionChanged!();
            }
          },
          onDisconnect: (StompFrame frame) {
            print('【WebSocket】 DISCONNESSO. Frame: ${frame.headers}');
            _isConnecting = false;

            if (onConnectionChanged != null) {
              onConnectionChanged!();
            }

            // Riconnessione dopo 5 secondi
            _scheduleReconnect();
          },
          onStompError: (StompFrame frame) {
            print('【WebSocket】 ERRORE STOMP: ${frame.body}');
            _isConnecting = false;
            _scheduleReconnect();
          },
          onWebSocketError: (dynamic error) {
            print('【WebSocket】 ERRORE WebSocket: $error');
            _isConnecting = false;
            _scheduleReconnect();
          },
          // Intestazioni per autenticazione
          stompConnectHeaders: {
            'Authorization': 'Bearer $token',
          },
          webSocketConnectHeaders: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('【WebSocket】 Attivazione STOMP client...');
      _stompClient?.activate();
      print('【WebSocket】 STOMP client attivato');
    } catch (e) {
      print('【WebSocket】 ERRORE nell\'attivazione STOMP client: $e');
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_isConnecting && _userId > 0) {
      print('【WebSocket】 Programmazione riconnessione tra 5 secondi...');

      Future.delayed(const Duration(seconds: 5), () {
        if (!isConnected) {
          print('【WebSocket】 Tentativo di riconnessione...');
          connect(_userId);
        }
      });
    }
  }

  void disconnect() {
    try {
      print('【WebSocket】 Disconnessione STOMP client');
      _stompClient?.deactivate();
    } catch (e) {
      print('【WebSocket】 ERRORE durante la disconnessione: $e');
    }
  }

  // Invia heartbeat di presenza utente
  void _sendUserPresence(int userId) {
    if (_stompClient?.connected ?? false) {
      try {
        print('【WebSocket】 Invio heartbeat di presenza');
        _stompClient?.send(
          destination: '/app/chat.presence',
          body: jsonEncode({'userId': userId}),
        );
      } catch (e) {
        print('【WebSocket】 ERRORE nell\'invio dell\'heartbeat: $e');
      }

      // Programma prossimo heartbeat
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

  void sendDeliveryReceipt(int conversationId) {
    if (_stompClient?.connected ?? false) {
      try {
        _stompClient?.send(
          destination: '/app/chat.delivered',
          body: jsonEncode({
            'conversationId': conversationId,
          }),
        );
      } catch (e) {
        print('Failed to send delivery receipt: $e');
      }
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