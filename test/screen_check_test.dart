import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tangerine/main.dart';

void main() {
  testWidgets('discovery screen lays out and supports category selection', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const DiscoveryApp());
    expect(find.text('Trending users'), findsOneWidget);
    expect(find.text('Interface Design'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Interface Design'), findsOneWidget);
    expect(find.text('@djshiflet'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('@djshiflet'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Popular'), findsOneWidget);
    final popular = find
        .ancestor(of: find.text('Popular'), matching: find.byType(InkWell))
        .first;
    final interfaceDesign = find
        .ancestor(
          of: find.text('Interface Design'),
          matching: find.byType(InkWell),
        )
        .first;
    final gap =
        tester.getTopLeft(interfaceDesign).dx - tester.getTopRight(popular).dx;
    expect(gap, 6);
    expect(gap * tester.view.devicePixelRatio, 18);

    await tester.tap(find.text('Interface Design'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
