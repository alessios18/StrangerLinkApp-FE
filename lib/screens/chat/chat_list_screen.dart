import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stranger_link_app/blocs/chat/chat_bloc.dart';
import 'package:stranger_link_app/blocs/conversation_list/conversation_list_bloc.dart';
import 'package:stranger_link_app/models/conversation.dart';
import 'package:stranger_link_app/screens/chat/chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConversationListBloc(
        chatBloc: context.read<ChatBloc>(),
      )..add(LoadConversationList()),
      child: const ChatListView(),
    );
  }
}

class ChatListView extends StatelessWidget {
  const ChatListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Chats'),
      actions: [
        // Search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(context),
        ),
        // Filter menu
        PopupMenuButton<ConversationFilter>(
          icon: const Icon(Icons.filter_list),
          onSelected: (filter) {
            context.read<ConversationListBloc>()
                .add(FilterConversations(filter));
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: ConversationFilter.all,
              child: Text('All Chats'),
            ),
            const PopupMenuItem(
              value: ConversationFilter.unread,
              child: Text('Unread'),
            ),
            const PopupMenuItem(
              value: ConversationFilter.online,
              child: Text('Online Users'),
            ),
          ],
        ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<ConversationListBloc>()
                .add(RefreshConversationList());
          },
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<ConversationListBloc, ConversationListState>(
      builder: (context, state) {
        if (state is ConversationListLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ConversationListError) {
          return _buildErrorState(context, state);
        }

        final conversations = state is ConversationListLoaded
            ? state.filteredConversations : [];

        if (conversations.isEmpty) {
          return _buildEmptyState(context, state);
        }

        return _buildConversationList(context, conversations as List<Conversation>, state);
      },
    );
  }

  Widget _buildErrorState(BuildContext context, ConversationListError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading conversations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(state.message),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ConversationListBloc>().add(RefreshConversationList());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ConversationListState state) {
    // Show different empty states based on filter
    String message = 'No conversations yet';
    String submessage = 'Search for users to start chatting';

    if (state is ConversationListLoaded) {
      if (state.filter == ConversationFilter.unread) {
        message = 'No unread messages';
        submessage = 'All caught up!';
      } else if (state.filter == ConversationFilter.online) {
        message = 'No online users';
        submessage = 'Try again later or search for new users';
      } else if (state.searchQuery.isNotEmpty) {
        message = 'No matching conversations';
        submessage = 'Try a different search term';
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            submessage,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
            icon: const Icon(Icons.search),
            label: const Text('Find People'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(
      BuildContext context,
      List<Conversation> conversations,
      ConversationListState state,
      ) {
    // Show search query if filtering
    Widget? header;
    if (state is ConversationListLoaded && state.searchQuery.isNotEmpty) {
      header = Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.search, size: 16),
            const SizedBox(width: 8),
            Text('Search: "${state.searchQuery}"'),
            const Spacer(),
            GestureDetector(
              onTap: () {
                context.read<ConversationListBloc>().add(const SearchConversations(''));
              },
              child: const Icon(Icons.close, size: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ConversationListBloc>().add(RefreshConversationList());
        // Wait for the refresh to complete
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: Column(
        children: [
          if (header != null) header,
          Expanded(
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _buildConversationTile(context, conversation);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, Conversation conversation) {
    final otherUser = conversation.otherUser;
    final lastMessageTime = conversation.lastMessageTimestamp != null
        ? _formatTime(conversation.lastMessageTimestamp!)
        : '';

    return Dismissible(
      key: Key('conversation_${conversation.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm'),
              content: const Text('Are you sure you want to delete this conversation?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        context.read<ConversationListBloc>().add(DeleteConversation(conversation.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation deleted')),
        );
      },
      child: ListTile(
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
            if (conversation.isOnline == true)
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
          style: TextStyle(
            fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: conversation.lastMessage != null
            ? Text(
          conversation.lastMessage!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
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
          // Mark conversation as read
          if (conversation.unreadCount > 0) {
            context.read<ConversationListBloc>().add(MarkConversationAsRead(conversation.id));
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(conversation: conversation),
            ),
          ).then((_) {
            // Refresh the conversation list when returning from chat detail
            context.read<ConversationListBloc>().add(RefreshConversationList());
          });
        },
        onLongPress: () => _showConversationOptions(context, conversation),
      ),
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

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Conversations'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Enter username to search',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            context.read<ConversationListBloc>().add(SearchConversations(value));
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ConversationListBloc>().add(SearchConversations(searchController.text));
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showConversationOptions(BuildContext context, Conversation conversation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: conversation.otherUser.profileImageUrl != null
                    ? CachedNetworkImageProvider(conversation.otherUser.profileImageUrl!)
                    : null,
                child: conversation.otherUser.profileImageUrl == null
                    ? Text(conversation.otherUser.username.substring(0, 1).toUpperCase())
                    : null,
              ),
              title: Text(conversation.otherUser.username),
              subtitle: Text(conversation.isOnline == true ? 'Online' : 'Offline'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/profile/view',
                  arguments: conversation.otherUser.id,
                );
              },
            ),
            if (conversation.unreadCount > 0)
              ListTile(
                leading: const Icon(Icons.mark_chat_read),
                title: const Text('Mark as Read'),
                onTap: () {
                  Navigator.pop(context);
                  context.read<ConversationListBloc>().add(MarkConversationAsRead(conversation.id));
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Conversation', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteConversation(context, conversation.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteConversation(BuildContext context, int conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.read<ConversationListBloc>().add(DeleteConversation(conversationId));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}