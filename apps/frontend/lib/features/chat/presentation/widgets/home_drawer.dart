import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../theme/app_theme.dart';
import '../../application/chat_state.dart';
import '../../domain/models/conversation.dart';

class HomeDrawer extends StatelessWidget {
  final ChatState chatState;
  final bool isGuest;
  final bool isAdmin;
  final bool isDark;
  final String? userEmail;
  final VoidCallback onNewConversation;
  final VoidCallback onSettings;
  final VoidCallback onAdmin;
  final ValueChanged<String> onSelectConversation;
  final VoidCallback onSignIn;
  final VoidCallback onLogout;

  const HomeDrawer({
    super.key,
    required this.chatState,
    required this.isGuest,
    required this.isAdmin,
    required this.isDark,
    this.userEmail,
    required this.onNewConversation,
    required this.onSettings,
    required this.onAdmin,
    required this.onSelectConversation,
    required this.onSignIn,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppTheme.inkDark : AppTheme.inkLight;
    final muted = isDark ? AppTheme.mutedDark : AppTheme.mutedLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final drawerBg = isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgDark2, AppTheme.bgDarkSurface],
          )
        : AppTheme.backgroundGradient;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(gradient: drawerBg),
        child: Column(
          children: [
            // User header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.user,
                        color: Colors.white, size: 18,
                        semanticLabel: AppStrings.a11yUserAvatar),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGuest ? AppStrings.drawerGuestUser : (userEmail ?? 'Seeker'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: ink,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isGuest) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${chatState.guestQueriesRemaining} ${AppStrings.drawerQueriesRemaining}',
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
                            ),
                          ),
                        ] else
                          Text(
                            'Lifetime · signed in',
                            style: GoogleFonts.inter(fontSize: 10, color: muted),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.settings, size: 16, color: muted),
                    onPressed: onSettings,
                    tooltip: AppStrings.drawerSettings,
                  ),
                ],
              ),
            ),

            // Menu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DrawerAction(
                      icon: LucideIcons.plus,
                      label: AppStrings.drawerNewConversation,
                      isDark: isDark,
                      surface: surface,
                      border: border,
                      ink: ink,
                      isGradient: true,
                      onTap: onNewConversation,
                    ),
                    const SizedBox(height: 8),
                    if (isGuest)
                      DrawerAction(
                        icon: LucideIcons.logIn,
                        label: AppStrings.drawerSignIn,
                        isDark: isDark,
                        surface: surface,
                        border: border,
                        ink: ink,
                        onTap: onSignIn,
                      )
                    else ...[
                      DrawerAction(
                        icon: LucideIcons.logOut,
                        label: AppStrings.drawerLogout,
                        isDark: isDark,
                        surface: surface,
                        border: border,
                        ink: ink,
                        onTap: onLogout,
                        itemKey: const Key('logout_menu_item'),
                      ),
                      const SizedBox(height: 8),
                      DrawerAction(
                        icon: LucideIcons.settings,
                        label: AppStrings.drawerSettings,
                        isDark: isDark,
                        surface: surface,
                        border: border,
                        ink: ink,
                        onTap: onSettings,
                      ),
                    ],
                    if (!isGuest && isAdmin) ...[
                      const SizedBox(height: 8),
                      DrawerAction(
                        icon: LucideIcons.layoutDashboard,
                        label: 'Admin Dashboard',
                        isDark: isDark,
                        surface: surface,
                        border: border,
                        ink: ink,
                        onTap: onAdmin,
                        itemKey: const Key('admin_dashboard_menu_item'),
                      ),
                    ],

                    // Recent conversations
                    if (!isGuest && chatState.recentConversations.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 10),
                          child: Text(
                            AppStrings.drawerRecentTitle.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                        ),
                      ),
                      ...chatState.recentConversations.take(5).map(
                            (Conversation conv) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: HistoryRow(
                                title: conv.title,
                                ink: ink,
                                muted: muted,
                                surface: surface,
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
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'v1.0.0',
                style: GoogleFonts.inter(color: muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isGradient;
  final Color surface;
  final Color border;
  final Color ink;
  final VoidCallback onTap;
  final Key? itemKey;

  const DrawerAction({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.ink,
    required this.onTap,
    this.isGradient = false,
    this.itemKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: itemKey,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          gradient: isGradient ? AppTheme.primaryGradient : null,
          color: isGradient ? null : surface,
          borderRadius: BorderRadius.circular(10),
          border: isGradient ? null : Border.all(color: border),
          boxShadow: isGradient
              ? const [
                  BoxShadow(
                    color: Color(0x354F46E5),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isGradient ? Colors.white : ink),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isGradient ? Colors.white : ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryRow extends StatelessWidget {
  final String title;
  final Color ink;
  final Color muted;
  final Color surface;
  final VoidCallback onTap;

  const HistoryRow({
    super.key,
    required this.title,
    required this.ink,
    required this.muted,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.accentSoft.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, color: muted),
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
