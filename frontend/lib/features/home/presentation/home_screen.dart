import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../theme/app_theme.dart';
import '../../chat/application/chat_controller.dart';
import '../../chat/application/chat_state.dart';
import '../../chat/domain/models/citation.dart';
import '../../chat/domain/models/message.dart';
import '../../chat/domain/models/conversation.dart';
import '../../auth/application/auth_controller.dart';

/// Main chat screen for both guest and authenticated users.
///
/// Displays an empty state with suggestion cards, a message
/// list with user/assistant bubbles, a text input bar, and
/// a navigation drawer with user profile and actions.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates a [HomeScreen].
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

    final authState = ref.read(authControllerProvider);
    final currentUser = authState;
    final guestSessionId = currentUser == AppStrings.guestUserId
        ? AppStrings.guestSessionId
        : null;

    ref
        .read(chatControllerProvider.notifier)
        .sendQuery(userMsg, guestSessionId: guestSessionId);

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
              // Routing handled automatically via GoRouter refresh
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
      final current = next;
      final prev = previous;

      if (current.error != null && current.error != prev?.error) {
        if (current.error == 'Rate limit exceeded') {
          _showRateLimitModal();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(current.error!)));
        }
        ref.read(chatControllerProvider.notifier).resetError();
      }
      if (current.messages.length > (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    final chatState = ref.watch(chatControllerProvider);
    final currentUser = ref.watch(authControllerProvider);
    final isGuest = currentUser == AppStrings.guestUserId;

    return GradientScaffold(
      drawer: _HomeDrawer(
        chatState: chatState,
        isGuest: isGuest,
        userEmail: isGuest ? null : currentUser,
        onNewConversation: () {
          ref.read(chatControllerProvider.notifier).newConversation();
          Navigator.pop(context);
        },
        onSettings: () {
          Navigator.pop(context);
          context.push('/settings');
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
          children: [
            const Icon(
              LucideIcons.bookOpen,
              color: AppTheme.teal500,
              size: 20,
              semanticLabel: AppStrings.a11yBrandLogo,
            ),
            const SizedBox(width: 8),
            Text(
              AppStrings.brandName,
              style: GoogleFonts.outfit(
                color: AppTheme.gray900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: AppTheme.gray900),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? _EmptyStateView(
                    onSuggestionTap: (text) {
                      _messageController.text = text;
                      _sendMessage();
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    itemCount:
                        chatState.messages.length +
                        (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length) {
                        return const _TypingIndicator();
                      }
                      final msg = chatState.messages[index];
                      final isUser = msg.sender == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: isUser
                              ? _UserMessageBubble(message: msg)
                              : _AssistantMessageBubble(message: msg),
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
          _ChatInputBar(
            controller: _messageController,
            isDisabled: chatState.isLoading || chatState.rateLimitExceeded,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

/// Navigation drawer showing user profile and menu actions.
class _HomeDrawer extends StatelessWidget {
  final ChatState chatState;
  final bool isGuest;
  final String? userEmail;
  final VoidCallback onNewConversation;
  final VoidCallback onSettings;
  final ValueChanged<String> onSelectConversation;
  final VoidCallback onSignIn;
  final VoidCallback onLogout;

  const _HomeDrawer({
    required this.chatState,
    required this.isGuest,
    this.userEmail,
    required this.onNewConversation,
    required this.onSettings,
    required this.onSelectConversation,
    required this.onSignIn,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.purple300.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.secondaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      color: Colors.white,
                      size: 24,
                      semanticLabel: AppStrings.a11yUserAvatar,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGuest
                              ? AppStrings.drawerGuestUser
                              : (userEmail ?? 'Authenticated User'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gray900,
                            fontSize: 16,
                          ),
                        ),
                        if (isGuest) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.secondaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${chatState.guestQueriesRemaining}'
                              ' ${AppStrings.drawerQueriesRemaining}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _DrawerMenuItem(
                    icon: LucideIcons.circlePlus,
                    label: AppStrings.drawerNewConversation,
                    color: AppTheme.teal500,
                    onTap: onNewConversation,
                  ),
                  const SizedBox(height: 16),
                  if (isGuest)
                    _DrawerMenuItem(
                      icon: LucideIcons.logIn,
                      label: AppStrings.drawerSignIn,
                      color: AppTheme.purple500,
                      onTap: onSignIn,
                    )
                  else
                    _DrawerMenuItem(
                      icon: LucideIcons.logOut,
                      label: AppStrings.drawerLogout,
                      color: Colors.grey,
                      onTap: onLogout,
                      itemKey: const Key('logout_menu_item'),
                    ),
                  if (!isGuest) ...[
                    const SizedBox(height: 16),
                    _DrawerMenuItem(
                      icon: LucideIcons.settings,
                      label: AppStrings.drawerSettings,
                      color: AppTheme.purple500,
                      onTap: onSettings,
                    ),
                  ],
                  if (!isGuest && chatState.recentConversations.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.drawerRecentTitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gray700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...chatState.recentConversations
                        .take(5)
                        .map(
                          (Conversation conv) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _HistoryItem(
                              title: conv.title,
                              onTap: () {
                                Navigator.pop(context);
                                onSelectConversation(conv.id);
                              },
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'v1.0.0',
                style: GoogleFonts.inter(color: AppTheme.gray700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single item in the navigation drawer.
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Key? itemKey;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.itemKey,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: itemKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single item in the recent history list within the drawer.
class _HistoryItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _HistoryItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.messageSquare,
              size: 14,
              color: AppTheme.gray700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.gray900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state shown when there are no messages yet.
class _EmptyStateView extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;

  const _EmptyStateView({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.messageSquare,
                size: 48,
                color: AppTheme.teal500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.emptyStateTitle,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.emptyStateSubtitle,
              style: GoogleFonts.inter(fontSize: 16, color: AppTheme.gray700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                for (final suggestion in AppStrings.suggestions)
                  _SuggestionCard(text: suggestion, onTap: onSuggestionTap),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable suggestion card shown in the empty state.
class _SuggestionCard extends StatelessWidget {
  final String text;
  final ValueChanged<String> onTap;

  const _SuggestionCard({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: 300,
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => onTap(text),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(color: AppTheme.gray900),
              ),
            ),
            const Icon(
              LucideIcons.arrowRight,
              size: 16,
              color: AppTheme.teal500,
            ),
          ],
        ),
      ),
    );
  }
}

/// A user message bubble with gradient background.
class _UserMessageBubble extends StatelessWidget {
  final Message message;

  const _UserMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${message.timestamp.hour}:'
        '${message.timestamp.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.teal500.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.content,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            timeStr,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// An assistant message bubble with citation list.
class _AssistantMessageBubble extends StatelessWidget {
  final Message message;

  const _AssistantMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${message.timestamp.hour}:'
        '${message.timestamp.minute.toString().padLeft(2, '0')}';
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: MarkdownBody(
                  data: message.content,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.inter(
                      color: AppTheme.gray900,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  onTapLink: (text, href, title) async {
                    if (href != null) {
                      final url = Uri.parse(href);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    }
                  },
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  LucideIcons.share2,
                  size: 18,
                  color: AppTheme.gray700,
                ),
                tooltip: AppStrings.a11yShare,
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: '${message.content}\n\nShared from Sacred Wisdom',
                      subject: 'Spiritual Insight',
                    ),
                  );
                },
              ),
            ],
          ),
          if (message.citations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: AppTheme.gray200),
            const SizedBox(height: 8),
            Text(
              AppStrings.sourcesTitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray700,
              ),
            ),
            const SizedBox(height: 4),
            ...message.citations.map(
              (Citation citation) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  onTap: () => _showCitationSheet(context, citation),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.link,
                        size: 12,
                        color: AppTheme.teal500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${citation.title} '
                        '(p. ${citation.page})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.teal500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              timeStr,
              style: GoogleFonts.inter(color: AppTheme.gray700, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _showCitationSheet(BuildContext context, Citation citation) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.bookOpen,
                  color: AppTheme.teal500,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.scriptureVerseTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gray900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  tooltip: AppStrings.a11yClose,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              citation.title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: AppTheme.gray700,
              ),
            ),
            Text(
              'Page ${citation.page}',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.gray700),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white),
              ),
              child: Text(
                citation.passageText ?? 'Verifying source context...',
                style: GoogleFonts.notoSerif(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.gray900,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Animated three-dot typing indicator.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.a11yAssistantTyping,
      liveRegion: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _TypingDot(),
              SizedBox(width: 4),
              _TypingDot(),
              SizedBox(width: 4),
              _TypingDot(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppTheme.gray700,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Chat text input bar with send button.
class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDisabled;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isDisabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Chat input field',
                  child: TextField(
                    key: const Key('chat_input_field'),
                    controller: controller,
                    enabled: !isDisabled,
                    maxLength: 2000,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    decoration: const InputDecoration(
                      hintText: 'Ask a question...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: GoogleFonts.inter(color: Colors.black),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Send message',
                child: IconButton(
                  key: const Key('chat_send_button'),
                  onPressed: isDisabled ? null : onSend,
                  icon: Icon(
                    LucideIcons.send,
                    color: isDisabled ? AppTheme.gray200 : AppTheme.teal500,
                  ),
                ),
              ),
            ],
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return Text(
                '${value.text.length} / 2000',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: value.text.length >= 2000
                      ? Colors.red
                      : AppTheme.gray700,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
