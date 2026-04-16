// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:cryptography/cryptography.dart';

void main() async {
  final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final password = 'test';
  final salt = List<int>.generate(16, (i) => i);
  
  final key = await hkdf.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    info: salt,
  );
  
  final bytes = await key.extractBytes();
  print('HKDF: ${base64Url.encode(bytes)}');
}
