import 'package:campusx/app/app.dart';
import 'package:campusx/core/app_state.dart';
import 'package:campusx/core/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CampusX boots into the splash experience', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialCampusStateProvider.overrideWithValue(CampusState.initial())],
        child: const CampusXApp(),
      ),
    );

    expect(find.text('CampusX'), findsOneWidget);
    expect(find.text('Everything campus. One app.'), findsOneWidget);
  });
}
