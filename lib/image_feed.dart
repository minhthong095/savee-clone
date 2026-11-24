import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'avif_image.dart';
import 'image_assets.dart';

typedef OpenFeedImage = void Function(
  EncodedImage image,
  int thumbnailWidth,
  Rect sourceRect,
);

class ImageFeedSliver extends StatelessWidget {
  const ImageFeedSliver({
    super.key,
    required this.items,
    required this.loadImage,
    required this.decode,
    this.onOpen,
    this.hiddenPath,
    this.coverAnimation,
  });

  final List<ImageAsset> items;
  final Future<EncodedImage> Function(ImageAsset) loadImage;
  final AvifDecoder decode;
  final OpenFeedImage? onOpen;
  final String? hiddenPath;
  final Animation<double>? coverAnimation;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    sliver: SliverMasonryGrid.count(
      crossAxisCount: 2,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      childCount: items.length,
      itemBuilder: (context, index) {
        final asset = items[index];
        return _ImageTile(
          key: ValueKey(onOpen == null ? asset.path : 'feed-item-$index'),
          asset: asset,
          loadImage: loadImage,
          decode: decode,
          onOpen: onOpen,
          coverAnimation: asset.path == hiddenPath ? coverAnimation : null,
        );
      },
    ),
  );
}

class _ImageTile extends StatefulWidget {
  const _ImageTile({
    super.key,
    required this.asset,
    required this.loadImage,
    required this.decode,
    this.onOpen,
    this.coverAnimation,
  });

  final ImageAsset asset;
  final Future<EncodedImage> Function(ImageAsset) loadImage;
  final AvifDecoder decode;
  final OpenFeedImage? onOpen;
  final Animation<double>? coverAnimation;

  @override
  State<_ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends State<_ImageTile> {
  static const _borderWidth = .7;
  static const _borderRadius = BorderRadius.all(Radius.circular(6));

  late Future<EncodedImage> _encoded;

  @override
  void initState() {
    super.initState();
    _encoded = widget.loadImage(widget.asset);
  }

  @override
  void didUpdateWidget(_ImageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.path != widget.asset.path ||
        oldWidget.loadImage != widget.loadImage) {
      _encoded = widget.loadImage(widget.asset);
    }
  }

  void _open(EncodedImage image, int width) {
    final box = context.findRenderObject()! as RenderBox;
    final navigator = Navigator.of(context).context.findRenderObject();
    final origin = box.localToGlobal(Offset.zero, ancestor: navigator);
    widget.onOpen!(image, width, origin & box.size);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final contentWidth = (constraints.maxWidth - 2 * _borderWidth).clamp(
        0.0,
        double.infinity,
      );
      final pixelWidth = widget.asset.decodeWidth(
        contentWidth,
        MediaQuery.devicePixelRatioOf(context),
      );
      final tile = SizedBox(
        height: contentWidth / widget.asset.aspectRatio + 2 * _borderWidth,
        child: DecoratedBox(
          position: .foreground,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xff333333),
              width: _borderWidth,
            ),
            borderRadius: _borderRadius,
          ),
          child: ClipRRect(
            borderRadius: _borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(_borderWidth),
              child: FutureBuilder<EncodedImage>(
                future: _encoded,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != .done || !snapshot.hasData) {
                    return const SizedBox.expand();
                  }
                  final image = snapshot.data!;
                  if (widget.onOpen == null) {
                    return UncachedAvifImage(
                      bytes: image.bytes,
                      pixelWidth: pixelWidth,
                      decode: widget.decode,
                      builder: (context, bitmap) =>
                          RawImage(image: bitmap, fit: .fill),
                    );
                  }
                  return Image(
                    image: FeedAvifImage(
                      path: image.asset.path,
                      bytes: image.bytes,
                      pixelWidth: pixelWidth,
                      decode: widget.decode,
                    ),
                    fit: .fill,
                    frameBuilder: (context, child, frame, _) => InkWell(
                      onTap: frame == null
                          ? null
                          : () => _open(image, pixelWidth),
                      child: child,
                    ),
                    errorBuilder: (context, error, stack) =>
                        const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
        ),
      );
      if (widget.onOpen == null) return tile;

      final cover = widget.coverAnimation ?? const AlwaysStoppedAnimation(0.0);
      return AnimatedBuilder(
        animation: cover,
        child: tile,
        builder: (context, child) => IgnorePointer(
          ignoring: cover.value > 0,
          child: Opacity(opacity: cover.value == 0 ? 1 : 0, child: child),
        ),
      );
    },
  );
}
