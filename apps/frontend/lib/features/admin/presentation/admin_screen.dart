import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import '../../../core/presentation/widgets/glass_container.dart';
import '../../../core/presentation/widgets/gradient_scaffold.dart';
import '../../../theme/app_theme.dart';
import '../application/admin_controller.dart';

/// Admin Dashboard with PDF upload and document management.
class AdminScreen extends ConsumerStatefulWidget {
  /// Creates an [AdminScreen].
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _titleController = TextEditingController();
  final _bookIdController = TextEditingController();
  final _authorController = TextEditingController();
  final _editionController = TextEditingController();

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isUploading = false;
  List<Map<String, dynamic>> _documents = [];
  bool _isLoadingDocs = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    // Poll every 5 seconds so status updates are visible
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadDocuments(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _titleController.dispose();
    _bookIdController.dispose();
    _authorController.dispose();
    _editionController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    if (_isLoadingDocs) return;
    setState(() => _isLoadingDocs = true);
    try {
      final docs =
          await ref.read(adminControllerProvider.notifier).listDocuments();
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoadingDocs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDocs = false);
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _selectedFileBytes = result.files.single.bytes;
        _selectedFileName = result.files.single.name;
        // Auto-fill title from filename
        if (_titleController.text.isEmpty) {
          _titleController.text = result.files.single.name
              .replaceAll('.pdf', '')
              .replaceAll('_', ' ');
        }
      });
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedFileBytes == null || _selectedFileName == null) {
      _showSnackBar('Please select a PDF file first.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Please enter a document title.');
      return;
    }
    if (_bookIdController.text.trim().isEmpty) {
      _showSnackBar('Please enter a book ID.');
      return;
    }

    setState(() => _isUploading = true);
    final success =
        await ref.read(adminControllerProvider.notifier).ingestDocument(
              fileBytes: _selectedFileBytes!,
              filename: _selectedFileName!,
              title: _titleController.text.trim(),
              logicalBookId: _bookIdController.text.trim(),
              author: _authorController.text.trim().isNotEmpty
                  ? _authorController.text.trim()
                  : null,
              edition: _editionController.text.trim().isNotEmpty
                  ? _editionController.text.trim()
                  : null,
            );

    setState(() => _isUploading = false);
    if (success) {
      _showSnackBar('Document queued for ingestion!');
      _clearForm();
      await _loadDocuments();
    } else {
      _showSnackBar('Upload failed. Check logs.');
    }
  }

  void _clearForm() {
    _titleController.clear();
    _bookIdController.clear();
    _authorController.clear();
    _editionController.clear();
    setState(() {
      _selectedFileBytes = null;
      _selectedFileName = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: AppTheme.gray900,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: AppTheme.gray900,
          ),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUploadCard(),
            const SizedBox(height: 24),
            _buildDocumentsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.upload,
                color: AppTheme.purple500,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Upload PDF for Ingestion',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.gray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // File Picker
          _FilePickerButton(
            fileName: _selectedFileName,
            fileSize: _selectedFileBytes != null
                ? '${(_selectedFileBytes!.length / 1024 / 1024).toStringAsFixed(1)} MB'
                : null,
            onPick: _pickFile,
          ),
          const SizedBox(height: 16),

          // Title
          _buildTextField(
            controller: _titleController,
            label: 'Document Title *',
            hint: 'e.g. Discourses Volume 1',
          ),
          const SizedBox(height: 12),

          // Book ID
          _buildTextField(
            controller: _bookIdController,
            label: 'Logical Book ID *',
            hint: 'e.g. discourses_v1',
          ),
          const SizedBox(height: 12),

          // Author & Edition row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _authorController,
                  label: 'Author',
                  hint: 'Optional',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _editionController,
                  label: 'Edition',
                  hint: 'Optional',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Upload Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadDocument,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.cloudUpload),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload & Ingest',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.purple500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: GoogleFonts.inter(fontSize: 13),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppTheme.gray700,
        ),
      ),
      style: GoogleFonts.inter(fontSize: 14),
    );
  }

  Widget _buildDocumentsCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.fileText,
                color: AppTheme.teal500,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ingested Documents',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('refresh-docs'),
                icon: Icon(
                  LucideIcons.refreshCw,
                  color: AppTheme.gray700,
                  size: 20,
                ),
                onPressed: _loadDocuments,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_documents.isEmpty && !_isLoadingDocs)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 24,
              ),
              child: Center(
                child: Text(
                  'No documents ingested yet.\n'
                  'Upload a PDF above to get started.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.gray700,
                  ),
                ),
              ),
            )
          else
            ..._documents.map(_buildDocumentRow),
          if (_isLoadingDocs && _documents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(Map<String, dynamic> doc) {
    final status = doc['status'] as String? ?? 'unknown';
    final title = doc['title'] as String? ?? 'Untitled';
    final chunks = doc['chunks_created'] as int? ?? 0;
    final docId = doc['id'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.gray700.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            _StatusBadge(status: status),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == 'ingested' ? '$chunks chunks' : status,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.gray700,
                    ),
                  ),
                ],
              ),
            ),
            if (docId.isNotEmpty)
              IconButton(
                icon: Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: Colors.red.shade400,
                ),
                onPressed: () => _deleteDocument(docId),
                tooltip: 'Delete',
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDocument(String docId) async {
    final success =
        await ref.read(adminControllerProvider.notifier).deleteDocument(docId);
    if (success) {
      _showSnackBar('Document deleted.');
      await _loadDocuments();
    } else {
      _showSnackBar('Delete failed.');
    }
  }
}

class _FilePickerButton extends StatelessWidget {
  final String? fileName;
  final String? fileSize;
  final VoidCallback onPick;

  const _FilePickerButton({
    required this.onPick,
    this.fileName,
    this.fileSize,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasFile
                ? AppTheme.teal500
                : AppTheme.gray700.withValues(alpha: 0.3),
            width: hasFile ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: hasFile ? AppTheme.teal500.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFile ? LucideIcons.fileCheck : LucideIcons.file,
              color: hasFile ? AppTheme.teal500 : AppTheme.gray700,
            ),
            const SizedBox(width: 12),
            if (hasFile) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gray900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (fileSize != null)
                      Text(
                        fileSize!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.gray700,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                'Change',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.purple500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else
              Text(
                'Pick a PDF file (max 100 MB)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.gray700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case 'ingested':
        color = Colors.green;
        icon = LucideIcons.circleCheck;
      case 'processing':
        color = Colors.orange;
        icon = LucideIcons.loader;
      case 'pending':
        color = Colors.blue;
        icon = LucideIcons.clock;
      case 'failed':
        color = Colors.red;
        icon = LucideIcons.circleX;
      default:
        color = AppTheme.gray700;
        icon = LucideIcons.circleQuestionMark;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
