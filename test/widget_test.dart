import 'package:flutter_test/flutter_test.dart';

import 'package:medoc_claims/main.dart';

void main() {
  testWidgets('Dashboard loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ClaimApp());

    expect(find.text('Insurance Claim Dashboard'), findsOneWidget);
    expect(find.text('No claims yet'), findsOneWidget);
  });
}
