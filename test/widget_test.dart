import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rubik_solver/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: RubikSolverApp()));

    // Verify that the Rubik Solver app is successfully loaded.
    expect(find.byType(RubikSolverApp), findsOneWidget);
  });
}
