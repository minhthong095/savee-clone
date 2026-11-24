import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tangerine/feed.screen.dart';

Finder get loadingCards => find.byWidgetPredicate(
  (widget) =>
      widget is DecoratedBox &&
      widget.decoration is BoxDecoration &&
      (widget.decoration as BoxDecoration).gradient is LinearGradient &&
      ((widget.decoration as BoxDecoration).gradient! as LinearGradient)
              .colors
              .length ==
          11,
);

List<LinearGradient> gradients(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(loadingCards)
    .map(
      (widget) =>
          (widget.decoration as BoxDecoration).gradient! as LinearGradient,
    )
    .toList();

void main() {
  testWidgets('loading gradient moves in sync without moving the cards', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FeedScreen()));
    await tester.pump();

    final initial = gradients(tester);
    expect(initial, hasLength(7));
    expect(initial.toSet(), hasLength(1));
    expect(initial.first.begin, Alignment.centerLeft);
    expect(initial.first.end, Alignment.centerRight);
    expect(initial.first.colors.first, const Color(0xff252525));
    expect(initial.first.colors.last, const Color(0xff1d1d1d));
    final bounds = loadingCards.evaluate().map((element) {
      final box = element.renderObject! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    }).toList();

    // Frame 34: the highlight has crossed to the right edge.
    await tester.pump(const Duration(milliseconds: 435));
    final moved = gradients(tester);
    expect(moved.toSet(), hasLength(1));
    expect(moved.first.colors.first.toARGB32(), 0xff1d1d1d);
    expect(moved.first.colors.last.toARGB32(), 0xff262626);
    expect(
      loadingCards.evaluate().map((element) {
        final box = element.renderObject! as RenderBox;
        return box.localToGlobal(Offset.zero) & box.size;
      }).toList(),
      bounds,
    );

    // The highlight leaves the cards before the next sweep.
    await tester.pump(const Duration(milliseconds: 505));
    expect(
      gradients(tester).first.colors.map((color) => color.toARGB32()).toSet(),
      {0xff1d1d1d},
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      gradients(tester).first.colors.map((color) => color.toARGB32()),
      initial.first.colors.map((color) => color.toARGB32()),
    );

    // Removing loading cards disposes the animation's ticker.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading gradient respects reduced motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: FeedScreen(),
        ),
      ),
    );
    final initial = gradients(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(gradients(tester), initial);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
