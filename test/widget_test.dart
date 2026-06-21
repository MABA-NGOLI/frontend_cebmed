import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_cebmed/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Splash Screen', () {
    testWidgets(
      'affiche la page d accueil apres le splash',
          (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          const CebMedApp(),
        );

        expect(
          find.text('Se connecter'),
          findsNothing,
        );

        await tester.pump(
          const Duration(seconds: 4),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Bienvenue sur'),
          findsOneWidget,
        );

        expect(
          find.text('Se connecter'),
          findsOneWidget,
        );

        expect(
          find.text("S'inscrire"),
          findsOneWidget,
        );
      },
    );
  });
}