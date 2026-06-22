import 'package:flutter_test/flutter_test.dart';

import 'package:esda_mobile/features/shared/theme.dart';
import 'package:esda_mobile/main.dart';

void main() {
  testWidgets('App boots', (WidgetTester tester) async {
    await tester.pumpWidget(EsdaApp(theme: ThemeController()));
    expect(find.byType(EsdaApp), findsOneWidget);
  });
}
