import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/admin/application/admin_controller.dart';
import 'package:frontend/features/admin/domain/repositories/admin_repository.dart';
import 'package:frontend/features/admin/data/providers/admin_repository_provider.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository mockAdminRepo;
  late ProviderContainer container;

  setUp(() {
    mockAdminRepo = MockAdminRepository();
    container = ProviderContainer(
      overrides: [
        adminRepositoryProvider.overrideWithValue(mockAdminRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AdminController', () {
    test('initial state is not loading', () {
      final state = container.read(adminControllerProvider);
      expect(state.isLoading, false);
    });



    test('ingestDocument success', () async {
      final fileBytes = Uint8List.fromList([1, 2, 3]);
      when(() => mockAdminRepo.ingestDocument(
            fileBytes: fileBytes,
            filename: 'test.pdf',
            title: 'Test',
            logicalBookId: 'L001',
          )).thenAnswer((_) async => true);

      final result = await container
          .read(adminControllerProvider.notifier)
          .ingestDocument(
            fileBytes: fileBytes,
            filename: 'test.pdf',
            title: 'Test',
            logicalBookId: 'L001',
          );

      expect(result, true);
      verify(() => mockAdminRepo.ingestDocument(
            fileBytes: fileBytes,
            filename: 'test.pdf',
            title: 'Test',
            logicalBookId: 'L001',
          )).called(1);
    });
  });
}
