import 'package:flutter_test/flutter_test.dart';

import 'package:asteroids_app/main.dart';

void main() {
  testWidgets('Asteroids game loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AsteroidsApp());

    expect(find.text('Score: 0'), findsOneWidget);
    expect(find.text('Controls: Arrow Keys to rotate/thrust, Space to fire'), findsOneWidget);
  });
}
