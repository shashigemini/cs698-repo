class MockAuthRepository {
  Future<String> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'mock_token_123';
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
