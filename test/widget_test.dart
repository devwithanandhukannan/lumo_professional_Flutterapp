import 'package:flutter_test/flutter_test.dart';
import 'package:pro_app/main.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LumoProApp());
    expect(find.byType(LumoProApp), findsOneWidget);
  });
}
