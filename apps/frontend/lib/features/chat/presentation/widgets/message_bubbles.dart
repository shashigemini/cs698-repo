import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/citation.dart';
import '../../domain/models/message.dart';
import 'citation_sheet.dart';
import 'pull_quote.dart';

String _fmtTime(DateTime t) =>
    '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

class UserBubble extends StatelessWidget {
  final Message message;
  final bool isDark;

  const UserBubble({super.key, required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final timeStr = _fmtTime(message.timestamp);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x354F46E5),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            message.content,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          timeStr,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isDark ? AppTheme.mutedDark : AppTheme.mutedLight,
          ),
        ),
      ],
    );
  }
}

class AssistantBubble extends StatelessWidget {
  final Message message;
  final bool isDark;

  const AssistantBubble({super.key, required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppTheme.inkDark : AppTheme.inkLight;
    final muted = isDark ? AppTheme.mutedDark : AppTheme.mutedLight;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final timeStr = _fmtTime(message.timestamp);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(18),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: surface,
            border: Border.all(color: border),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: MarkdownBody(
                      data: message.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(
                          color: ink, fontSize: 15, height: 1.65,
                        ),
                        a: GoogleFonts.inter(
                          color: AppTheme.accentSoft,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onTapLink: (text, href, title) async {
                        if (href == null) return;
                        if (href.startsWith('#citation-')) {
                          final idx = int.tryParse(
                              href.replaceFirst('#citation-', ''));
                          if (idx != null &&
                              idx > 0 &&
                              idx <= message.citations.length) {
                            _showCitationSheet(
                                context, message.citations[idx - 1], isDark);
                            return;
                          }
                        }
                        final url = Uri.parse(href);
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                    ),
                  ),
                ],
              ),

              if (message.citations.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...message.citations.take(1).map(
                      (citation) => PullQuote(
                        citation: citation,
                        isDark: isDark,
                        ink: ink,
                        onTap: () =>
                            _showCitationSheet(context, citation, isDark),
                      ),
                    ),
                if (message.citations.length > 1) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: message.citations.skip(1).map((c) {
                      return GestureDetector(
                        onTap: () => _showCitationSheet(context, c, isDark),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentSoft.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.accentSoft
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.link,
                                  size: 10, color: AppTheme.accentSoft),
                              const SizedBox(width: 4),
                              Text(
                                '${c.title} (p. ${c.page})',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppTheme.accentSoft),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  FooterAction(
                    icon: LucideIcons.bookmark,
                    label: 'Save',
                    color: muted,
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  FooterAction(
                    icon: LucideIcons.share2,
                    label: 'Share',
                    color: muted,
                    onTap: () {
                      SharePlus.instance.share(ShareParams(
                        text: '${message.content}\n\nShared from Sacred Wisdom',
                        subject: 'Spiritual Insight',
                      ));
                    },
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(fontSize: 10, color: muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCitationSheet(
      BuildContext context, Citation citation, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CitationSheet(citation: citation, isDark: isDark),
    );
  }
}
