import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/features/settings/presentation/settings_screen.dart';
import 'package:frontend/core/constants/app_strings.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';
import 'package:frontend/features/admin/data/providers/admin_repository_provider.dart';
import 'package:frontend/core/providers/demo_mode_provider.dart';

class MockAdminRepository implements AdminRepository {
  @override
  Future<void> ingestDocument({
    required covariant fileBytes,
    required String filename,
    required String title,
    required String logicalBookId,
    String? author,
    String? edition,
  }) async {
    // success
  }

  @override
  Future<List<Map<String, dynamic>>> listDocuments() async {
    return [];
  }

  @override
  Future<void> deleteDocument(String documentId) async {}
}

class MockFilePicker extends FilePicker {
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    dynamic onFileLoading,
    bool allowCompression = true,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    int? compressionQuality,
  }) async {
    final bytes = File('/workspaces/cs698-repo/test_data/Meher Baba on Be True to Your Duty and Five Other Messages - Read Book.pdf').readAsBytesSync();
    return FilePickerResult([
      PlatformFile(
        name: 'Meher Baba on Be True to Your Duty and Five Other Messages - Read Book.pdf',
        size: bytes.length,
        bytes: bytes,
        path: '/workspaces/cs698-repo/test_data/Meher Baba on Be True to Your Duty and Five Other Messages - Read Book.pdf',
      )
    ]);
  }
}

void main() {
  testWidgets('Demo panel demo text fields have expected label text', (tester) async {
    FilePicker.platform = MockFilePicker();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isDemoModeProvider.overrideWithValue(true),
          adminRepositoryProvider.overrideWithValue(MockAdminRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final titleField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == AppStrings.demoPdfTitle,
      description: 'TextField with label ${AppStrings.demoPdfTitle}',
    );

    final authorField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == AppStrings.demoPdfAuthor,
      description: 'TextField with label ${AppStrings.demoPdfAuthor}',
    );

    final idField = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == AppStrings.demoPdfLogicalId,
      description: 'TextField with label ${AppStrings.demoPdfLogicalId}',
    );

    expect(titleField, findsOneWidget);
    expect(authorField, findsOneWidget);
    expect(idField, findsOneWidget);
  });

  testWidgets('Demo panel PDF upload test', (tester) async {
    FilePicker.platform = MockFilePicker();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isDemoModeProvider.overrideWithValue(true),
          adminRepositoryProvider.overrideWithValue(MockAdminRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    
    // Find the text fields
    final titleField = find.widgetWithText(TextField, 'PDF Title');
    final authorField = find.widgetWithText(TextField, 'Author');
    final idField = find.widgetWithText(TextField, 'Logical Book ID');
    
    expect(titleField, findsOneWidget);
    
    // Enter info
    await tester.enterText(titleField, 'Test Title');
    await tester.enterText(authorField, 'Test Author');
    await tester.enterText(idField, 'test_id_123');
    await tester.pumpAndSettle();
    
    // Tap "Select PDF"
    final selectBtn = find.widgetWithText(OutlinedButton, 'Select PDF');
    await tester.ensureVisible(selectBtn);
    await tester.tap(selectBtn);
    await tester.pumpAndSettle();
    
    // Tap "Upload Document"
    final uploadBtn = find.widgetWithText(ElevatedButton, 'Upload Document');
    await tester.ensureVisible(uploadBtn);
    await tester.tap(uploadBtn);
    await tester.pump(const Duration(milliseconds: 500)); // allow async op
    
    // check if it attempts to finish without null pointer
    debugPrint('If we reached here without a crash, the null byte issue is fixed!');
  });
}
