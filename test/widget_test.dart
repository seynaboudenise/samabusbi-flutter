// Test de démarrage de l'application SAMA BUS BI.

import 'package:flutter_test/flutter_test.dart';
import 'package:sama_bus_app/main.dart';

void main() {
  testWidgets('SAMA BUS BI démarre correctement', (WidgetTester tester) async {
    await tester.pumpWidget(const SamaBusApp());

    await tester.pumpAndSettle();

    expect(find.byType(SamaBusApp), findsOneWidget);
  });
}
