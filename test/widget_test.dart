import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flow_tomato/main.dart';

void main() {
  void setDesktopSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('FlowTomato opens to the workbench sections', (
    WidgetTester tester,
  ) async {
    setDesktopSurface(tester);
    await tester.pumpWidget(const FlowTomatoApp(promptForNocoDBOnStart: false));

    expect(find.text('FlowTomato'), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Todo'), findsOneWidget);
    expect(find.text('Done'), findsWidgets);
    expect(find.text('Pomodoro'), findsOneWidget);
    expect(find.text('Connect NocoDB'), findsOneWidget);
  });

  testWidgets('NocoDB settings accepts local development configuration', (
    WidgetTester tester,
  ) async {
    setDesktopSurface(tester);
    await tester.pumpWidget(const FlowTomatoApp(promptForNocoDBOnStart: false));

    await tester.tap(find.text('Connect NocoDB'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('nocodbBaseUrl')),
      'http://127.0.0.1:8080',
    );
    await tester.enterText(
      find.byKey(const Key('nocodbApiToken')),
      'nc_pat_test',
    );

    expect(find.text('NocoDB app connection'), findsOneWidget);
    expect(find.text('Find NocoDB workspace'), findsOneWidget);
    expect(find.textContaining('Personal access token'), findsOneWidget);
  });

  testWidgets('setting a todo task as now updates the Now section', (
    WidgetTester tester,
  ) async {
    setDesktopSurface(tester);
    await tester.pumpWidget(const FlowTomatoApp(promptForNocoDBOnStart: false));

    await tester.tap(find.text('Focus').first);
    await tester.pump();

    expect(find.text('正在做'), findsOneWidget);
    expect(find.text('Implement Flutter shell'), findsWidgets);
  });

  testWidgets(
    'narrow layout uses one vertical scroll container after adding tasks',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(700, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const FlowTomatoApp(promptForNocoDBOnStart: false),
      );

      await tester.ensureVisible(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'New task');
      await tester.tap(find.byTooltip('Add task'));
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    },
  );
}
