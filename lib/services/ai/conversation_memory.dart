class ConversationMessage {
  final String role;
  final String content;

  const ConversationMessage({
    required this.role,
    required this.content,
  });
}

class ConversationMemory {
  final List<ConversationMessage> _messages = [];

  List<ConversationMessage> get messages =>
      List.unmodifiable(_messages);

  void addUser(String text) {
    _messages.add(
      ConversationMessage(
        role: 'user',
        content: text,
      ),
    );
  }

  void addAssistant(String text) {
    _messages.add(
      ConversationMessage(
        role: 'assistant',
        content: text,
      ),
    );
  }

  void clear() {
    _messages.clear();
  }
}