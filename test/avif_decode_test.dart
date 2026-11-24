import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tangerine/avif_image.dart';
import 'package:tangerine/image_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses physical pixels and caps the decode at the source width', () {
    const asset = ImageAsset('asset/sample.avif', 420, 630);
    expect(asset.decodeWidth(190.1, 1), 191);
    expect(asset.decodeWidth(190.1, 2), 381);
    expect(asset.decodeWidth(190.1, 3), 420);
    expect(asset.decodeWidth(387, 1), 387);
  });

  test('decodes bundled portrait at the requested physical width', () async {
    final images = ImageAssetRepository(bundle: rootBundle);
    final catalog = await images.loadCatalog();
    expect(catalog, hasLength(134));
    final paths = catalog.map((asset) => asset.path).toList();
    expect(paths, orderedEquals([...paths]..sort()));
    final selected = catalog.last;
    final related = await images.loadRelated(selected);
    expect(related, catalog.take(7));

    final asset = catalog.firstWhere((asset) => asset.height > asset.width);
    final encoded = await images.loadImage(asset);
    final bitmap = await decodeAvif(encoded.bytes, 120);
    addTearDown(bitmap.dispose);
    expect(bitmap.width, 120);
    expect(bitmap.height, closeTo(120 / asset.aspectRatio, 1));
  });
}
