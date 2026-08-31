import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileapp/main.dart';

void main() {
  testWidgets('DukaApp builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DukaApp()),
    );
    await tester.pump();
    expect(find.byType(DukaApp), findsOneWidget);
  });
}
