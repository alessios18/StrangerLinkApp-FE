// lib/screens/search/user_search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stranger_link_app/blocs/auth/auth_bloc.dart';
import 'package:stranger_link_app/blocs/chat/chat_bloc.dart';
import 'package:stranger_link_app/models/conversation.dart';
import 'package:stranger_link_app/models/user.dart';
import 'package:stranger_link_app/repositories/user_repository.dart';
import 'package:stranger_link_app/screens/chat/chat_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserRepository _userRepository = UserRepository();

  // For random match tab
  List<User> _randomUsers = [];
  bool _isLoadingRandom = false;
  String _randomError = '';

  // For recent tab
  List<User> _recentUsers = [];
  bool _isLoadingRecent = false;
  String _recentError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load data for both tabs
    _loadRandomMatches();
    _loadRecentUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRandomMatches() async {
    setState(() {
      _isLoadingRandom = true;
      _randomError = '';
    });

    try {
      final users = await _userRepository.searchUsers(usePreferences: true);
      setState(() {
        _randomUsers = users;
        _isLoadingRandom = false;
      });
    } catch (e) {
      setState(() {
        _randomError = 'Failed to load matches: $e';
        _isLoadingRandom = false;
      });
    }
  }

  Future<void> _loadRecentUsers() async {
    setState(() {
      _isLoadingRecent = true;
      _recentError = '';
    });

    try {
      final users = await _userRepository.getRecentlyActiveUsers();
      setState(() {
        _recentUsers = users;
        _isLoadingRecent = false;
      });
    } catch (e) {
      setState(() {
        _recentError = 'Failed to load recent users: $e';
        _isLoadingRecent = false;
      });
    }
  }

  void _startChat(User user) {
    // In a real app, you'd create or get an existing conversation
    // For now we'll create a dummy conversation
    final conversation = Conversation(
      id: 0, // The server will create a real ID
      otherUser: user,
      unreadCount: 0,
      isOnline: true,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(conversation: conversation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find People'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.shuffle),
              text: 'Random Matches',
            ),
            Tab(
              icon: Icon(Icons.access_time),
              text: 'Recently Active',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Random matches tab
          RefreshIndicator(
            onRefresh: _loadRandomMatches,
            child: _buildUserList(
              _randomUsers,
              _isLoadingRandom,
              _randomError,
              'No matches found based on your preferences.\nTry adjusting your search preferences.',
            ),
          ),

          // Recent users tab
          RefreshIndicator(
            onRefresh: _loadRecentUsers,
            child: _buildUserList(
              _recentUsers,
              _isLoadingRecent,
              _recentError,
              'No users have been active recently.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
      List<User> users,
      bool isLoading,
      String error,
      String emptyMessage,
      ) {
    if (isLoading && users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_tabController.index == 0) {
                  _loadRandomMatches();
                } else {
                  _loadRecentUsers();
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            if (_tabController.index == 0)
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                child: const Text('Edit Preferences'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];

        // Calculate how recently the user was active
        final lastActive = DateTime.now().difference(user.lastActive);
        String lastActiveText;

        if (lastActive.inMinutes < 1) {
          lastActiveText = 'Just now';
        } else if (lastActive.inHours < 1) {
          lastActiveText = '${lastActive.inMinutes}m ago';
        } else if (lastActive.inDays < 1) {
          lastActiveText = '${lastActive.inHours}h ago';
        } else {
          lastActiveText = '${lastActive.inDays}d ago';
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user.username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
            title: Text(
              user.username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Active: $lastActiveText'),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => _startChat(user),
                  child: const Text('Start Chat'),
                ),
              ],
            ),
            onTap: () => _startChat(user),
          ),
        );
      },
    );
  }
}