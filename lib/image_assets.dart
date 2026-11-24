import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

final class ImageAsset {
  const ImageAsset(this.path, this.width, this.height);

  final String path;
  final int width;
  final int height;

  double get aspectRatio => width / height;

  int decodeWidth(double logicalWidth, double devicePixelRatio) =>
      (logicalWidth * devicePixelRatio).ceil().clamp(1, width);
}

final class EncodedImage {
  const EncodedImage(this.asset, this.bytes);

  final ImageAsset asset;
  final Uint8List bytes;
}

class ImageAssetRepository {
  ImageAssetRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const catalogPath = 'asset/image_catalog.json';

  final AssetBundle _bundle;
  final _pending = <String, Future<EncodedImage>>{};
  Future<List<ImageAsset>>? _catalog;

  Future<List<ImageAsset>> loadCatalog() => _catalog ??= _readCatalog();

  Future<List<ImageAsset>> _readCatalog() async {
    try {
      final rows = jsonDecode(await _bundle.loadString(catalogPath)) as List;
      return List.unmodifiable([
        for (final row in rows.cast<List>())
          ImageAsset(row[0] as String, row[1] as int, row[2] as int),
      ]);
    } catch (_) {
      _catalog = null;
      rethrow;
    }
  }

  Future<List<ImageAsset>> loadRelated(ImageAsset selected) async {
    final catalog = await loadCatalog();
    final index = catalog.indexWhere((asset) => asset.path == selected.path);
    if (index == -1) return const [];

    return List.unmodifiable([
      for (var offset = 1; offset <= math.min(7, catalog.length - 1); offset++)
        catalog[(index + offset) % catalog.length],
    ]);
  }

  Future<EncodedImage> loadImage(ImageAsset asset) =>
      _pending.putIfAbsent(asset.path, () => _readImage(asset));

  Future<EncodedImage> _readImage(ImageAsset asset) async {
    try {
      final data = await _bundle.load(asset.path);
      return EncodedImage(
        asset,
        Uint8List.sublistView(data).asUnmodifiableView(),
      );
    } finally {
      _pending.remove(asset.path);
    }
  }
}
