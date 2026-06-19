import 'package:flutter_test/flutter_test.dart';

import 'package:esda_mobile/main.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(const EsdaApp());
    expect(find.byType(EsdaApp), findsOneWidget);
  });
}
