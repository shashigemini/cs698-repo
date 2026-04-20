import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../../theme/app_theme.dart';

class Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final bool isDisabled;
  final Color muted;
  final VoidCallback onSend;

  const Composer({
    super.key,
    required this.controller,
    required this.isDark,
    required this.isDisabled,
    required this.muted,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;
    final ink = isDark ? AppTheme.inkDark : AppTheme.inkLight;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Chat input field',
                        child: TextField(
                          key: const Key('chat_input_field'),
                          controller: controller,
                          enabled: !isDisabled,
                          maxLength: 2000,
                          buildCounter: (context,
                                  {required currentLength,
                                  required isFocused,
                                  maxLength}) =>
                              null,
                          decoration: InputDecoration(
                            hintText: 'Ask a question…',
                            hintStyle: GoogleFonts.inter(color: muted, fontSize: 15),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          style: GoogleFonts.inter(color: ink, fontSize: 15),
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
                      child: GestureDetector(
                        key: const Key('chat_send_button'),
                        onTap: isDisabled ? null : onSend,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: isDisabled ? null : AppTheme.primaryGradient,
                            color: isDisabled
                                ? (isDark
                                    ? const Color(0x1AFFFFFF)
                                    : const Color(0x1A0F172A))
                                : null,
                            shape: BoxShape.circle,
                            boxShadow: isDisabled
                                ? null
                                : const [
                                    BoxShadow(
                                      color: Color(0x504F46E5),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Icon(
                            LucideIcons.arrowUp,
                            size: 18,
                            color: isDisabled ? muted : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 2),
                    child: Text(
                      '${value.text.length} / 2000',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: value.text.length >= 2000 ? Colors.red : muted,
                      ),
                    ),
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
