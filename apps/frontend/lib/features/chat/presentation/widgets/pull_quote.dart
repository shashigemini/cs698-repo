import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/citation.dart';

class PullQuote extends StatelessWidget {
  final Citation citation;
  final bool isDark;
  final Color ink;
  final VoidCallback onTap;

  const PullQuote({
    super.key,
    required this.citation,
    required this.isDark,
    required this.ink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(left: 18, top: 14, bottom: 14, right: 16),
        decoration: BoxDecoration(
          color: AppTheme.accentSoft.withValues(alpha: isDark ? 0.12 : 0.06),
          border: Border(
            left: BorderSide(color: AppTheme.accentSoft, width: 2),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: 0.3,
              child: Icon(LucideIcons.quote, size: 14, color: AppTheme.accentSoft),
            ),
            const SizedBox(height: 6),
            Text(
              citation.passageText ?? citation.title,
              style: GoogleFonts.notoSerif(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: ink,
                height: 1.55,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 1,
                  color: AppTheme.accentSoft,
                ),
                const SizedBox(width: 6),
                Text(
                  '${citation.title}  ·  p. ${citation.page}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: AppTheme.accentSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FooterAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const FooterAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
