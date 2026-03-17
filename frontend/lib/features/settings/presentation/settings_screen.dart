import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../theme/app_theme.dart';
import '../../chat/application/chat_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/widgets/change_password_dialog.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/demo_mode_provider.dart';
import '../../admin/application/admin_controller.dart';
import '../../chat/domain/models/conversation.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).fetchRecentConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteAccount() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is permanent and will delete all your conversation history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authControllerProvider.notifier).deleteAccount();
              context.go('/login');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final filteredConversations = chatState.recentConversations
        .where(
          (conv) =>
              conv.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Account Settings',
          style: GoogleFonts.outfit(
            color: AppTheme.gray900,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.gray900),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UsageMeter(
              usage: chatState.queryUsage,
              limit: chatState.totalUsageLimit,
            ),
            const SizedBox(height: 32),
            Text(
              'Conversation History',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.gray900,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search history...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (filteredConversations.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No matching conversations found.',
                    style: GoogleFonts.inter(color: AppTheme.gray700),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredConversations.length,
                itemBuilder: (context, index) {
                  final conv = filteredConversations[index];
                  return _HistoryListItem(
                    key: ValueKey('history_item_${conv.id}'),
                    conversation: conv,
                    onDelete: () async {
                      debugPrint(
                        'SettingsScreen: onDelete triggered for ${conv.id}',
                      );
                      await ref
                          .read(chatControllerProvider.notifier)
                          .deleteConversation(conv.id);
                      if (context.mounted) {
                        debugPrint('SettingsScreen: showing deletion snackbar');
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.clearSnackBars();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Conversation deleted')),
                        );
                      }
                    },
                    onExport: () async {
                      debugPrint(
                        'SettingsScreen: onExport triggered for ${conv.id}',
                      );
                      final data = await ref
                          .read(chatControllerProvider.notifier)
                          .exportConversation(conv.id);
                      if (data != null && context.mounted) {
                        debugPrint('SettingsScreen: showing export snackbar');
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.clearSnackBars();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Conversation exported'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => const ChangePasswordDialog(),
                  );
                },
                icon: const Icon(LucideIcons.keyRound),
                label: const Text('Change Password'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _confirmDeleteAccount,
                icon: const Icon(LucideIcons.trash2),
                label: const Text('Delete Account Permanently'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ),
            if (ref.watch(isDemoModeProvider)) ...[
              const SizedBox(height: 48),
              const Divider(),
              const SizedBox(height: 24),
              const _DemoAdminPanel(),
            ],
          ],
        ),
      ),
    );
  }
}

class _UsageMeter extends StatelessWidget {
  final int usage;
  final int limit;

  const _UsageMeter({required this.usage, required this.limit});

  @override
  Widget build(BuildContext context) {
    final percent = (usage / limit).clamp(0.0, 1.0);
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Usage',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                ),
              ),
              Text(
                '$usage / $limit queries',
                style: GoogleFonts.inter(color: AppTheme.gray700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: AppTheme.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                percent > 0.8 ? Colors.orange : AppTheme.teal500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Usage resets on the 1st of every month.',
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.gray700),
          ),
        ],
      ),
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  const _HistoryListItem({
    super.key,
    required this.conversation,
    required this.onDelete,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
      ),
      child: ListTile(
        title: Text(
          conversation.title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Created on ${conversation.createdAt.day}/${conversation.createdAt.month}/${conversation.createdAt.year}',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.gray700),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.download, size: 20),
              onPressed: onExport,
              tooltip: 'Export',
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () {
          // Placeholder for selecting conversation
        },
      ),
    );
  }
}

class _DemoAdminPanel extends ConsumerStatefulWidget {
  const _DemoAdminPanel();

  @override
  ConsumerState<_DemoAdminPanel> createState() => _DemoAdminPanelState();
}

class _DemoAdminPanelState extends ConsumerState<_DemoAdminPanel> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _idController = TextEditingController();
  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminControllerProvider);
    final isLoading = adminState.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.demoAdminTitle,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.gray900,
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.demoUploadPdf,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: AppStrings.demoPdfTitle,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: AppStrings.demoPdfAuthor,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: AppStrings.demoPdfLogicalId,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(LucideIcons.fileText),
                label: Text(
                  _selectedFile?.name ?? 'Select PDF',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedFile == null ||
                          _titleController.text.isEmpty ||
                          _idController.text.isEmpty ||
                          isLoading)
                      ? null
                      : () async {
                          final success = await ref
                              .read(
                                adminControllerProvider.notifier,
                              )
                              .ingestDocument(
                                fileBytes: _selectedFile!.bytes!,
                                filename: _selectedFile!.name,
                                title: _titleController.text,
                                logicalBookId: _idController.text,
                                author: _authorController.text.isEmpty
                                    ? null
                                    : _authorController.text,
                              );
                          if (success) {
                            _showSnackBar(
                              AppStrings.demoPdfIngested,
                            );
                            setState(
                              () => _selectedFile = null,
                            );
                            _titleController.clear();
                            _authorController.clear();
                            _idController.clear();
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          AppStrings.demoUploadButton,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
