import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kapea_app/ui/screens/kapea_app.dart';

void main() {
  testWidgets('student app displays the Kapea home screen', (tester) async {
    await tester.pumpWidget(const KapeaApp());

    expect(find.text('K A P E A'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Scan Link'), findsOneWidget);
  });
}
