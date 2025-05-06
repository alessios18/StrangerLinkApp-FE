// lib/screens/chat/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:stranger_link_app/blocs/chat/chat_bloc.dart';
import 'package:stranger_link_app/models/conversation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stranger_link_app/screens/chat/chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    // Load conversations when screen opens
    context.read<ChatBloc>().add(LoadConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChatBloc>().add(LoadConversations());
            },
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading && state.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChatError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ChatBloc>().add(LoadConversations());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final conversations = state is ChatConversationsLoaded
              ? state.conversations
              : state is ChatLoading ? state.conversations : [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Search for users to start chatting',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigation is now handled by the bottom nav bar
                      // So we don't need to navigate here
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Find People'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ChatBloc>().add(LoadConversations());
              // Wait for a bit to show the refresh indicator
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _buildConversationTile(context, conversation);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, Conversation conversation) {
    final otherUser = conversation.otherUser;
    final lastMessageTime = conversation.lastMessageTimestamp != null
        ? _formatTime(conversation.lastMessageTimestamp!)
        : '';

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: otherUser.profileImageUrl != null
                ? CachedNetworkImageProvider(otherUser.profileImageUrl!)
                : null,
            child: otherUser.profileImageUrl == null
                ? Text(otherUser.username.substring(0, 1).toUpperCase())
                : null,
          ),
          if (conversation.isOnline != null && conversation.isOnline!)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        otherUser.username,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: conversation.lastMessage != null
          ? Text(
        conversation.lastMessage!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      )
          : const Text(
        'No messages yet',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            lastMessageTime,
            style: TextStyle(
              fontSize: 12,
              color: conversation.unreadCount > 0
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(conversation: conversation),
          ),
        ).then((_) {
          // Refresh the conversation list when returning from chat detail
          context.read<ChatBloc>().add(LoadConversations());
        });
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat.Hm().format(time); // HH:mm
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat.E().format(time); // Day of week
    } else {
      return DateFormat.yMd().format(time); // MM/dd/yyyy
    }
  }
}