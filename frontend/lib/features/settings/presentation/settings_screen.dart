import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/core/constants/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: ListView(
        children: [
          const ListTile(title: Text('Profile')),
          const Divider(),
          const _DemoAdminPanel(),
        ],
      ),
    );
  }
}

class _DemoAdminPanel extends StatelessWidget {
  const _DemoAdminPanel();

  Future<void> _pickAndUploadPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      debugPrint('Uploading PDF: \${file.path}');
      // In demo mode, we just show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF Uploaded Successfully (Demo)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Admin Panel (Demo)', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () => _pickAndUploadPdf(context),
          child: const Text('Upload PDF Knowledge Base'),
        ),
      ],
    );
  }
}
