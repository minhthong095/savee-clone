import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tangerine/avif_image.dart';

class FakeCompleter extends ImageStreamCompleter {}

void main() {
  testWidgets('resize keys reuse only identical decode requests', (
    tester,
  ) async {
    Future<Object> key(int size, {String path = 'asset/sample.avif'}) =>
        FeedAvifImage(
          path: path,
          bytes: Uint8List(0),
          pixelWidth: size,
          decode: decodeAvif,
        ).obtainKey(ImageConfiguration.empty);
    final small = await key(100);
    final large = await key(1000);
    final largeAgain = await key(1000);
    final smallAgain = await key(100);

    expect(largeAgain, large);
    expect(smallAgain, small);
    expect(small, isNot(large));
    expect(large, isNot(await key(1000, path: 'asset/other.avif')));

    // Exercise Flutter's actual cache in each direction. Completers stand in for
    // already-started image streams; no network or codec is needed here.
    for (final keys in [
      [small, large],
      [large, small],
      [large, largeAgain],
      [largeAgain, large],
    ]) {
      final cache = ImageCache();
      var starts = 0;
      ImageStreamCompleter load() {
        starts++;
        return FakeCompleter();
      }

      final first = cache.putIfAbsent(keys[0], load);
      final second = cache.putIfAbsent(keys[1], load);
      final matching = keys[0] == keys[1];
      expect(starts, matching ? 1 : 2);
      expect(identical(first, second), matching);
      cache.clear();
    }
  });
}
