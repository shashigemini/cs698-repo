import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/recovery_service.dart';

void main() {
  late RecoveryService recoveryService;

  setUp(() {
    recoveryService = RecoveryService();
  });

  group('RecoveryService', () {
    test('generateRecoveryKey returns a 128-bit key', () async {
      final key = await recoveryService.generateRecoveryKey();
      final bytes = await key.extractBytes();
      expect(bytes.length, 16);
    });

    test('keyToMnemonic produces 16 words for 128-bit key', () async {
      final keyBytes = List<int>.generate(16, (i) => i);
      final mnemonic = recoveryService.keyToMnemonic(keyBytes);
      final words = mnemonic.split(' ');
      expect(words.length, 16);
    });

    test('mnemonicToKey recovers original bytes (round-trip)', () async {
      final originalBytes = List<int>.generate(16, (i) => i * 13 % 256);
      final mnemonic = recoveryService.keyToMnemonic(originalBytes);
      final recoveredBytes = recoveryService.mnemonicToKey(mnemonic);
      expect(recoveredBytes, originalBytes);
    });

    test('case-insensitivity of mnemonicToKey', () async {
      final originalBytes = [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
      ];
      final mnemonic = recoveryService.keyToMnemonic(originalBytes);
      final upperMnemonic = mnemonic.toUpperCase();
      final recoveredBytes = recoveryService.mnemonicToKey(upperMnemonic);
      expect(recoveredBytes, originalBytes);
    });

    test('invalid mnemonic length throws FormatException', () {
      expect(
        () => recoveryService.mnemonicToKey('word1 word2'),
        throwsFormatException,
      );
    });

    test('invalid words in mnemonic throws FormatException', () {
      final invalidMnemonic = List.filled(16, 'invalidword').join(' ');
      expect(
        () => recoveryService.mnemonicToKey(invalidMnemonic),
        throwsFormatException,
      );
    });
  });
}
