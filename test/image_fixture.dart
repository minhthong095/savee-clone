import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tangerine/app.router.dart';
import 'package:tangerine/image_assets.dart';

class ImageTestBundle extends CachingAssetBundle {
  static const heights = [420, 630, 280, 500, 420, 560, 470, 440, 420, 500];
  static String path(int index) => 'asset/test-$index.avif';

  final reads = <String, int>{};

  @override
  Future<ByteData> load(String key) async {
    reads.update(key, (value) => value + 1, ifAbsent: () => 1);
    if (key == ImageAssetRepository.catalogPath) {
      return ByteData.sublistView(
        utf8.encode(
          jsonEncode([
            for (var i = 0; i < heights.length; i++) [path(i), 420, heights[i]],
          ]),
        ),
      );
    }
    for (var i = 0; i < heights.length; i++) {
      if (key == path(i)) return ByteData.sublistView(Uint8List.fromList([i]));
    }
    throw StateError('Missing test asset $key');
  }
}

class ImageFixture {
  final bundle = ImageTestBundle();
  final requests = <({Uint8List bytes, int width, ui.Image bitmap})>[];

  late final router = AppRouter(
    images: ImageAssetRepository(bundle: bundle),
    decode: decode,
  );

  Future<ui.Image> decode(Uint8List bytes, int width) async {
    final height = (width * ImageTestBundle.heights[bytes.first] / 420).round();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(Colors.blue, .src);
    final picture = recorder.endRecording();
    try {
      final bitmap = picture.toImageSync(width, height);
      requests.add((bytes: bytes, width: width, bitmap: bitmap));
      return bitmap;
    } finally {
      picture.dispose();
    }
  }

  Widget app({TransitionBuilder? builder}) => MaterialApp.router(
    routerDelegate: router,
    backButtonDispatcher: RootBackButtonDispatcher(),
    theme: ThemeData.dark(),
    builder: builder,
  );

  Future<void> pumpFeed(
    WidgetTester tester, {
    TransitionBuilder? builder,
  }) async {
    addTearDown(router.dispose);
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(builder: builder));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }
}
