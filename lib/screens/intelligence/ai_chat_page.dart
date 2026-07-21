import 'dart:async';
import 'dart:ui' as ui;
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:myfin_mobile/widgets/navigation/myfin_back_button.dart';
import 'package:flutter/services.dart';
import 'package:myfin_mobile/services/ai/ai_chat_service.dart';
import 'package:myfin_mobile/services/ai/openai_provider.dart';
import 'package:myfin_mobile/services/ai/portfolio_analysis.dart';
import 'package:myfin_mobile/models/portfolio_item.dart';
import 'package:myfin_mobile/services/portfolio_valuation_service.dart';
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
  const AiChatPage({
    super.key,
    required this.analysis,
    required this.portfolioItems,
    this.initialQuestion,
  });

  final PortfolioAnalysis analysis;
  final List<PortfolioItem> portfolioItems;
  final String? initialQuestion;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  static final Map<String, _ChatSession> _sessions = <String, _ChatSession>{};
  static StreamSubscription<User?>? _authSubscription;

  late final AIChatService _chatService;
  late final List<_ChatMessage> _messages;

  bool _isSending = false;

  static const List<_SuggestedPrompt> _suggestedPrompts = <_SuggestedPrompt>[
    _SuggestedPrompt(
      icon: Icons.donut_large_rounded,
      title: 'Dağılım grafiği',
      prompt: 'Portföyümü kategori dağılım grafiğiyle gösterir misin?',
    ),
    _SuggestedPrompt(
      icon: Icons.bar_chart_rounded,
      title: 'Kâr/zarar grafiği',
      prompt: 'Kalemlerin kâr zararını sütun grafikle karşılaştırır mısın?',
    ),
    _SuggestedPrompt(
      icon: Icons.compare_arrows_rounded,
      title: 'Maliyet / güncel',
      prompt: 'Maliyet ve güncel değerleri ürün bazında karşılaştırır mısın?',
    ),
    _SuggestedPrompt(
      icon: Icons.category_rounded,
      title: 'Kategori sonucu',
      prompt: 'Kategori bazında kâr zarar grafiğini gösterir misin?',
    ),
    _SuggestedPrompt(
      icon: Icons.balance_rounded,
      title: 'Kazanan / kaybeden',
      prompt: 'Kazandıran ve kaybettiren kalemlerin grafiğini gösterir misin?',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final initialQuestion = widget.initialQuestion?.trim() ?? '';
    if (initialQuestion.isNotEmpty) {
      _messageController.text = initialQuestion;
    }
    _authSubscription ??= FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      if (user != null) return;
      for (final session in _sessions.values) {
        session.chatService.dispose();
      }
      _sessions.clear();
    });

    final user = FirebaseAuth.instance.currentUser;
    final sessionKey = user?.uid ?? 'signed-out';
    final displayName = _displayNameFor(user);
    final session = _sessions.putIfAbsent(
      sessionKey,
      () => _ChatSession(
        chatService: AIChatService(provider: OpenAIProvider()),
        messages: <_ChatMessage>[
          _ChatMessage.assistant(text: _welcomeMessage(displayName)),
        ],
      ),
    );
    _chatService = session.chatService;
    _messages = session.messages;
  }

  static String _displayNameFor(User? user) {
    final profileName = user?.displayName?.trim() ?? '';
    if (profileName.isNotEmpty) return profileName;
    final emailName = user?.email?.split('@').first.trim() ?? '';
    return emailName.isNotEmpty ? emailName : 'MyFin kullanıcısı';
  }

  static String _welcomeMessage(String displayName) {
    return 'Merhaba $displayName 👋\n\n'
        'Ben MyFin AI. Portföyünü, risklerini, piyasa notlarını ve finansal kararlarını '
        'daha net görmen için buradayım. Bana portföyün, nakit durumun, hedeflerin veya '
        'merak ettiğin hisseler hakkında soru sorabilirsin.';
  }

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
      final valuation = await _loadPortfolioValuation();
      final chartType = _chartTypeFor(text);
      if (chartType != null && mounted) {
        setState(() {
          assistantMessage
            ..chartType = chartType
            ..valuation = valuation;
        });
      }
      await for (final String chunk in _chatService.askStream(
        analysis: widget.analysis,
        valuation: valuation,
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

  Future<PortfolioValuation> _loadPortfolioValuation() async {
    final service = PortfolioValuationService.instance;
    final cached = service.peek(widget.portfolioItems);
    if (cached != null) {
      // Sohbeti bekletmeden son güvenilir değerlemeyi kullan; sonraki istek için
      // canlı fiyat yenilemesini arka planda başlat.
      unawaited(
        service
            .calculate(widget.portfolioItems, forceRefresh: true)
            .catchError((_) => cached),
      );
      return cached;
    }

    try {
      return await service
          .calculate(widget.portfolioItems)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      return _costBasisFallback();
    } catch (_) {
      return _costBasisFallback();
    }
  }

  PortfolioValuation _costBasisFallback() {
    final entries = widget.portfolioItems
        .map((item) {
          final cost = item.totalCost;
          return PortfolioItemValuation(
            item: item,
            costInBaseCurrency: cost,
            currentValueInBaseCurrency: cost,
            profitLossInBaseCurrency: 0,
            profitPercent: 0,
            hasLivePrice: false,
          );
        })
        .toList(growable: false);
    final total = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.costInBaseCurrency,
    );
    return PortfolioValuation(
      baseCurrency: PortfolioValuationService.baseCurrency,
      items: entries,
      totalCost: total,
      totalValue: total,
      totalProfit: 0,
      profitPercent: 0,
      updatedAt: DateTime.now(),
      isStale: true,
    );
  }

  _PortfolioChartType? _chartTypeFor(String question) {
    final value = question.toLowerCase();
    final wantsChart =
        value.contains('grafik') ||
        value.contains('grafiğ') ||
        value.contains('görsel') ||
        value.contains('pasta') ||
        value.contains('sütun') ||
        value.contains('dağılım') ||
        value.contains('dagilim') ||
        value.contains('karşılaştır') ||
        value.contains('karsilastir') ||
        value.contains('yoğunlaş') ||
        value.contains('artıyo') ||
        value.contains('arttı') ||
        value.contains('yogunlas');
    if (!wantsChart) return null;
    final mentionsProfitLoss =
        value.contains('kâr') ||
        value.contains('kar ') ||
        value.contains('zarar') ||
        value.contains('getiri') ||
        value.contains('performans');
    if (value.contains('kazandır') ||
        value.contains('kaybettir') ||
        value.contains('pozitif') ||
        value.contains('artıyo') ||
        value.contains('arttı') ||
        value.contains('negatif')) {
      return _PortfolioChartType.winnersLosers;
    }
    if (value.contains('kategori') && mentionsProfitLoss) {
      return _PortfolioChartType.categoryProfitLoss;
    }
    if (value.contains('maliyet') ||
        value.contains('alış') ||
        value.contains('alis')) {
      return _PortfolioChartType.costVsValue;
    }
    if (value.contains('yoğunlaş') ||
        value.contains('yogunlas') ||
        value.contains('risk ağırl') ||
        value.contains('risk agir')) {
      return _PortfolioChartType.concentration;
    }
    if (mentionsProfitLoss) {
      return _PortfolioChartType.profitLoss;
    }
    if (value.contains('dağılım') ||
        value.contains('dagilim') ||
        value.contains('kategori') ||
        value.contains('pasta')) {
      return _PortfolioChartType.distribution;
    }
    if (value.contains('ürün') ||
        value.contains('urun') ||
        value.contains('kalem') ||
        value.contains('değer') ||
        value.contains('deger') ||
        value.contains('sütun')) {
      return _PortfolioChartType.itemValues;
    }
    return _PortfolioChartType.distribution;
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
                          onCopy: () => _copyMessage(
                            _MessageBubble._withoutChartCodeBlocks(
                              message.text,
                            ),
                          ),
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
                    fontWeight: FontWeight.w400,
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
              fontWeight: FontWeight.w400,
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
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onPromptSelected(
              'Portföyümdeki şirket, metal ve dövizlerle ilgili güncel haberleri kaynaklarıyla derler misin?',
            ),
            icon: const Icon(Icons.newspaper_rounded, size: 18),
            label: const Text('Portföy haberlerini tara'),
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
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Sormak için dokun',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
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
                if (!isUser &&
                    message.chartType != null &&
                    message.valuation != null) ...<Widget>[
                  _PortfolioChart(
                    type: message.chartType!,
                    valuation: message.valuation!,
                  ),
                  const SizedBox(height: 14),
                ],

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
                        fontWeight: FontWeight.w400,
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
    final text = _withoutChartCodeBlocks(message.text);
    if (!message.isStreaming) return text;
    if (text.trim().isEmpty) return 'MyFin AI düşünüyor...';
    return '$text▌';
  }

  static String _withoutChartCodeBlocks(String input) {
    var result = input.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    final unfinishedFence = result.indexOf('```');
    if (unfinishedFence >= 0) {
      result = result.substring(0, unfinishedFence);
    }
    return result.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
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
                  fontWeight: FontWeight.w400,
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
  _PortfolioChartType? chartType;
  PortfolioValuation? valuation;
}

class _ChatSession {
  const _ChatSession({required this.chatService, required this.messages});

  final AIChatService chatService;
  final List<_ChatMessage> messages;
}

enum _PortfolioChartType {
  distribution,
  profitLoss,
  itemValues,
  costVsValue,
  categoryProfitLoss,
  winnersLosers,
  concentration,
}

class _PortfolioChart extends StatefulWidget {
  const _PortfolioChart({required this.type, required this.valuation});

  final _PortfolioChartType type;
  final PortfolioValuation valuation;

  @override
  State<_PortfolioChart> createState() => _PortfolioChartState();
}

class _PortfolioChartState extends State<_PortfolioChart> {
  final GlobalKey _captureKey = GlobalKey();
  bool _isSharing = false;

  static const colors = <Color>[
    Color(0xFF2563EB),
    Color(0xFFF59E0B),
    Color(0xFF16A34A),
    Color(0xFF8B5CF6),
    Color(0xFF0891B2),
    Color(0xFFEC4899),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _captureKey,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: _buildChart(),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _isSharing ? null : _sharePng,
            icon: _isSharing
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded, size: 17),
            label: Text(_isSharing ? 'Hazırlanıyor' : 'PNG Paylaş'),
          ),
        ),
      ],
    );
  }

  Future<void> _sharePng() async {
    setState(() => _isSharing = true);
    try {
      final box = context.findRenderObject() as RenderBox?;
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data?.buffer.asUint8List();
      if (bytes == null) return;
      await SharePlus.instance.share(
        ShareParams(
          text: 'MyFin AI portföy grafiği',
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: 'myfin_${widget.type.name}.png',
            ),
          ],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Widget _buildChart() {
    return switch (widget.type) {
      _PortfolioChartType.distribution => _buildDistribution(),
      _PortfolioChartType.profitLoss => _buildProfitLoss(),
      _PortfolioChartType.itemValues => _buildItemValues(),
      _PortfolioChartType.costVsValue => _buildCostVsValue(),
      _PortfolioChartType.categoryProfitLoss => _buildCategoryProfitLoss(),
      _PortfolioChartType.winnersLosers => _buildWinnersLosers(),
      _PortfolioChartType.concentration => _buildConcentration(),
    };
  }

  Widget _buildDistribution() {
    final totals = <String, double>{};
    for (final entry in widget.valuation.items) {
      final category = entry.item.type.trim().isEmpty
          ? 'Diğer'
          : entry.item.type.trim();
      totals.update(
        category,
        (value) => value + entry.currentValueInBaseCurrency,
        ifAbsent: () => entry.currentValueInBaseCurrency,
      );
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty || widget.valuation.totalValue <= 0) {
      return const Text('Dağılım grafiği için yeterli değerleme yok.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori Dağılımı',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 42,
              sectionsSpace: 2,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value,
                    color: colors[i % colors.length],
                    radius: 42,
                    title:
                        '%${(entries[i].value / widget.valuation.totalValue * 100).toStringAsFixed(0)}',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (var i = 0; i < entries.length; i++)
              _ChartLegend(
                color: colors[i % colors.length],
                label: entries[i].key,
                value:
                    '%${(entries[i].value / widget.valuation.totalValue * 100).toStringAsFixed(1)}',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfitLoss() {
    final entries = [...widget.valuation.items]
      ..sort(
        (a, b) => b.profitLossInBaseCurrency.abs().compareTo(
          a.profitLossInBaseCurrency.abs(),
        ),
      );
    final visible = entries.take(8).toList();
    if (visible.isEmpty) {
      return const Text('Kâr/zarar grafiği için yeterli değerleme yok.');
    }
    final maxPercent = visible
        .map((entry) => entry.profitPercent.abs())
        .fold<double>(1, (max, value) => value > max ? value : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Oran(%) Bazında Kar / Zarar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 16),
        for (final entry in visible) ...[
          _ProfitLossRow(entry: entry, maxPercent: maxPercent),
          const SizedBox(height: 12),
        ],
        const Text(
          'Çubuklardaki renkli alanlar getiri yüzdesini, sağdaki değer TL kâr/zararı gösterir.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildItemValues() {
    final entries = [...widget.valuation.items]
      ..sort(
        (a, b) => b.currentValueInBaseCurrency.compareTo(
          a.currentValueInBaseCurrency,
        ),
      );
    final visible = entries.take(8).toList();
    return _buildMetricRows(
      title: 'Ürün Bazında Güncel Değer',
      entries: [
        for (final entry in visible)
          _ChartMetric(
            label: entry.item.symbol,
            value: entry.currentValueInBaseCurrency,
            displayValue: _compactMoney(entry.currentValueInBaseCurrency),
            color: const Color(0xFF2563EB),
          ),
      ],
      footnote: 'Çubuk uzunluğu ürünün güncel portföy değerini gösterir.',
    );
  }

  Widget _buildCostVsValue() {
    final entries = [...widget.valuation.items]
      ..sort(
        (a, b) => b.currentValueInBaseCurrency.compareTo(
          a.currentValueInBaseCurrency,
        ),
      );
    final visible = entries.take(8).toList();
    final maxValue = visible
        .expand(
          (entry) => [
            entry.costInBaseCurrency.abs(),
            entry.currentValueInBaseCurrency.abs(),
          ],
        )
        .fold<double>(1, (max, value) => value > max ? value : max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maliyet / Güncel Değer',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 14),
        for (final entry in visible) ...[
          _ComparisonBarRow(entry: entry, maxValue: maxValue),
          const SizedBox(height: 12),
        ],
        const Wrap(
          spacing: 14,
          children: [
            _ChartLegend(color: Color(0xFF94A3B8), label: 'Maliyet', value: ''),
            _ChartLegend(color: Color(0xFF2563EB), label: 'Güncel', value: ''),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryProfitLoss() {
    final totals = <String, double>{};
    for (final entry in widget.valuation.items) {
      final category = entry.item.type.trim().isEmpty
          ? 'Diğer'
          : entry.item.type.trim();
      totals.update(
        category,
        (value) => value + entry.profitLossInBaseCurrency,
        ifAbsent: () => entry.profitLossInBaseCurrency,
      );
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    return _buildMetricRows(
      title: 'Kategori Bazında Kâr / Zarar',
      entries: [
        for (final entry in entries)
          _ChartMetric(
            label: entry.key,
            value: entry.value.abs(),
            displayValue: _compactMoney(entry.value),
            color: entry.value >= 0
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
          ),
      ],
      footnote:
          'Yeşil kârı, kırmızı zararı; uzunluk mutlak TL etkisini gösterir.',
    );
  }

  Widget _buildWinnersLosers() {
    final winners = widget.valuation.items
        .where((entry) => entry.profitLossInBaseCurrency > 0)
        .length;
    final losers = widget.valuation.items
        .where((entry) => entry.profitLossInBaseCurrency < 0)
        .length;
    final neutral = widget.valuation.items.length - winners - losers;
    final total = widget.valuation.items.length;
    if (total == 0) {
      return const Text('Karşılaştırma için portföy kalemi bulunmuyor.');
    }
    final data = <(String, int, Color)>[
      ('Kazandıran', winners, const Color(0xFF16A34A)),
      ('Kaybettiren', losers, const Color(0xFFDC2626)),
      if (neutral > 0) ('Değişmeyen', neutral, const Color(0xFF94A3B8)),
    ];
    return _buildDonut(
      title: 'Kazandıran / Kaybettiren',
      sections: [
        for (final item in data)
          _DonutMetric(
            label: item.$1,
            value: item.$2.toDouble(),
            displayValue: '${item.$2} kalem',
            color: item.$3,
          ),
      ],
    );
  }

  Widget _buildConcentration() {
    final entries = [...widget.valuation.items]
      ..sort(
        (a, b) => b.currentValueInBaseCurrency.compareTo(
          a.currentValueInBaseCurrency,
        ),
      );
    final top = entries.take(5).toList();
    final other = entries
        .skip(5)
        .fold<double>(
          0,
          (sum, entry) => sum + entry.currentValueInBaseCurrency,
        );
    return _buildDonut(
      title: 'Ürün Bazında Yoğunlaşma',
      sections: [
        for (var i = 0; i < top.length; i++)
          _DonutMetric(
            label: top[i].item.symbol,
            value: top[i].currentValueInBaseCurrency,
            displayValue:
                '%${(top[i].currentValueInBaseCurrency / widget.valuation.totalValue * 100).toStringAsFixed(1)}',
            color: colors[i % colors.length],
          ),
        if (other > 0)
          _DonutMetric(
            label: 'Diğer',
            value: other,
            displayValue:
                '%${(other / widget.valuation.totalValue * 100).toStringAsFixed(1)}',
            color: const Color(0xFF94A3B8),
          ),
      ],
    );
  }

  Widget _buildMetricRows({
    required String title,
    required List<_ChartMetric> entries,
    required String footnote,
  }) {
    if (entries.isEmpty) return const Text('Grafik için yeterli veri yok.');
    final maxValue = entries
        .map((entry) => entry.value.abs())
        .fold<double>(1, (max, value) => value > max ? value : max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 14),
        for (final entry in entries) ...[
          _MetricBarRow(entry: entry, maxValue: maxValue),
          const SizedBox(height: 12),
        ],
        Text(
          footnote,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDonut({
    required String title,
    required List<_DonutMetric> sections,
  }) {
    final nonEmpty = sections.where((entry) => entry.value > 0).toList();
    if (nonEmpty.isEmpty) return const Text('Grafik için yeterli veri yok.');
    final total = nonEmpty.fold<double>(0, (sum, entry) => sum + entry.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 42,
              sectionsSpace: 2,
              sections: [
                for (final entry in nonEmpty)
                  PieChartSectionData(
                    value: entry.value,
                    color: entry.color,
                    radius: 42,
                    title: '%${(entry.value / total * 100).toStringAsFixed(0)}',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final entry in nonEmpty)
              _ChartLegend(
                color: entry.color,
                label: entry.label,
                value: entry.displayValue,
              ),
          ],
        ),
      ],
    );
  }

  static String _compactMoney(double value) {
    final sign = value > 0 ? '+' : '';
    final abs = value.abs();
    if (abs >= 1000000) {
      return '$sign${(value / 1000000).toStringAsFixed(2)} Mn TL';
    }
    if (abs >= 1000) return '$sign${(value / 1000).toStringAsFixed(1)} Bin TL';
    return '$sign${value.toStringAsFixed(2)} TL';
  }
}

class _ChartMetric {
  const _ChartMetric({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.color,
  });

  final String label;
  final double value;
  final String displayValue;
  final Color color;
}

class _DonutMetric {
  const _DonutMetric({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.color,
  });

  final String label;
  final double value;
  final String displayValue;
  final Color color;
}

class _MetricBarRow extends StatelessWidget {
  const _MetricBarRow({required this.entry, required this.maxValue});

  final _ChartMetric entry;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final progress = (entry.value.abs() / maxValue).clamp(0.02, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              entry.displayValue,
              style: TextStyle(
                color: entry.color,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                width: constraints.maxWidth * progress,
                height: 8,
                decoration: BoxDecoration(
                  color: entry.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComparisonBarRow extends StatelessWidget {
  const _ComparisonBarRow({required this.entry, required this.maxValue});

  final PortfolioItemValuation entry;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.item.symbol,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Text(
              '${_PortfolioChartState._compactMoney(entry.costInBaseCurrency)} → ${_PortfolioChartState._compactMoney(entry.currentValueInBaseCurrency)}',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 9,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        _ThinValueBar(
          value: entry.costInBaseCurrency,
          maxValue: maxValue,
          color: const Color(0xFF94A3B8),
        ),
        const SizedBox(height: 3),
        _ThinValueBar(
          value: entry.currentValueInBaseCurrency,
          maxValue: maxValue,
          color: const Color(0xFF2563EB),
        ),
      ],
    );
  }
}

class _ThinValueBar extends StatelessWidget {
  const _ThinValueBar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (value.abs() / maxValue).clamp(0.01, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: constraints.maxWidth * progress,
        height: 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label $value',
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ProfitLossRow extends StatelessWidget {
  const _ProfitLossRow({required this.entry, required this.maxPercent});

  final PortfolioItemValuation entry;
  final double maxPercent;

  @override
  Widget build(BuildContext context) {
    final positive = entry.profitLossInBaseCurrency >= 0;
    final color = positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final progress = (entry.profitPercent.abs() / maxPercent).clamp(0.02, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 68,
              child: Text(
                entry.item.symbol,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Text(
              '${positive ? '+' : ''}${entry.profitPercent.toStringAsFixed(2)}%',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Text(
              _PortfolioChartState._compactMoney(
                entry.profitLossInBaseCurrency,
              ),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Container(
                width: constraints.maxWidth * progress,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
