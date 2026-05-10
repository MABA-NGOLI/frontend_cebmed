import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_cebmed/main.dart';

void main() {
  testWidgets('shows welcome actions after splash', (WidgetTester tester) async {
    await tester.pumpWidget(const CebMedApp());

    expect(find.text('Se connecter'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text("S'inscrire"), findsOneWidget);
  });
}
