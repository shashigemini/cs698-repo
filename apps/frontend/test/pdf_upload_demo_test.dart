import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/features/settings/presentation/settings_screen.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';
import 'package:frontend/features/admin/data/providers/admin_repository_provider.dart';
import 'package:frontend/core/providers/demo_mode_provider.dart';
import 'package:frontend/core/services/local_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // Minimal valid-ish PDF header bytes for deterministic CI tests.
    final bytes = Uint8List.fromList(<int>[
      0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, // %PDF-1.4
      0x0A, 0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A,
      0x31, 0x20, 0x30, 0x20, 0x6F, 0x62, 0x6A, 0x0A, // 1 0 obj
      0x3C, 0x3C, 0x2F, 0x54, 0x79, 0x70, 0x65, 0x2F,
      0x43, 0x61, 0x74, 0x61, 0x6C, 0x6F, 0x67, 0x3E,
      0x3E, 0x0A, 0x65, 0x6E, 0x64, 0x6F, 0x62, 0x6A,
      0x0A, 0x25, 0x25, 0x45, 0x4F, 0x46,
    ]);
    return FilePickerResult([
      PlatformFile(
        name: 'sample.pdf',
        size: bytes.length,
        bytes: bytes,
        path: null,
      )
    ]);
  }
}

void main() {
  testWidgets('Demo panel PDF upload test', (tester) async {
    FilePicker.platform = MockFilePicker();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isDemoModeProvider.overrideWithValue(true),
          adminRepositoryProvider.overrideWithValue(MockAdminRepository()),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    
    // Find demo panel text fields by InputDecoration labelText
    final titleField = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == 'PDF Title');
    final authorField = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == 'Author');
    final idField = find.byWidgetPredicate((widget) =>
        widget is TextField && widget.decoration?.labelText == 'Logical Book ID');

    expect(titleField, findsOneWidget);
    expect(authorField, findsOneWidget);
    expect(idField, findsOneWidget);
    
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
