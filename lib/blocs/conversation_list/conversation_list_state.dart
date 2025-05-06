part of 'conversation_list_bloc.dart';

enum ConversationFilter { all, unread, online }

abstract class ConversationListState extends Equatable {
  const ConversationListState();

  @override
  List<Object?> get props => [];
}

class ConversationListInitial extends ConversationListState {}

class ConversationListLoading extends ConversationListState {}

class ConversationListLoaded extends ConversationListState {
  final List<Conversation> conversations;
  final List<Conversation> filteredConversations;
  final String searchQuery;
  final ConversationFilter filter;

  const ConversationListLoaded({
    required this.conversations,
    required this.filteredConversations,
    this.searchQuery = '',
    this.filter = ConversationFilter.all,
  });

  ConversationListLoaded copyWith({
    List<Conversation>? conversations,
    List<Conversation>? filteredConversations,
    String? searchQuery,
    ConversationFilter? filter,
  }) {
    return ConversationListLoaded(
      conversations: conversations ?? this.conversations,
      filteredConversations: filteredConversations ?? this.filteredConversations,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [conversations, filteredConversations, searchQuery, filter];
}

class ConversationListError extends ConversationListState {
  final String message;

  const ConversationListError(this.message);

  @override
  List<Object?> get props => [message];
}