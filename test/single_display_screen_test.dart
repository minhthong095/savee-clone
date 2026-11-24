import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tangerine/feed.screen.dart';
import 'package:tangerine/single_display.screen.dart';

import 'image_fixture.dart';

void main() {
  testWidgets('opens the selected image and loads an uncached related feed', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = ImageFixture();
    await fixture.pumpFeed(tester);

    final firstTile = find.byKey(const ValueKey('feed-item-0'));
    final secondTile = find.byKey(const ValueKey('feed-item-1'));
    final firstSize = tester.getSize(firstTile);
    final secondSize = tester.getSize(secondTile);
    expect(firstSize.width, closeTo(191.5, .01));
    expect(secondSize.width, firstSize.width);
    expect(
      secondSize.height - 1.4,
      closeTo((secondSize.width - 1.4) * 1.5, .01),
    );

    final cache = PaintingBinding.instance.imageCache;
    final initialCacheSize = cache.currentSize;
    final thumbnail = fixture.requests.singleWhere(
      (request) => request.bytes.first == 0,
    );
    expect(thumbnail.width, 381);

    await tester.tap(firstTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SingleDisplayScreen), findsOneWidget);
    expect(
      find.textContaining('@nuecodesigner', findRichText: true),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(FeedLoading), findsNothing);
    final hero = find.byKey(const ValueKey('single-display-media'));
    expect(tester.getSize(hero), const Size(389, 389));
    final detail = fixture.requests.singleWhere(
      (request) => request.bytes.first == 0 && request.width == 420,
    );
    expect(detail.bytes, same(thumbnail.bytes));
    expect(fixture.bundle.reads[ImageTestBundle.path(0)], 1);
    final relatedA = find.byKey(ValueKey(ImageTestBundle.path(1)));
    final relatedB = find.byKey(ValueKey(ImageTestBundle.path(2)));
    expect(tester.getSize(relatedA).width, firstSize.width);
    expect(tester.getSize(relatedB).width, firstSize.width);
    expect(cache.currentSize, initialCacheSize);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(SingleDisplayScreen), findsNothing);
    expect(detail.bitmap.debugDisposed, isTrue);
    expect(cache.currentSize, initialCacheSize);
  });
}
