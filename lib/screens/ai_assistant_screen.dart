// ============================================================
// RAWBY — JARVIS AI Assistant
// Voice-enabled · app navigation · full-screen immersive
// AI settings live in Settings screen — not here
// ============================================================
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/user_session_provider.dart';
import '../providers/router_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'paywall_screen.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _loading = false;
  bool _isListening = false;
  bool _speechEnabled = false;

  late AnimationController _orbCtrl;
  late AnimationController _listenCtrl;
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _listenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) => _addWelcome());
  }

  Future<void> _initSpeech() async {
    final enabled = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
          _listenCtrl.reverse();
          if (_controller.text.isNotEmpty) _send();
        }
      },
    );
    if (mounted) setState(() => _speechEnabled = enabled);
  }

  void _addWelcome() {
    final session = ref.read(userSessionProvider);
    final name = session.displayName.isNotEmpty ? session.displayName : session.username;
    setState(() {
      _messages.add(_ChatMessage(
        role: 'assistant',
        text: "Online, $name. I'm RAWBY AI — your creative command center.\n\nI can answer questions, navigate the app, analyze your stats, or help with any filmmaking challenge.\n\nTry: \"Go to leaderboard\", \"Show my stats\", or ask anything.",
      ));
    });
  }

  Future<void> _toggleListening() async {
    final session = ref.read(userSessionProvider);
    if (!session.isPro) {
      _showProGate();
      return;
    }
    if (!_speechEnabled) {
      _showSpeechUnavailable();
      return;
    }
    HapticFeedback.mediumImpact();
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _listenCtrl.reverse();
    } else {
      setState(() { _isListening = true; _controller.clear(); });
      _listenCtrl.forward();
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() => _controller.text = result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(cancelOnError: true),
      );
    }
  }

  void _showSpeechUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice input not available on this device.')),
    );
  }

  void _showProGate() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallScreen(featureName: 'Voice Mode'),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    _controller.clear();
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      _listenCtrl.reverse();
    }
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _loading = true;
    });
    _scrollToBottom();

    // Check for navigation commands first
    final navRoute = _parseNavigationCommand(text);
    if (navRoute != null) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            role: 'assistant',
            text: _navResponse(navRoute),
            navRoute: navRoute,
          ));
          _loading = false;
        });
        _scrollToBottom();
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go(navRoute);
      }
      return;
    }

    // AI response
    try {
      final session = ref.read(userSessionProvider);
      final api = ref.read(apiServiceProvider);

      final allMsgs = _messages
          .where((m) => m.role != 'typing')
          .map((m) => <String, String>{'role': m.role, 'content': m.text})
          .toList();
      final firstUser = allMsgs.indexWhere((m) => m['role'] == 'user');
      final historyForApi = firstUser < 0
          ? <Map<String, String>>[]
          : allMsgs.sublist(firstUser).take(10).toList();

      final ctx = {
        'totalScore': session.totalScore,
        'rank': session.currentRank.label,
        'streak': session.streak,
        'completedWeeks': session.completedWeeks,
        'avgLikes': session.avgLikes,
        'username': session.username,
      };

      final response = await api.aiChat(
        messages: historyForApi,
        context: ctx,
        provider: 'groq', // Groq only — Claude disabled
      );

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', text: response));
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            role: 'assistant',
            text: 'Something went wrong. Check your connection and try again.',
          ));
          _loading = false;
        });
        _scrollToBottom();
      }
    }
  }

  String? _parseNavigationCommand(String input) {
    final lower = input.toLowerCase();
    final isNav = lower.startsWith('go to') ||
        lower.startsWith('open ') ||
        lower.startsWith('navigate to') ||
        lower.startsWith('show ') ||
        lower.startsWith('take me to');

    if (!isNav && !lower.contains('go to') && !lower.contains('navigate')) return null;

    if (lower.contains('prompt') || lower.contains('challenge')) return Routes.prompts;
    if (lower.contains('leaderboard') || lower.contains('ranking')) return Routes.leaderboard;
    if (lower.contains('profile')) return Routes.profile;
    if (lower.contains('gear') || lower.contains('equipment')) return Routes.gear;
    if (lower.contains('skill') || lower.contains('training')) return Routes.skill;
    if (lower.contains('setting')) return Routes.settings;
    if (lower.contains('home') || lower.contains('dashboard')) return Routes.home;
    if (lower.contains('admin')) return Routes.admin;
    return null;
  }

  String _navResponse(String route) {
    switch (route) {
      case Routes.prompts: return 'Navigating to Prompts. Choose your next challenge.';
      case Routes.leaderboard: return 'Pulling up the Leaderboard. Let\'s see where you stand.';
      case Routes.profile: return 'Opening your Profile. Looking good.';
      case Routes.gear: return 'Opening Gear vault. What are you working with?';
      case Routes.skill: return 'Skill Center loading. Time to level up.';
      case Routes.settings: return 'Opening Settings. AI configuration is in here.';
      case Routes.home: return 'Returning to Command Center.';
      case Routes.admin: return 'Admin panel accessed.';
      default: return 'Navigating now.';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _orbCtrl.dispose();
    _listenCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  static const _quickPrompts = [
    'Show my stats',
    'Tips to improve score?',
    'Go to leaderboard',
    'Cinematic editing tips?',
    'Help with lighting?',
    'Go to prompts',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final showQuickPrompts = _messages.length <= 1 && !_loading;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // ── JARVIS Orb Header ──────────────────────────────────
          _JarvisOrbHeader(
            orbCtrl: _orbCtrl,
            listenCtrl: _listenCtrl,
            loading: _loading,
            isListening: _isListening,
            theme: theme,
            isDark: isDark,
          ),

          // ── Messages ──────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length + (_loading ? 1 : 0) + (showQuickPrompts ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (showQuickPrompts && i == _messages.length) {
                  return _QuickPrompts(
                    prompts: _quickPrompts,
                    onTap: (p) { _controller.text = p; _send(); },
                    theme: theme,
                    isDark: isDark,
                  );
                }
                if (_loading && i == _messages.length + (showQuickPrompts ? 1 : 0)) {
                  return _TypingIndicator(theme: theme, isDark: isDark);
                }
                if (i < _messages.length) {
                  return _AnimatedMessageBubble(
                    msg: _messages[i],
                    theme: theme,
                    isDark: isDark,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // ── Input Bar ─────────────────────────────────────────
          _InputBar(
            controller: _controller,
            onSend: _send,
            onVoice: _toggleListening,
            loading: _loading,
            isListening: _isListening,
            speechEnabled: _speechEnabled,
            isPro: ref.watch(userSessionProvider).isPro,
            listenCtrl: _listenCtrl,
            theme: theme,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ── JARVIS Orb Header ────────────────────────────────────────

class _JarvisOrbHeader extends StatelessWidget {
  final AnimationController orbCtrl;
  final AnimationController listenCtrl;
  final bool loading;
  final bool isListening;
  final ThemeData theme;
  final bool isDark;

  const _JarvisOrbHeader({
    required this.orbCtrl,
    required this.listenCtrl,
    required this.loading,
    required this.isListening,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final activeColor = isListening
        ? theme.colorScheme.tertiary
        : loading
            ? RawbyPalette.info
            : theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.only(top: topPad + 12, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C0C) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Animated orb
          AnimatedBuilder(
            animation: orbCtrl,
            builder: (ctx, _) => SizedBox(
              width: 44,
              height: 44,
              child: CustomPaint(
                painter: _OrbPainter(
                  progress: orbCtrl.value,
                  color: activeColor,
                  listening: isListening,
                  thinking: loading,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RAWBY AI',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                AnimatedBuilder(
                  animation: orbCtrl,
                  builder: (ctx, _) {
                    final label = isListening
                        ? 'Listening...'
                        : loading
                            ? 'Processing...'
                            : 'Ready';
                    return Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: activeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0);
  }
}

// ── Orb Painter ──────────────────────────────────────────────

class _OrbPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool listening;
  final bool thinking;

  const _OrbPainter({
    required this.progress,
    required this.color,
    required this.listening,
    required this.thinking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Outer ring
    canvas.drawCircle(
      center,
      maxR * (0.9 + progress * 0.1),
      Paint()
        ..color = color.withValues(alpha: 0.08 + progress * 0.04)
        ..style = PaintingStyle.fill,
    );

    // Mid ring
    final midR = maxR * (0.65 + (listening ? math.sin(progress * math.pi) * 0.15 : 0));
    canvas.drawCircle(
      center,
      midR,
      Paint()
        ..color = color.withValues(alpha: 0.15 + progress * 0.08)
        ..style = PaintingStyle.fill,
    );

    // Core
    canvas.drawCircle(
      center,
      maxR * 0.42,
      Paint()
        ..color = color.withValues(alpha: 0.3 + progress * 0.15)
        ..style = PaintingStyle.fill,
    );

    // Icon — draw a simple circle dot for simplicity
    canvas.drawCircle(
      center,
      maxR * 0.18,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill,
    );

    // Rotating ring when thinking
    if (thinking) {
      final sweepPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: maxR * 0.82),
        progress * math.pi * 2,
        math.pi * 1.2,
        false,
        sweepPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.listening != listening ||
      old.thinking != thinking;
}

// ── Chat Message ─────────────────────────────────────────────

class _ChatMessage {
  final String role;
  final String text;
  final String? navRoute;

  const _ChatMessage({
    required this.role,
    required this.text,
    this.navRoute,
  });
}

// ── Animated Message Bubble ───────────────────────────────────

class _AnimatedMessageBubble extends StatefulWidget {
  final _ChatMessage msg;
  final ThemeData theme;
  final bool isDark;

  const _AnimatedMessageBubble({
    required this.msg,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    final isUser = widget.msg.role == 'user';
    _slide = Tween<Offset>(
      begin: Offset(isUser ? 0.08 : -0.08, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _MessageBubble(msg: widget.msg, theme: widget.theme, isDark: widget.isDark),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage msg;
  final ThemeData theme;
  final bool isDark;

  const _MessageBubble({required this.msg, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    final isNav = msg.navRoute != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.tertiary.withValues(alpha: 0.5),
                    theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(Icons.auto_awesome, size: 13, color: theme.colorScheme.tertiary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : isNav
                        ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
                        : (isDark ? const Color(0xFF1A1A1A) : RawbyPalette.lightCard),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isNav
                            ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
                            : (isDark ? const Color(0xFF252525) : RawbyPalette.lightBorder),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? theme.colorScheme.primary : Colors.black)
                        .withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isNav && !isUser) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.navigation_rounded, size: 12, color: theme.colorScheme.tertiary),
                        const SizedBox(width: 6),
                        Text(
                          'Navigating',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.tertiary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    msg.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isUser ? Colors.black : null,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Quick Prompts ────────────────────────────────────────────

class _QuickPrompts extends StatelessWidget {
  final List<String> prompts;
  final void Function(String) onTap;
  final ThemeData theme;
  final bool isDark;

  const _QuickPrompts({
    required this.prompts,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick commands', style: theme.textTheme.bodySmall).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prompts.asMap().entries.map((e) => GestureDetector(
              onTap: () => onTap(e.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : RawbyPalette.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF252525) : RawbyPalette.lightBorder,
                  ),
                ),
                child: Text(
                  e.value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: 250 + e.key * 50))
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Typing Indicator ─────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final ThemeData theme;
  final bool isDark;
  const _TypingIndicator({required this.theme, required this.isDark});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.tertiary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.theme.colorScheme.tertiary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(Icons.auto_awesome, size: 13, color: widget.theme.colorScheme.tertiary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1A1A1A) : RawbyPalette.lightCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: widget.isDark ? const Color(0xFF252525) : RawbyPalette.lightBorder,
              ),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (ctx, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final t = (math.sin((_ctrl.value * 3 - i) * math.pi)).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: Transform.translate(
                      offset: Offset(0, -5 * t),
                      child: Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: widget.theme.colorScheme.tertiary.withValues(alpha: 0.4 + t * 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input Bar ────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onVoice;
  final bool loading;
  final bool isListening;
  final bool speechEnabled;
  final bool isPro;
  final AnimationController listenCtrl;
  final ThemeData theme;
  final bool isDark;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onVoice,
    required this.loading,
    required this.isListening,
    required this.speechEnabled,
    required this.isPro,
    required this.listenCtrl,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C0C) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Voice button
          AnimatedBuilder(
            animation: listenCtrl,
            builder: (ctx, _) => GestureDetector(
              onTap: onVoice,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening
                          ? theme.colorScheme.tertiary
                          : isDark
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFF0F0F0),
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.tertiary
                                    .withValues(alpha: 0.4 * listenCtrl.value),
                                blurRadius: 16,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 20,
                      color: isListening
                          ? Colors.white
                          : speechEnabled
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.outline,
                    ),
                  ),
                  if (!isPro)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: isListening ? 'Listening...' : 'Command or question...',
                hintStyle: TextStyle(
                  color: isListening
                      ? theme.colorScheme.tertiary.withValues(alpha: 0.7)
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF252525) : const Color(0xFFEEEEEE),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: theme.colorScheme.tertiary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                filled: true,
                fillColor: isDark ? const Color(0xFF141414) : const Color(0xFFF5F5F5),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: loading ? null : onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: loading
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : theme.colorScheme.primary,
                boxShadow: loading
                    ? null
                    : [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: loading
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
