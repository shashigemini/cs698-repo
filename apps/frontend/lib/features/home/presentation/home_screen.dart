import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../theme/app_theme.dart';
import '../../chat/application/chat_controller.dart';
import '../../chat/application/chat_state.dart';
import '../../chat/presentation/widgets/composer.dart';
import '../../chat/presentation/widgets/home_drawer.dart';
import '../../chat/presentation/widgets/message_bubbles.dart';
import '../../chat/presentation/widgets/typing_indicator.dart';
import '../../auth/application/auth_controller.dart';
import '../../admin/application/admin_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final userMsg = _messageController.text;
    _messageController.clear();
    final currentUser = ref.read(authControllerProvider);
    final guestSessionId =
        currentUser == AppStrings.guestUserId ? AppStrings.guestSessionId : null;
    ref.read(chatControllerProvider.notifier).sendQuery(userMsg, guestSessionId: guestSessionId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showRateLimitModal() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.rateLimitModalTitle),
        content: Text(AppStrings.rateLimitModalBody),
        actions: [
          TextButton(
            key: const Key('maybe_later_button'),
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.maybeLater),
          ),
          TextButton(
            key: const Key('signin_from_modal_button'),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).logout();
            },
            child: Text(AppStrings.signInAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ChatState>(chatControllerProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        if (next.error == 'Rate limit exceeded') {
          _showRateLimitModal();
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(next.error!)));
        }
        ref.read(chatControllerProvider.notifier).resetError();
      }
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    final chatState = ref.watch(chatControllerProvider);
    final currentUser = ref.watch(authControllerProvider);
    final isGuest = currentUser == AppStrings.guestUserId;
    final isAdminUser = ref.watch(isAdminProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.inkLight;
    final muted = isDark ? AppTheme.mutedDark : AppTheme.mutedLight;

    return GradientScaffold(
      drawer: HomeDrawer(
        chatState: chatState,
        isGuest: isGuest,
        isAdmin: isAdminUser,
        userEmail: isGuest ? null : currentUser,
        isDark: isDark,
        onNewConversation: () {
          ref.read(chatControllerProvider.notifier).newConversation();
          Navigator.pop(context);
        },
        onSettings: () {
          Navigator.pop(context);
          context.push('/settings');
        },
        onAdmin: () {
          Navigator.pop(context);
          context.push('/admin');
        },
        onSelectConversation: (id) {
          ref.read(chatControllerProvider.notifier).loadConversation(id);
        },
        onSignIn: () {
          ref.read(authControllerProvider.notifier).logout();
          context.go('/login');
        },
        onLogout: () {
          ref.read(authControllerProvider.notifier).logout();
          context.go('/login');
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bookOpen, color: AppTheme.accentSoft, size: 18,
                semanticLabel: AppStrings.a11yBrandLogo),
            const SizedBox(width: 8),
            Text(
              AppStrings.brandName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ink,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: ink),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? _EmptyStateView(
                    isDark: isDark,
                    onSuggestionTap: (text) {
                      _messageController.text = text;
                      _sendMessage();
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length) {
                        return const TypingIndicator();
                      }
                      final msg = chatState.messages[index];
                      final isUser = msg.sender == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: isUser
                              ? UserBubble(message: msg, isDark: isDark)
                              : AssistantBubble(message: msg, isDark: isDark),
                        ),
                      );
                    },
                  ),
          ),
          if (chatState.rateLimitExceeded)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.withValues(alpha: 0.1),
              child: Text(
                AppStrings.rateLimitBanner,
                style: GoogleFonts.inter(color: Colors.red),
                key: const Key('rate_limit_banner'),
              ),
            ),
          Composer(
            controller: _messageController,
            isDark: isDark,
            isDisabled: chatState.isLoading || chatState.rateLimitExceeded,
            muted: muted,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Empty state — categorized layout
// ══════════════════════════════════════════════════════════════

const _kCategories = [
  _Category('Purpose', LucideIcons.compass, 'What is my dharma in this life?'),
  _Category('Grief', LucideIcons.heart, 'How do I sit with loss?'),
  _Category('Stillness', LucideIcons.feather, 'Teach me to quiet my mind.'),
  _Category('Presence', LucideIcons.clock, 'How do I live in the present?'),
];

class _Category {
  final String name;
  final IconData icon;
  final String prompt;
  const _Category(this.name, this.icon, this.prompt);
}

class _EmptyStateView extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onSuggestionTap;

  const _EmptyStateView({required this.isDark, required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppTheme.inkDark : AppTheme.inkLight;
    final muted = isDark ? AppTheme.mutedDark : AppTheme.mutedLight;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Flourish ornament
            _Flourish(color: AppTheme.accentSoft, size: 90),
            const SizedBox(height: 16),
            Text(
              'What weighs on you?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a thread to begin.',
              style: GoogleFonts.inter(fontSize: 14, color: muted),
            ),
            const SizedBox(height: 28),

            // 2×2 category grid
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: _kCategories
                    .map((cat) => _CategoryCard(
                          category: cat,
                          isDark: isDark,
                          ink: ink,
                          surface: surface,
                          border: border,
                          onTap: () => onSuggestionTap(cat.prompt),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _Category category;
  final bool isDark;
  final Color ink;
  final Color surface;
  final Color border;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isDark,
    required this.ink,
    required this.surface,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.accentSoft.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(category.icon, size: 16, color: AppTheme.accentSoft),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: AppTheme.accentSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    category.prompt,
                    style: GoogleFonts.inter(fontSize: 12, color: ink, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── SVG-style flourish ornament ────────────────────────────────
class _Flourish extends StatelessWidget {
  final Color color;
  final double size;

  const _Flourish({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.3),
      painter: _FlourishPainter(color: color),
    );
  }
}

class _FlourishPainter extends CustomPainter {
  final Color color;
  _FlourishPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final h = size.height / 2;
    // left line
    canvas.drawLine(Offset(0, h), Offset(size.width * 0.38, h), paint);
    // right line
    canvas.drawLine(Offset(size.width * 0.62, h), Offset(size.width, h), paint);
    // diamond
    final cx = size.width / 2;
    final path = Path()
      ..moveTo(cx - size.width * 0.1, h)
      ..lineTo(cx, h - size.height * 0.4)
      ..lineTo(cx + size.width * 0.1, h)
      ..lineTo(cx, h + size.height * 0.4)
      ..close();
    canvas.drawPath(path, paint);

    // center dot
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, h), 1.5, dotPaint);
  }

  @override
  bool shouldRepaint(_FlourishPainter old) => old.color != color;
}

