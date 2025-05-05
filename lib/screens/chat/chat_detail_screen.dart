// lib/screens/chat/chat_detail_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stranger_link_app/blocs/auth/auth_bloc.dart';
import 'package:stranger_link_app/blocs/chat/chat_bloc.dart';
import 'package:stranger_link_app/models/conversation.dart';
import 'package:stranger_link_app/models/message.dart';
import 'package:stranger_link_app/models/user.dart';

class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailScreen({Key? key, required this.conversation}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTyping = false;
  File? _selectedImage;
  User? currentUser;
  late int conversationId;
  bool _showScrollToBottom = false;
  bool _isLoadingMore = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    conversationId = widget.conversation.id;

    // Get current user from auth bloc
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      currentUser = authState.user;
    }

    // Load initial messages
    context.read<ChatBloc>().add(LoadMessages(conversationId));

    // Mark conversation as read
    context.read<ChatBloc>().add(MarkMessagesAsRead(conversationId));

    // Add scroll listener for pagination and scroll-to-bottom button
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    // Show scroll-to-bottom button when not at bottom
    setState(() {
      _showScrollToBottom = _scrollController.position.pixels <
          _scrollController.position.maxScrollExtent - 300;
    });

    // Load more messages when scrolled to top
    if (_scrollController.position.pixels <= 0 && !_isLoadingMore) {
      final state = context.read<ChatBloc>().state;
      if (state is ChatMessagesLoaded && state.hasMoreMessages) {
        setState(() {
          _isLoadingMore = true;
        });

        context.read<ChatBloc>().add(LoadMoreMessages(conversationId));

        // Reset flag after a delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if ((text.isEmpty && _selectedImage == null) || currentUser == null) return;

    MessageType messageType = MessageType.TEXT;
    String content = text;

    if (_selectedImage != null) {
      messageType = MessageType.IMAGE;
      content = text.isEmpty ? '[Image]' : text;
    }

    final message = Message(
      id: null, // Will be set by the server
      senderId: currentUser!.id,
      conversationId: conversationId,
      receiverId: widget.conversation.otherUser.id,
      content: content,
      timestamp: DateTime.now().toUtc(),
      type: messageType,
      status: MessageStatus.SENT,
    );

    // Clear input
    _messageController.clear();
    setState(() {
      _selectedImage = null;
      _isTyping = false;
    });

    // Send message
    if (_selectedImage != null) {
      context.read<ChatBloc>().add(SendMediaMessage(message, _selectedImage!));
    } else {
      context.read<ChatBloc>().add(SendTextMessage(message));
    }

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _handleTyping(String text) {
    bool isCurrentlyTyping = text.isNotEmpty;

    // Only send typing indicator when state changes
    if (isCurrentlyTyping != _isTyping) {
      setState(() {
        _isTyping = isCurrentlyTyping;
      });

      context.read<ChatBloc>().add(
          SetTypingStatus(conversationId, widget.conversation.otherUser.id, isCurrentlyTyping)
      );
    }

    // Reset typing indicator after 3 seconds of inactivity
    _typingTimer?.cancel();
    if (isCurrentlyTyping) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _isTyping) {
          setState(() {
            _isTyping = false;
          });
          context.read<ChatBloc>().add(
              SetTypingStatus(conversationId, widget.conversation.otherUser.id, false)
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.conversation.otherUser.profileImageUrl != null
                  ? CachedNetworkImageProvider(widget.conversation.otherUser.profileImageUrl!)
                  : null,
              child: widget.conversation.otherUser.profileImageUrl == null
                  ? Text(widget.conversation.otherUser.username.substring(0, 1).toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.otherUser.username,
                  style: const TextStyle(fontSize: 16),
                ),
                BlocBuilder<ChatBloc, ChatState>(
                  buildWhen: (previous, current) {
                    // Only rebuild for typing status or online status changes
                    return (previous is ChatMessagesLoaded && current is ChatMessagesLoaded) &&
                        (previous.isOtherUserTyping != current.isOtherUserTyping ||
                            previous.isOtherUserOnline != current.isOtherUserOnline);
                  },
                  builder: (context, state) {
                    if (state is ChatMessagesLoaded) {
                      if (state.isOtherUserTyping) {
                        return const Text(
                          'Typing...',
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        );
                      } else if (state.isOtherUserOnline) {
                        return const Text(
                          'Online',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        );
                      } else {
                        return const Text(
                          'Offline',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show user profile
              Navigator.pushNamed(
                context,
                '/profile/view',
                arguments: widget.conversation.otherUser.id,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listenWhen: (previous, current) {
                return current is ChatMessageSent ||
                    (current is ChatMessagesLoaded &&
                        previous is! ChatMessagesLoaded);
              },
              listener: (context, state) {
                if (state is ChatMessageSent ||
                    (state is ChatMessagesLoaded && state.scrollToBottom)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
              },
              builder: (context, state) {
                if (state is ChatLoading && state.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = state is ChatMessagesLoaded
                    ? state.messages
                    : state is ChatLoading ? state.messages : [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nStart the conversation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    // Loading indicator at top for pagination
                    if (_isLoadingMore)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          color: Theme.of(context).colorScheme.primary,
                          minHeight: 2,
                        ),
                      ),

                    // Messages list
                    ListView.builder(
                      controller: _scrollController,
                      reverse: true, // Latest messages at bottom
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isFromMe = message.senderId == currentUser?.id;

                        // Group messages by date
                        final showDate = index == messages.length - 1 ||
                            !_isSameDay(messages[index].timestamp, messages[index + 1].timestamp);

                        return Column(
                          children: [
                            if (showDate)
                              _buildDateSeparator(message.timestamp.toLocal()),
                            _buildMessageBubble(message, isFromMe),
                          ],
                        );
                      },
                    ),

                    // Scroll to bottom button
                    if (_showScrollToBottom)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.small(
                          onPressed: _scrollToBottom,
                          child: const Icon(Icons.arrow_downward),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Image preview if selected
          if (_selectedImage != null)
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.grey[200],
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text('Image selected'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onChanged: _handleTyping,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          const SizedBox(width: 8),
          Text(
            _formatDateSeparator(timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isFromMe) {
    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isFromMe
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isFromMe ? const Radius.circular(4) : null,
            bottomLeft: !isFromMe ? const Radius.circular(4) : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image message
            if (message.type == MessageType.IMAGE && message.mediaUrl != null)
              GestureDetector(
                onTap: () {
                  // Show full image
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: Colors.black,
                          iconTheme: const IconThemeData(color: Colors.white),
                        ),
                        backgroundColor: Colors.black,
                        body: Center(
                          child: InteractiveViewer(
                            child: CachedNetworkImage(
                              imageUrl: message.mediaUrl!,
                              placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: message.mediaUrl!,
                    placeholder: (context, url) =>
                    const SizedBox(
                      height: 100,
                      width: 150,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) =>
                    const SizedBox(
                      height: 100,
                      width: 150,
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
              ),

            // Text content
            if (message.content.isNotEmpty &&
                !(message.type == MessageType.IMAGE && message.content == '[Image]'))
              Text(
                message.content,
                style: TextStyle(
                  color: isFromMe ? Colors.white : null,
                ),
              ),

            // Time and status
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  DateFormat.Hm().format(message.timestamp.toLocal()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isFromMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                if (isFromMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _getStatusIcon(message.status),
                    size: 12,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.SENT:
        return Icons.check;
      case MessageStatus.DELIVERED:
        return Icons.done_all;
      case MessageStatus.READ:
        return Icons.done_all;
      default:
        return Icons.access_time;
    }
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat.EEEE().format(date); // Full day name
    } else {
      return DateFormat.yMMMd().format(date); // Jan 21, 2023
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}