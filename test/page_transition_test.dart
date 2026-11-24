import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tangerine/page_transition.dart';
import 'package:tangerine/single_display.screen.dart';

import 'image_fixture.dart';

void main() {
  testWidgets('sheet closes both gaps while expanding in sync with the hero', (
    tester,
  ) async {
    const size = Size(393, 852);
    const targetMedia = Rect.fromLTWH(2, 24, 389, 219);
    final sheetFinder = find.byKey(const ValueKey('transition-sheet'));
    final heroFinder = find.byKey(const ValueKey('transition-hero-media'));
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final animation = AnimationController(
      vsync: tester,
      duration: feedTransitionDuration,
    );
    addTearDown(animation.dispose);

    for (final source in [
      const Rect.fromLTWH(2, 80, 190, 238),
      const Rect.fromLTWH(200, 600, 190, 238),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: FeedToSingleTransition(
            animation: animation,
            sourceRect: source,
            targetMedia: targetMedia,
            media: const SizedBox.expand(),
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      );
      var previousGap = size.height;
      for (final elapsed in [0.0, .1, .2, .25, .35, .5, .75, .9, 1.0]) {
        animation.value = elapsed;
        await tester.pump();
        final sheet = tester.getRect(sheetFinder);
        final hero = tester.getRect(heroFinder);
        final sheetExpansion =
            (sheet.height - source.height) / (size.height - source.height);
        final heroExpansion =
            (hero.width - source.width) / (targetMedia.width - source.width);
        expect(sheetExpansion, closeTo(heroExpansion, .0001));
        if (elapsed <= .2) {
          expect(sheetExpansion, 0);
          expect(hero, source);
        } else if (elapsed == 1) {
          expect(sheet, Offset.zero & size);
          expect(hero, targetMedia);
        } else {
          expect(sheetExpansion, inExclusiveRange(0, 1));
        }
        final topGap = sheet.top;
        final bottomGap = size.height - sheet.bottom;
        expect(
          topGap,
          closeTo(bottomGap, .01),
          reason: '$source at $elapsed progress',
        );
        expect(
          topGap,
          lessThanOrEqualTo(previousGap),
          reason: '$source at $elapsed progress',
        );
        previousGap = topGap;
      }
      animation.value = 0;
      await tester.pump();
    }
  });

  testWidgets('blends in place and hands the image back to the scrolled tile', (
    tester,
  ) async {
    final fixture = ImageFixture();
    await fixture.pumpFeed(tester);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('feed-item-2'));
    final tileRect = tester.getRect(tile);
    final moving = find.byKey(const ValueKey('transition-hero-media'));
    final hero = find.byKey(const ValueKey('single-display-media'));
    final settledVisibility = find.byKey(
      const ValueKey('single-display-media-visibility'),
    );
    final sheet = find.byKey(const ValueKey('transition-sheet'));
    final tileImage = find.descendant(of: tile, matching: find.byType(Image));
    final originalThumbnail = tester.element(tileImage);

    double imageOpacity(Finder owner) => tester
        .widget<Opacity>(
          find.descendant(of: owner, matching: find.byType(Opacity)).first,
        )
        .opacity;
    double blendOpacity() => tester
        .widget<FadeTransition>(
          find.descendant(of: moving, matching: find.byType(FadeTransition)),
        )
        .opacity
        .value;

    final tenth = feedTransitionDuration * .1;
    final twentieth = feedTransitionDuration * .05;
    await tester.tap(tile);
    await tester.pump();
    await tester.pump();
    expect(imageOpacity(tile), 1);
    expect(imageOpacity(moving), 0);

    await tester.pump(tenth);
    expect(tester.getRect(moving), tileRect);
    expect(imageOpacity(tile), 0);
    expect(imageOpacity(moving), 1);
    expect(imageOpacity(sheet), 0);
    expect(blendOpacity(), closeTo(0, .001));

    await tester.pump(twentieth);
    expect(tester.getRect(moving), tileRect);
    expect(imageOpacity(moving), 1);
    expect(blendOpacity(), closeTo(.5, .001));

    await tester.pump(twentieth);
    expect(tester.getRect(moving), tileRect);
    expect(blendOpacity(), closeTo(1, .001));

    await tester.pump(tenth);
    expect(imageOpacity(sheet), greaterThan(0));
    expect(tester.getSize(sheet).width, greaterThan(tileRect.width));
    expect(tester.getSize(moving).width, greaterThan(tileRect.width));
    expect(imageOpacity(moving), 1);
    expect(tester.widget<Opacity>(settledVisibility).opacity, 0);

    await tester.pump(feedTransitionDuration);
    expect(find.byType(SingleDisplayScreen), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(tester.getRect(moving), tester.getRect(hero));
    expect(imageOpacity(moving), 0);
    expect(tester.widget<Opacity>(settledVisibility).opacity, 1);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(feedTransitionDuration * .8);
    expect(find.byType(SingleDisplayScreen), findsOneWidget);
    expect(tester.getRect(moving), tileRect);
    expect(imageOpacity(moving), 1);
    expect(imageOpacity(tile), 0);
    expect(blendOpacity(), closeTo(1, .001));

    await tester.pump(twentieth);
    expect(tester.getRect(moving), tileRect);
    expect(imageOpacity(moving), 1);
    expect(blendOpacity(), closeTo(.5, .001));

    await tester.pumpAndSettle();
    expect(find.byType(SingleDisplayScreen), findsNothing);
    expect(tester.getRect(tile), tileRect);
    expect(imageOpacity(tile), 1);
    expect(tester.element(tileImage), same(originalThumbnail));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('late decode blends over the same preview through landing', (
    tester,
  ) async {
    final fixture = _DelayedHeroFixture();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    await fixture.pumpFeed(tester);
    final moving = find.byKey(const ValueKey('transition-hero-media'));
    final settled = find.byKey(const ValueKey('single-display-media'));
    final preview = find.descendant(of: moving, matching: find.byType(Image));
    Finder blend(Finder owner) =>
        find.descendant(of: owner, matching: find.byType(FadeTransition));

    await tester.tap(find.byKey(const ValueKey('feed-item-0')));
    await tester.pump();
    await tester.pump(
      feedTransitionDuration - const Duration(milliseconds: 30),
    );
    final previewElement = tester.element(preview);
    expect(
      tester
          .widget<RawImage>(
            find.descendant(of: preview, matching: find.byType(RawImage)),
          )
          .image,
      isNotNull,
    );
    expect(blend(moving), findsNothing);

    fixture.allowHero.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 15));
    expect(tester.element(preview), same(previewElement));
    final inFlightOpacity = tester
        .widget<FadeTransition>(blend(moving))
        .opacity;
    expect(inFlightOpacity.value, inExclusiveRange(0, 1));
    expect(
      tester.widget<FadeTransition>(blend(settled)).opacity,
      same(inFlightOpacity),
    );

    await tester.pump(const Duration(milliseconds: 20));
    expect(
      tester.widget<FadeTransition>(blend(settled)).opacity.value,
      inExclusiveRange(inFlightOpacity.value, 1),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(tester.widget<FadeTransition>(blend(settled)).opacity.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion opens and closes without a timed transition', (
    tester,
  ) async {
    final fixture = ImageFixture();
    await fixture.pumpFeed(
      tester,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('feed-item-0')));
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(SingleDisplayScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}

class _DelayedHeroFixture extends ImageFixture {
  final allowHero = Completer<void>();

  @override
  Future<ui.Image> decode(Uint8List bytes, int width) async {
    if (bytes.first == 0 && width > 200) await allowHero.future;
    return super.decode(bytes, width);
  }
}
