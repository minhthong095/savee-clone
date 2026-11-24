import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:libavif/libavif.dart';

typedef AvifDecoder = Future<ui.Image> Function(
  Uint8List bytes,
  int pixelWidth,
);

Future<ui.Image> decodeAvif(Uint8List bytes, int pixelWidth) async {
  final frame = await Avif.decode(
    bytes,
    targetWidth: pixelWidth,
    options: const AvifDecodeOptions(maxThreads: 1),
  );
  final buffer = await ui.ImmutableBuffer.fromUint8List(frame.pixels);
  try {
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: frame.width,
      height: frame.height,
      rowBytes: frame.rowBytes,
      pixelFormat: .rgba8888,
    );
    try {
      final codec = await descriptor.instantiateCodec();
      try {
        return (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    } finally {
      descriptor.dispose();
    }
  } finally {
    buffer.dispose();
  }
}

typedef FeedAvifKey = ({String path, int pixelWidth});

final class FeedAvifImage extends ImageProvider<FeedAvifKey> {
  const FeedAvifImage({
    required this.path,
    required this.bytes,
    required this.pixelWidth,
    required this.decode,
  });

  final String path;
  final Uint8List bytes;
  final int pixelWidth;
  final AvifDecoder decode;

  @override
  Future<FeedAvifKey> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture((path: path, pixelWidth: pixelWidth));

  @override
  ImageStreamCompleter loadImage(
    FeedAvifKey key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(_load(key));

  Future<ImageInfo> _load(FeedAvifKey key) async =>
      ImageInfo(image: await decode(bytes, key.pixelWidth));

  @override
  bool operator ==(Object other) =>
      other is FeedAvifImage &&
      other.path == path &&
      other.pixelWidth == pixelWidth &&
      identical(other.bytes, bytes) &&
      other.decode == decode;

  @override
  int get hashCode =>
      Object.hash(path, pixelWidth, identityHashCode(bytes), decode);
}

class UncachedAvifImage extends StatefulWidget {
  const UncachedAvifImage({
    super.key,
    required this.bytes,
    required this.pixelWidth,
    required this.decode,
    required this.builder,
  });

  final Uint8List bytes;
  final int pixelWidth;
  final AvifDecoder decode;
  final Widget Function(BuildContext context, ui.Image? image) builder;

  @override
  State<UncachedAvifImage> createState() => _UncachedAvifImageState();
}

class _UncachedAvifImageState extends State<UncachedAvifImage> {
  late Future<ui.Image> _pending;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(UncachedAvifImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes) ||
        oldWidget.pixelWidth != widget.pixelWidth ||
        oldWidget.decode != widget.decode) {
      _image?.dispose();
      _image = null;
      _load();
    }
  }

  void _load() {
    final pending = _pending = Future.sync(
      () => widget.decode(widget.bytes, widget.pixelWidth),
    );
    unawaited(
      pending.then(
        (image) {
          if (!mounted || !identical(_pending, pending)) {
            image.dispose();
            return;
          }
          setState(() => _image = image);
        },
        onError: (Object error, StackTrace stack) {
          // The caller's placeholder or thumbnail stays visible on failure.
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _image);

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }
}
