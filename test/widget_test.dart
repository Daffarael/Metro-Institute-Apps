import 'package:flutter_test/flutter_test.dart';
import 'package:metro_institute_app/app.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MetroInstituteApp());
    expect(find.byType(MetroInstituteApp), findsOneWidget);
  });
}
