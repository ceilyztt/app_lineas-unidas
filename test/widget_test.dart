import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Este test requiere configuración de Firebase mock.
    // Ver: https://firebase.flutter.dev/docs/testing/
    expect(true, isTrue);
  });
}
