import 'package:flutter_test/flutter_test.dart';

class E2ETestUtils {
  static Future<void> waitFor(WidgetTester tester, Finder finder, {int timeoutSeconds = 10}) async {
    var seconds = 0;
    while (tester.any(finder) == false && seconds < timeoutSeconds) {
      await tester.pump(const Duration(seconds: 1));
      seconds++;
    }
    if (seconds >= timeoutSeconds) {
      throw TestFailure('Timed out waiting for finder: \$finder');
    }
  }
}
