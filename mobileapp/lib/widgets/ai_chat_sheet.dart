import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/ai_provider.dart';
import '../providers/api_provider.dart';
import '../providers/locale_provider.dart';

class AiChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final String timestamp;

  const AiChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
  });
}

/// Slide-over AI chat panel — mirrors web `AIChatbotDrawer`.
class AiChatSheet extends ConsumerStatefulWidget {
  const AiChatSheet({super.key});

  @override
  ConsumerState<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends ConsumerState<AiChatSheet> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <AiChatMessage>[];
  bool _loading = false;
  bool _seeded = false;
  String? _lastHandledPrompt;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _bootstrap() {
    final l10n = ref.read(appLocalizationsProvider);
    if (!_seeded) {
      _seeded = true;
      _messages.add(AiChatMessage(
        id: 'welcome',
        isUser: false,
        text: l10n.aiWelcomeMessage,
        timestamp: _timeNow(),
      ));
    }
    _maybeSendPendingPrompt();
  }

  void _maybeSendPendingPrompt() {
    final pending = ref.read(aiChatProvider).pendingPrompt;
    if (pending == null || pending == _lastHandledPrompt) return;
    _lastHandledPrompt = pending;
    ref.read(aiChatProvider.notifier).consumePrompt();
    _send(pending);
  }

  String _timeNow() {
    final now = TimeOfDay.now();
    final h = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final m = now.minute.toString().padLeft(2, '0');
    final suffix = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $suffix';
  }

  Future<void> _send([String? textOverride]) async {
    final text = (textOverride ?? _inputCtrl.text).trim();
    if (text.isEmpty || _loading) return;

    final l10n = ref.read(appLocalizationsProvider);
    setState(() {
      _messages.add(AiChatMessage(
        id: 'u-${DateTime.now().millisecondsSinceEpoch}',
        isUser: true,
        text: text,
        timestamp: _timeNow(),
      ));
      _loading = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    try {
      final api = ref.read(apiClientProvider);
      final shopContext = await buildAiShopContext(ref);
      final lang = aiLanguageCode(ref);
      final data = await api.aiChat(
        message: text,
        language: lang,
        shopContext: shopContext,
      );
      final reply = data['reply']?.toString() ??
          (lang == 'sw' ? 'Samahani, jaribu tena.' : 'Sorry, please try again.');

      if (!mounted) return;
      setState(() {
        _messages.add(AiChatMessage(
          id: 'a-${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: reply,
          timestamp: _timeNow(),
        ));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(AiChatMessage(
          id: 'err-${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: l10n.aiNetworkError,
          timestamp: _timeNow(),
        ));
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AiChatState>(aiChatProvider, (prev, next) {
      if (next.isOpen && next.pendingPrompt != null &&
          next.pendingPrompt != _lastHandledPrompt) {
        _maybeSendPendingPrompt();
      }
    });

    final l10n = ref.watch(appLocalizationsProvider);
    final bottom = MediaQuery.of(context).padding.bottom;
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = width > 500 ? 440.0 : width;

    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: () => ref.read(aiChatProvider.notifier).close(),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: panelWidth,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 24,
                        offset: Offset(-4, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _Header(l10n: l10n, onClose: () {
                        ref.read(aiChatProvider.notifier).close();
                      }),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF8F8F8),
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length + (_loading ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == _messages.length && _loading) {
                                return _LoadingBubble(l10n: l10n);
                              }
                              final msg = _messages[i];
                              return _MessageBubble(message: msg);
                            },
                          ),
                        ),
                      ),
                      _QuickChips(l10n: l10n, onTap: _send),
                      _Composer(
                        l10n: l10n,
                        controller: _inputCtrl,
                        loading: _loading,
                        bottom: bottom,
                        onSend: () => _send(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onClose;

  const _Header({required this.l10n, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF24284A), Color(0xFF6264A7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFFFCD34D), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aiAssistantTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    l10n.aiAssistantSubtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AiChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF6264A7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF0078D4) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormattedText(
                    text: message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                    boldColor: isUser ? Colors.white : AppColors.textPrimary,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      message.timestamp,
                      style: TextStyle(
                        fontSize: 9,
                        color: isUser
                            ? Colors.white70
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF0078D4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormattedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color boldColor;

  const _FormattedText({
    required this.text,
    required this.style,
    required this.boldColor,
  });

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    if (parts.length == 1) {
      return Text(text, style: style);
    }
    return RichText(
      text: TextSpan(
        style: style.copyWith(color: style.color),
        children: [
          for (var i = 0; i < parts.length; i++)
            TextSpan(
              text: parts[i],
              style: i.isOdd
                  ? style.copyWith(fontWeight: FontWeight.w700, color: boldColor)
                  : style,
            ),
        ],
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  final AppLocalizations l10n;

  const _LoadingBubble({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.aiAnalyzing,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChips extends StatelessWidget {
  final AppLocalizations l10n;
  final void Function(String) onTap;

  const _QuickChips({required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chips = l10n.aiQuickChips;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final chip in chips)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(chip, style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFFF3F2F1),
                  side: const BorderSide(color: AppColors.border),
                  onPressed: () => onTap(chip),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final AppLocalizations l10n;
  final TextEditingController controller;
  final bool loading;
  final double bottom;
  final VoidCallback onSend;

  const _Composer({
    required this.l10n,
    required this.controller,
    required this.loading,
    required this.bottom,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !loading,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: l10n.askQuestionPlaceholder,
                filled: true,
                fillColor: const Color(0xFFF3F2F1),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF0078D4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: loading ? AppColors.textHint : const Color(0xFF6264A7),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: loading ? null : onSend,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
