import 'dart:async';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:flutter/material.dart';
import 'package:myfin_mobile/widgets/navigation/myfin_back_button.dart';
import 'package:flutter/services.dart';
import 'package:myfin_mobile/services/ai/ai_chat_service.dart';
import 'package:myfin_mobile/services/ai/openai_provider.dart';
import 'package:myfin_mobile/services/ai/portfolio_analysis.dart';
import '../../widgets/navigation/myfin_bottom_nav.dart';

/// MyFin AI Chat Page
///
/// Production-ready, dependency-free Flutter screen for the Intelligence area.
/// It includes:
/// - Clean financial assistant chat UI
/// - Suggested prompts
/// - Typing/loading state
/// - Scroll-to-bottom behavior
/// - Copy message action
/// - Safe keyboard handling
/// - Empty/error-safe local response engine
///
/// Replace [_LocalMyFinAiResponder] with your backend/OpenAI/Firebase service
/// when the production AI endpoint is ready.
class QuickPrompt {
  final String title;
  final String prompt;
  final IconData icon;

  const QuickPrompt({
    required this.title,
    required this.prompt,
    required this.icon,
  });
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key, required this.analysis});

  final PortfolioAnalysis analysis;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIChatService _chatService = AIChatService(provider: OpenAIProvider());
  final FocusNode _inputFocusNode = FocusNode();

  final List<_ChatMessage> _messages = <_ChatMessage>[
    _ChatMessage.assistant(
      text:
          'Merhaba Erhan 👋\n\nBen MyFin AI. Portföyünü, risklerini, piyasa notlarını ve finansal kararlarını daha net görmen için buradayım. Bana portföyün, nakit durumun, hedeflerin veya merak ettiğin hisseler hakkında soru sorabilirsin.',
    ),
  ];

  bool _isSending = false;

  static const List<_SuggestedPrompt> _suggestedPrompts = <_SuggestedPrompt>[
    _SuggestedPrompt(
      icon: Icons.insights_rounded,
      title: 'Portföy yorumu',
      prompt: 'Portföyümü risk, çeşitlilik ve denge açısından yorumlar mısın?',
    ),
    _SuggestedPrompt(
      icon: Icons.warning_amber_rounded,
      title: 'Risk analizi',
      prompt: 'Portföyümdeki en büyük riskler neler olabilir?',
    ),
    _SuggestedPrompt(
      icon: Icons.trending_up_rounded,
      title: 'Piyasa özeti',
      prompt: 'Bugünkü piyasa hareketlerini sade bir dille özetler misin?',
    ),
    _SuggestedPrompt(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Nakit planı',
      prompt: 'Yatırım yaparken ne kadar nakit tutmak mantıklı olur?',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? presetText]) async {
    final String text = (presetText ?? _messageController.text).trim();
    if (text.isEmpty || _isSending) return;

    HapticFeedback.selectionClick();

    final _ChatMessage assistantMessage = _ChatMessage.assistant(
      text: '',
      isStreaming: true,
    );

    setState(() {
      _messages.add(_ChatMessage.user(text: text));
      _messages.add(assistantMessage);
      _isSending = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final StringBuffer streamBuffer = StringBuffer();
    Timer? flushTimer;
    bool didShowFirstChunk = false;

    const Duration flushInterval = Duration(milliseconds: 72);
    const Duration finalCursorHold = Duration(milliseconds: 180);

    int nextVisibleLength(String value) {
      if (value.isEmpty) return 0;

      // Kısa parçalar doğal aksın.
      if (value.length <= 8) return value.length;

      // Çok küçük kelime kırılmaları yerine mümkünse kısa kelime grupları göster.
      final int searchLimit = value.length < 14 ? value.length : 14;
      for (int i = 5; i < searchLimit; i++) {
        final String char = value[i];
        if (char == ' ' || char == '\n' || char == '\t') {
          return i + 1;
        }
      }

      // Uzun kelimelerde ekrana bir anda çok metin basma.
      return 8;
    }

    void flushBufferedChunks() {
      if (!mounted || streamBuffer.isEmpty) return;

      final String current = streamBuffer.toString();
      final int take = nextVisibleLength(current);
      if (take <= 0) return;

      final String nextText = current.substring(0, take);

      streamBuffer
        ..clear()
        ..write(current.substring(take));

      setState(() {
        assistantMessage.text += nextText;
      });

      _scrollToBottom();
    }

    Future<void> drainBufferedChunks() async {
      while (mounted && streamBuffer.isNotEmpty) {
        flushBufferedChunks();

        if (streamBuffer.isNotEmpty) {
          await Future<void>.delayed(flushInterval);
        }
      }
    }

    flushTimer = Timer.periodic(flushInterval, (_) => flushBufferedChunks());

    try {
      await for (final String chunk in _chatService.askStream(
        analysis: widget.analysis,
        question: text,
      )) {
        if (chunk.isEmpty) continue;

        streamBuffer.write(chunk);

        // İlk gerçek token bekletilmesin; kullanıcı hemen yazma hissini görsün.
        if (!didShowFirstChunk) {
          didShowFirstChunk = true;
          flushBufferedChunks();
        }
      }

      flushTimer.cancel();

      // Stream bitince buffer'da kalan son parçaları kaybetmeden yazdır.
      await drainBufferedChunks();

      // İmleç cevap bittikten sonra çok kısa süre daha kalsın.
      await Future<void>.delayed(finalCursorHold);

      if (!mounted) return;
      setState(() {
        assistantMessage.isStreaming = false;
        if (assistantMessage.text.trim().isEmpty) {
          assistantMessage.text =
              'Şu anda net bir yanıt üretemedim. Sorunu biraz daha açık yazar mısın?';
        }
      });
    } catch (_) {
      flushTimer.cancel();

      if (!mounted) return;
      setState(() {
        assistantMessage
          ..isStreaming = false
          ..text =
              'Şu anda yanıt üretirken bir sorun oluştu. Lütfen biraz sonra tekrar dene.';
      });
    } finally {
      flushTimer.cancel();
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
        _inputFocusNode.requestFocus();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Mesaj kopyalandı'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        leading: const MyFinBackButton(),
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFFF6F8FB),
        foregroundColor: const Color(0xFF0F172A),
        titleSpacing: 0,
        title: const Text('MyFin AI'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: <Widget>[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: _HeroPanel(onPromptSelected: _sendMessage),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: _PromptChips(
                        prompts: _suggestedPrompts,
                        enabled: !_isSending,
                        onSelected: _sendMessage,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList.separated(
                      itemCount: _messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final _ChatMessage message = _messages[index];
                        return _MessageBubble(
                          message: message,
                          onCopy: () => _copyMessage(message.text),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            _Composer(
              controller: _messageController,
              focusNode: _inputFocusNode,
              enabled: !_isSending,
              onSend: _sendMessage,
              colorScheme: colors,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MyFinBottomNav(
        selectedIndex: 3,
        allowSelectedDestinationNavigation: true,
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onPromptSelected});

  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0F172A), Color(0xFF008DB9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF008DB9).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  'Beta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Akıllı finans sohbeti',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Portföyünü yorumlat, riskleri gör, piyasa gelişmelerini sadeleştir ve kararlarını daha bilinçli al.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 14,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onPromptSelected(
              'Portföyüm için kısa bir sağlık kontrolü yapar mısın?',
            ),
            icon: const Icon(Icons.health_and_safety_rounded, size: 18),
            label: const Text('Hızlı sağlık kontrolü'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChips extends StatelessWidget {
  const _PromptChips({
    required this.prompts,
    required this.enabled,
    required this.onSelected,
  });

  final List<_SuggestedPrompt> prompts;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final _SuggestedPrompt item = prompts[index];
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: enabled ? () => onSelected(item.prompt) : null,
            child: Ink(
              width: 176,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(item.icon, color: const Color(0xFF008DB9), size: 22),
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Sormak için dokun',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onCopy});

  final _ChatMessage message;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == _MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF008DB9) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(isUser ? 22 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 22),
            ),
            border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: <Widget>[
                isUser
                    ? Text(
                        message.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      )
                    : GptMarkdown(_assistantDisplayText(message)),

                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.72)
                            : const Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isUser) ...<Widget>[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onCopy,
                        borderRadius: BorderRadius.circular(999),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _assistantDisplayText(_ChatMessage message) {
    if (!message.isStreaming) return message.text;
    if (message.text.trim().isEmpty) return 'MyFin AI düşünüyor...';
    return '${message.text}▌';
  }

  static String _formatTime(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
    required this.colorScheme,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onSend;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.viewInsetsOf(context).bottom * 0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'MyFin AI’ya sor...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF008DB9),
                    width: 1.4,
                  ),
                ),
              ),
              onSubmitted: (_) {},
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (BuildContext context, TextEditingValue value, _) {
              final bool canSend = enabled && value.text.trim().isNotEmpty;
              return AnimatedOpacity(
                opacity: canSend ? 1 : 0.45,
                duration: const Duration(milliseconds: 180),
                child: FilledButton(
                  onPressed: canSend ? () => onSend(value.text) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF008DB9),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Icon(Icons.arrow_upward_rounded),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  _ChatMessage({
    required this.role,
    required this.text,
    DateTime? createdAt,
    this.isStreaming = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory _ChatMessage.user({required String text}) {
    return _ChatMessage(role: _MessageRole.user, text: text);
  }

  factory _ChatMessage.assistant({
    required String text,
    bool isStreaming = false,
  }) {
    return _ChatMessage(
      role: _MessageRole.assistant,
      text: text,
      isStreaming: isStreaming,
    );
  }

  final _MessageRole role;
  String text;
  final DateTime createdAt;
  bool isStreaming;
}

enum _MessageRole { user, assistant }

class _SuggestedPrompt {
  const _SuggestedPrompt({
    required this.icon,
    required this.title,
    required this.prompt,
  });

  final IconData icon;
  final String title;
  final String prompt;
}
