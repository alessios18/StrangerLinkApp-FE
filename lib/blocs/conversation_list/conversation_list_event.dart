part of 'conversation_list_bloc.dart';

abstract class ConversationListEvent extends Equatable {
  const ConversationListEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversationList extends ConversationListEvent {}

class RefreshConversationList extends ConversationListEvent {}

class SearchConversations extends ConversationListEvent {
  final String query;

  const SearchConversations(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterConversations extends ConversationListEvent {
  final ConversationFilter filter;

  const FilterConversations(this.filter);

  @override
  List<Object?> get props => [filter];
}

class ConversationReceived extends ConversationListEvent {
  final List<Conversation> conversations;

  const ConversationReceived(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class DeleteConversation extends ConversationListEvent {
  final int conversationId;

  const DeleteConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class MarkConversationAsRead extends ConversationListEvent {
  final int conversationId;

  const MarkConversationAsRead(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}