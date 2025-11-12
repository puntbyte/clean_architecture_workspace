// test/helpers/debug_expect.dart
import 'package:test/test.dart';

/// Run an expect but print helpful debug info if it fails, then rethrow so the test still fails normally.
///
/// - [actual] and [matcher] are forwarded to `expect`.
/// - [context] is a short description string included in the test failure.
/// - [extrasProvider] is called only when the assertion fails and should return a map of diagnostic values.
void expectWithDebugLazy(
    Object? actual,
    Matcher matcher, {
      String? context,
      Map<String, Object?> Function()? extrasProvider,
    }) {
  try {
    expect(actual, matcher, reason: context);
  } catch (e) {
    print('--- EXPECT FAILED: ${context ?? ""}');
    print('Actual value: $actual');
    print('Matcher: $matcher');
    if (extrasProvider != null) {
      try {
        final extras = extrasProvider();
        if (extras.isNotEmpty) {
          print('Extra debug info:');
          extras.forEach((k, v) => print('  $k: $v'));
        }
      } catch (extraErr) {
        print('Error while computing extrasProvider: $extraErr');
      }
    }
    rethrow;
  }
}
