class MockChatRepository {
  Future<String> sendMessage(String message) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'This is a mock response about spiritual wisdom.';
  }
}
