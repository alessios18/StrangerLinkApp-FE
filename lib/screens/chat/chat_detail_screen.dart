import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stranger_link_app/blocs/auth/auth_bloc.dart';
import 'package:stranger_link_app/blocs/chat/chat_bloc.dart' as chat;
import 'package:stranger_link_app/blocs/chat_detail/chat_detail_bloc.dart';
import 'package:stranger_link_app/models/conversation.dart';
import 'package:stranger_link_app/models/message.dart';
import 'package:stranger_link_app/models/user.dart';
import 'package:stranger_link_app/repositories/chat_repository.dart';

class ChatDetailScreen extends StatelessWidget {
  final Conversation conversation;

  const ChatDetailScreen({Key? key, required this.conversation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatDetailBloc(
        chatBloc: context.read<chat.ChatBloc>(),
        chatRepository: context.read<ChatRepository>(),
      )..add(LoadChatMessages(
        conversationId: conversation.id,
        otherUserId: conversation.otherUser.id,
      )),
      child: _ChatDetailView(conversation: conversation),
    );
  }
}

class _ChatDetailView extends StatefulWidget {
  final Conversation conversation;

  const _ChatDetailView({Key? key, required this.conversation}) : super(key: key);

  @override
  _ChatDetailViewState createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<_ChatDetailView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  User? currentUser;
  bool _showScrollToBottom = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();

    // Get current user from auth bloc
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      currentUser = authState.user;
    }

    // Add scroll listener for pagination and scroll-to-bottom button
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
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
      final state = context.read<ChatDetailBloc>().state;
      if (state is ChatDetailLoaded && state.hasMoreMessages) {
        setState(() {
          _isLoadingMore = true;
        });

        context.read<ChatDetailBloc>().add(const LoadMoreChatMessages());

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
    if (currentUser == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty && _getSelectedImage() == null) return;

    final bloc = context.read<ChatDetailBloc>();
    final state = bloc.state;
    if (state is! ChatDetailLoaded) return;

    MessageType messageType = MessageType.TEXT;
    String content = text;

    if (_getSelectedImage() != null) {
      messageType = MessageType.IMAGE;
      content = text.isEmpty ? '[Image]' : text;
    }

    final message = Message(
      id: null, // Will be set by the server
      senderId: currentUser!.id,
      conversationId: state.conversationId,
      receiverId: widget.conversation.otherUser.id,
      content: content,
      timestamp: DateTime.now().toUtc(),
      type: messageType,
      status: MessageStatus.SENT,
    );

    // Clear input
    _messageController.clear();

    // Send message
    if (_getSelectedImage() != null) {
      bloc.add(SendMediaMessage(
        message: message,
        mediaFile: _getSelectedImage()!,
      ));
    } else {
      bloc.add(SendChatMessage(message));
    }
  }

  void _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      context.read<ChatDetailBloc>().add(SelectImage(File(pickedFile.path)));
    }
  }

  void _handleTyping(String text) {
    final isTyping = text.isNotEmpty;
    context.read<ChatDetailBloc>().add(UpdateTypingStatus(isTyping));
  }

  File? _getSelectedImage() {
    final state = context.read<ChatDetailBloc>().state;
    return state is ChatDetailLoaded ? state.selectedImage : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: BlocBuilder<ChatDetailBloc, ChatDetailState>(
        buildWhen: (previous, current) {
          if (previous is ChatDetailLoaded && current is ChatDetailLoaded) {
            return previous.isOtherUserTyping != current.isOtherUserTyping ||
                previous.isOtherUserOnline != current.isOtherUserOnline;
          }
          return false;
        },
        builder: (context, state) {
          return Row(
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
                  if (state is ChatDetailLoaded)
                    _buildStatusText(state),
                ],
              ),
            ],
          );
        },
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
    );
  }

  Widget _buildStatusText(ChatDetailLoaded state) {
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

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: BlocConsumer<ChatDetailBloc, ChatDetailState>(
            listenWhen: (previous, current) {
              return (current is ChatDetailLoaded &&
                  current.scrollToBottom) ||
                  current is ChatDetailError;
            },
            listener: (context, state) {
              if (state is ChatDetailLoaded && state.scrollToBottom) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
              } else if (state is ChatDetailError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              if (state is ChatDetailLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ChatDetailLoaded) {
                return _buildMessagesList(context, state);
              }

              return const Center(child: Text('Failed to load messages'));
            },
          ),
        ),

        // Image preview if selected
        BlocBuilder<ChatDetailBloc, ChatDetailState>(
          buildWhen: (previous, current) {
            if (previous is ChatDetailLoaded && current is ChatDetailLoaded) {
              return previous.selectedImage != current.selectedImage;
            }
            return false;
          },
          builder: (context, state) {
            if (state is ChatDetailLoaded && state.selectedImage != null) {
              return _buildImagePreview(context, state.selectedImage!);
            }
            return const SizedBox.shrink();
          },
        ),

        // Message input
        _buildMessageInput(context),
      ],
    );
  }

  Widget _buildMessagesList(BuildContext context, ChatDetailLoaded state) {
    final messages = state.messages;

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
  }

  Widget _buildImagePreview(BuildContext context, File image) {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              image,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Image selected'),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              context.read<ChatDetailBloc>().add(const ClearSelectedImage());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
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
                onTap: () => _showFullImage(context, message.mediaUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: message.mediaUrl!,
                    placeholder: (context, url) => const SizedBox(
                      height: 100,
                      width: 150,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => const SizedBox(
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
                    color: message.status == MessageStatus.READ
                        ? Colors.blue // Blue ticks for read
                        : message.status == MessageStatus.DELIVERED
                        ? Colors.white70 // White ticks for delivered
                        : Colors.white54, // Light white for sent
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
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
                imageUrl: imageUrl,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.SENT:
        return Icons.check; // Single check mark
      case MessageStatus.DELIVERED:
        return Icons.done_all; // Double check mark (outline)
      case MessageStatus.READ:
        return Icons.done_all; // Double check mark (filled)
      default:
        return Icons.access_time; // Clock icon for pending
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