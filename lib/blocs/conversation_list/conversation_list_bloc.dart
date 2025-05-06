import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stranger_link_app/blocs/chat/chat_bloc.dart';
import 'package:stranger_link_app/models/conversation.dart';

part 'conversation_list_event.dart';
part 'conversation_list_state.dart';

class ConversationListBloc extends Bloc<ConversationListEvent, ConversationListState> {
  final ChatBloc chatBloc;
  late StreamSubscription chatBlocSubscription;

  ConversationListBloc({required this.chatBloc}) : super(ConversationListInitial()) {
    on<LoadConversationList>(_onLoadConversationList);
    on<RefreshConversationList>(_onRefreshConversationList);
    on<SearchConversations>(_onSearchConversations);
    on<FilterConversations>(_onFilterConversations);
    on<ConversationReceived>(_onConversationReceived);
    on<DeleteConversation>(_onDeleteConversation);
    on<MarkConversationAsRead>(_onMarkConversationAsRead);

    // Listen to ChatBloc updates
    chatBlocSubscription = chatBloc.stream.listen((state) {
      if (state is ChatConversationsLoaded) {
        add(ConversationReceived(state.conversations));
      }
    });
  }

  Future<void> _onLoadConversationList(
      LoadConversationList event,
      Emitter<ConversationListState> emit
      ) async {
    emit(ConversationListLoading());
    chatBloc.add(LoadConversations());
  }

  Future<void> _onRefreshConversationList(
      RefreshConversationList event,
      Emitter<ConversationListState> emit
      ) async {
    final currentState = state;
    if (currentState is ConversationListLoaded) {
      emit(ConversationListLoading());
    }
    chatBloc.add(LoadConversations());
  }

  Future<void> _onSearchConversations(
      SearchConversations event,
      Emitter<ConversationListState> emit
      ) async {
    final currentState = state;
    if (currentState is ConversationListLoaded) {
      // Filter conversations based on search query
      final filteredConversations = _filterConversations(
        currentState.conversations,
        searchQuery: event.query,
        filter: currentState.filter,
      );

      emit(currentState.copyWith(
        filteredConversations: filteredConversations,
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _onFilterConversations(
      FilterConversations event,
      Emitter<ConversationListState> emit
      ) async {
    final currentState = state;
    if (currentState is ConversationListLoaded) {
      // Filter conversations based on filter type
      final filteredConversations = _filterConversations(
        currentState.conversations,
        searchQuery: currentState.searchQuery,
        filter: event.filter,
      );

      emit(currentState.copyWith(
        filteredConversations: filteredConversations,
        filter: event.filter,
      ));
    }
  }

  Future<void> _onConversationReceived(
      ConversationReceived event,
      Emitter<ConversationListState> emit
      ) async {
    final conversations = event.conversations;

    final currentState = state;
    if (currentState is ConversationListLoaded) {
      // Apply existing filters to the new conversations
      final filteredConversations = _filterConversations(
        conversations,
        searchQuery: currentState.searchQuery,
        filter: currentState.filter,
      );

      emit(currentState.copyWith(
        conversations: conversations,
        filteredConversations: filteredConversations,
      ));
    } else {
      // First load
      emit(ConversationListLoaded(
        conversations: conversations,
        filteredConversations: conversations,
      ));
    }
  }

  Future<void> _onDeleteConversation(
      DeleteConversation event,
      Emitter<ConversationListState> emit
      ) async {
    // This would typically call a method in the repository to delete the conversation
    // For now, we'll just filter it out locally

    final currentState = state;
    if (currentState is ConversationListLoaded) {
      final updatedConversations = currentState.conversations
          .where((conversation) => conversation.id != event.conversationId)
          .toList();

      final filteredConversations = _filterConversations(
        updatedConversations,
        searchQuery: currentState.searchQuery,
        filter: currentState.filter,
      );

      emit(currentState.copyWith(
        conversations: updatedConversations,
        filteredConversations: filteredConversations,
      ));

      // In a real implementation, you would call the repository to delete
      // chatBloc.add(DeleteConversationRequested(event.conversationId));
    }
  }

  Future<void> _onMarkConversationAsRead(
      MarkConversationAsRead event,
      Emitter<ConversationListState> emit
      ) async {
    // Mark conversation as read in the chat bloc
    chatBloc.add(MarkMessagesAsRead(event.conversationId));

    // Update locally until the subscription updates
    final currentState = state;
    if (currentState is ConversationListLoaded) {
      final updatedConversations = currentState.conversations.map((conversation) {
        if (conversation.id == event.conversationId) {
          return conversation.copyWith(unreadCount: 0);
        }
        return conversation;
      }).toList();

      final filteredConversations = _filterConversations(
        updatedConversations,
        searchQuery: currentState.searchQuery,
        filter: currentState.filter,
      );

      emit(currentState.copyWith(
        conversations: updatedConversations,
        filteredConversations: filteredConversations,
      ));
    }
  }

  // Helper method to filter conversations
  List<Conversation> _filterConversations(
      List<Conversation> conversations, {
        required String searchQuery,
        required ConversationFilter filter,
      }) {
    var filtered = List<Conversation>.from(conversations);

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((conversation) {
        return conversation.otherUser.username
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Apply type filter
    switch (filter) {
      case ConversationFilter.unread:
        filtered = filtered.where((conversation) => conversation.unreadCount > 0).toList();
        break;
      case ConversationFilter.online:
        filtered = filtered.where((conversation) => conversation.isOnline ?? false).toList();
        break;
      case ConversationFilter.all:
      default:
      // No additional filtering
        break;
    }

    return filtered;
  }

  @override
  Future<void> close() {
    chatBlocSubscription.cancel();
    return super.close();
  }
}