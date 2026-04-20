import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/citation.dart';

class CitationSheet extends StatelessWidget {
  final Citation citation;
  final bool isDark;

  const CitationSheet({super.key, required this.citation, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppTheme.inkDark : AppTheme.inkLight;
    final muted = isDark ? AppTheme.mutedDark : AppTheme.mutedLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final sheetBg = isDark ? const Color(0xEB0C0C18) : const Color(0xF5FFFFFF);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 60,
              offset: Offset(0, -20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grabber
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x33FFFFFF)
                            : const Color(0x260F172A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accentSoft.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(LucideIcons.bookOpen,
                            size: 17, color: AppTheme.accentSoft),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SOURCE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                                color: muted,
                              ),
                            ),
                            Text(
                              citation.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: ink,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'p. ${citation.page}',
                        style: GoogleFonts.inter(fontSize: 11, color: muted),
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.x, size: 18, color: muted),
                        tooltip: AppStrings.a11yClose,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Verse block
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x08FFFFFF)
                          : AppTheme.accentSoft.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      citation.passageText ?? 'Verifying source context…',
                      style: GoogleFonts.notoSerif(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: ink,
                        height: 1.55,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x404F46E5),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Read full chapter',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Icon(LucideIcons.bookmark, size: 16, color: muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
