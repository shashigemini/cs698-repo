import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../../core/constants/app_strings.dart';
import '../../application/auth_controller.dart';
import '../../../../core/utils/app_logger.dart';

class RecoverAccountDialog extends ConsumerStatefulWidget {
  const RecoverAccountDialog({super.key});

  @override
  ConsumerState<RecoverAccountDialog> createState() =>
      _RecoverAccountDialogState();
}

class _RecoverAccountDialogState extends ConsumerState<RecoverAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _mnemonicController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _mnemonicController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRecover() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(authControllerProvider.notifier)
          .recoverAccount(
            email: _emailController.text.trim(),
            mnemonic: _mnemonicController.text.trim(),
            newPassword: _passwordController.text,
          );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppStrings.accountRecovered),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to recover account. Please check your mnemonic.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.e('Recovery error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Recover Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your details and recovery phrase to reset your password.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('recovery_email_field'),
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(LucideIcons.mail, size: 20),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('recovery_mnemonic_field'),
                controller: _mnemonicController,
                decoration: const InputDecoration(
                  labelText: '16-Word Recovery Phrase',
                  prefixIcon: Icon(LucideIcons.key, size: 20),
                  hintText: 'word1 word2 ... word16',
                ),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.split(RegExp(r'\s+')).length != 16)
                    ? 'Enter exactly 16 words'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('recovery_new_password_field'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(LucideIcons.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? 'Min 8 chars' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('recovery_submit_button'),
                onPressed: _isLoading ? null : _handleRecover,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Reset password'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
