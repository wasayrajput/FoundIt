import 'package:flutter_test/flutter_test.dart';
import 'package:foundit/main.dart';

void main() {
  testWidgets('FounditApp loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FounditApp());
    expect(find.byType(FounditApp), findsOneWidget);
  });
}
