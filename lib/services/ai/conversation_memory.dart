/// Lightweight in-memory conversation store for MyFin AI.
///
/// This service intentionally has no external package dependency so it can be
/// used safely from UI, services, tests, and future persistence layers.
class ConversationMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  const ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isSystem => role == ConversationRole.system;
  bool get isUser => role == ConversationRole.user;
  bool get isAssistant => role == ConversationRole.assistant;

  ConversationMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? createdAt,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    final String role = (json['role'] as String?)?.trim() ?? '';
    final String content = (json['content'] as String?)?.trim() ?? '';
    final String id = (json['id'] as String?)?.trim().isNotEmpty == true
        ? (json['id'] as String).trim()
        : ConversationMemory.generateMessageId();

    final String? createdAtText = json['createdAt'] as String?;
    final DateTime createdAt = createdAtText == null
        ? DateTime.now()
        : DateTime.tryParse(createdAtText) ?? DateTime.now();

    return ConversationMessage(
      id: id,
      role: ConversationRole.normalize(role),
      content: content,
      createdAt: createdAt,
    );
  }
}

class ConversationRole {
  static const String system = 'system';
  static const String user = 'user';
  static const String assistant = 'assistant';

  static const Set<String> values = <String>{
    system,
    user,
    assistant,
  };

  static String normalize(String role) {
    final String normalized = role.trim().toLowerCase();
    if (values.contains(normalized)) return normalized;
    return user;
  }
}

class ConversationMemory {
  ConversationMemory({
    int maxMessages = 50,
    String? systemPrompt,
    List<ConversationMessage>? initialMessages,
  }) : _maxMessages = maxMessages < 1 ? 1 : maxMessages {
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      addSystem(systemPrompt);
    }

    if (initialMessages != null && initialMessages.isNotEmpty) {
      _messages.addAll(initialMessages.where((ConversationMessage message) {
        return message.content.trim().isNotEmpty;
      }));
      _trimToLimit();
    }
  }

  final List<ConversationMessage> _messages = <ConversationMessage>[];
  final int _maxMessages;

  int get maxMessages => _maxMessages;

  bool get isEmpty => _messages.isEmpty;
  bool get isNotEmpty => _messages.isNotEmpty;
  int get length => _messages.length;

  List<ConversationMessage> get messages =>
      List<ConversationMessage>.unmodifiable(_messages);

  ConversationMessage? get latest =>
      _messages.isEmpty ? null : _messages.last;

  ConversationMessage? get latestUserMessage {
    for (final ConversationMessage message in _messages.reversed) {
      if (message.isUser) return message;
    }
    return null;
  }

  ConversationMessage? get latestAssistantMessage {
    for (final ConversationMessage message in _messages.reversed) {
      if (message.isAssistant) return message;
    }
    return null;
  }

  void addSystem(String text) {
    _add(ConversationRole.system, text);
  }

  void addUser(String text) {
    _add(ConversationRole.user, text);
  }

  void addAssistant(String text) {
    _add(ConversationRole.assistant, text);
  }

  void addMessage(ConversationMessage message) {
    final String content = message.content.trim();
    if (content.isEmpty) return;

    _messages.add(
      message.copyWith(
        role: ConversationRole.normalize(message.role),
        content: content,
      ),
    );
    _trimToLimit();
  }

  List<ConversationMessage> lastMessages(int count) {
    if (count <= 0 || _messages.isEmpty) {
      return <ConversationMessage>[];
    }

    if (count >= _messages.length) {
      return messages;
    }

    return List<ConversationMessage>.unmodifiable(
      _messages.sublist(_messages.length - count),
    );
  }

  List<ConversationMessage> messagesByRole(String role) {
    final String normalizedRole = ConversationRole.normalize(role);
    return List<ConversationMessage>.unmodifiable(
      _messages.where((ConversationMessage message) {
        return message.role == normalizedRole;
      }),
    );
  }

  /// Converts memory into a compact history block that can be injected into an
  /// AI prompt. System messages are kept, but callers may exclude them when the
  /// model provider already has a separate system prompt field.
  String buildPromptHistory({
    int? limit,
    bool includeSystemMessages = true,
  }) {
    final Iterable<ConversationMessage> source = limit == null
        ? _messages
        : lastMessages(limit);

    final Iterable<ConversationMessage> filtered = source.where(
      (ConversationMessage message) {
        if (!includeSystemMessages && message.isSystem) return false;
        return message.content.trim().isNotEmpty;
      },
    );

    return filtered.map((ConversationMessage message) {
      final String label = _labelForRole(message.role);
      return '$label: ${message.content.trim()}';
    }).join('\n');
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'maxMessages': _maxMessages,
      'messages': _messages
          .map((ConversationMessage message) => message.toJson())
          .toList(),
    };
  }

  factory ConversationMemory.fromJson(Map<String, dynamic> json) {
    final int maxMessages = json['maxMessages'] is int
        ? json['maxMessages'] as int
        : 50;

    final List<dynamic> rawMessages = json['messages'] is List<dynamic>
        ? json['messages'] as List<dynamic>
        : <dynamic>[];

    final List<ConversationMessage> parsedMessages = rawMessages
        .whereType<Map<String, dynamic>>()
        .map(ConversationMessage.fromJson)
        .where((ConversationMessage message) => message.content.isNotEmpty)
        .toList();

    return ConversationMemory(
      maxMessages: maxMessages,
      initialMessages: parsedMessages,
    );
  }

  void removeById(String id) {
    _messages.removeWhere((ConversationMessage message) => message.id == id);
  }

  void clear({bool keepSystemMessages = false}) {
    if (!keepSystemMessages) {
      _messages.clear();
      return;
    }

    _messages.removeWhere((ConversationMessage message) => !message.isSystem);
  }

  static String generateMessageId() {
    return 'msg_${DateTime.now().microsecondsSinceEpoch}';
  }

  void _add(String role, String text) {
    final String content = text.trim();
    if (content.isEmpty) return;

    _messages.add(
      ConversationMessage(
        id: generateMessageId(),
        role: role,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
    _trimToLimit();
  }

  void _trimToLimit() {
    if (_messages.length <= _maxMessages) return;

    final List<ConversationMessage> systemMessages = _messages
        .where((ConversationMessage message) => message.isSystem)
        .toList();
    final List<ConversationMessage> normalMessages = _messages
        .where((ConversationMessage message) => !message.isSystem)
        .toList();

    final int availableSlots = (_maxMessages - systemMessages.length).clamp(
      0,
      _maxMessages,
    );

    final List<ConversationMessage> keptNormalMessages = availableSlots == 0
        ? <ConversationMessage>[]
        : normalMessages.length <= availableSlots
            ? normalMessages
            : normalMessages.sublist(normalMessages.length - availableSlots);

    _messages
      ..clear()
      ..addAll(systemMessages.take(_maxMessages))
      ..addAll(keptNormalMessages);
  }

  String _labelForRole(String role) {
    switch (role) {
      case ConversationRole.system:
        return 'System';
      case ConversationRole.assistant:
        return 'Assistant';
      case ConversationRole.user:
      default:
        return 'User';
    }
  }
}
