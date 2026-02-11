import 'package:flutter_test/flutter_test.dart';
import 'package:distrohub_mobile/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // If MyApp builds without crashing, test passes
    expect(find.byType(MyApp), findsOneWidget);
  });
}
