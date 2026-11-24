import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.router.dart';
import 'avif_image.dart';
import 'feed.screen.dart';
import 'image_assets.dart';
import 'image_feed.dart';
import 'page_transition.dart';
import 'single_display.controller.dart';

const _mediaInset = 2.0;
const _mediaBorderWidth = 1.0;
const _mediaRadius = 20.0;
const _mediaTopGap = 24.0;
const _heroBlend = Interval(.1, feedHeroMotionStart);
const _decodeBlendDuration = Duration(milliseconds: 80);

class SingleDisplayScreen extends StatelessWidget with WidgetWithRouterKey {
  const SingleDisplayScreen({
    super.key,
    required this.image,
    required this.thumbnailWidth,
    required this.sourceRect,
    required this.images,
    required this.decode,
  });

  final EncodedImage image;
  final int thumbnailWidth;
  final Rect sourceRect;
  final ImageAssetRepository images;
  final AvifDecoder decode;

  @override
  RouterKey get routerKey => RouterKey.singleDisplay;

  @override
  Widget build(BuildContext context) {
    final animation =
        ModalRoute.of(context)?.animation ?? const AlwaysStoppedAnimation(1.0);
    return BlocProvider(
      create: (_) =>
          SingleDisplayCubit(SingleDisplayRepository(images), image.asset)
            ..load(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final top = MediaQuery.paddingOf(context).top + _mediaTopGap;
          final width = (constraints.maxWidth - 2 * _mediaInset).clamp(
            0.0,
            double.infinity,
          );
          final contentWidth = (width - 2 * _mediaBorderWidth).clamp(
            0.0,
            double.infinity,
          );
          final height =
              contentWidth / image.asset.aspectRatio + 2 * _mediaBorderWidth;
          final targetMedia = Rect.fromLTWH(_mediaInset, top, width, height);
          final thumbnail = Image(
            image: FeedAvifImage(
              path: image.asset.path,
              bytes: image.bytes,
              pixelWidth: thumbnailWidth,
              decode: decode,
            ),
            fit: .fill,
            errorBuilder: (context, error, stack) => const SizedBox.expand(),
          );
          return UncachedAvifImage(
            bytes: image.bytes,
            pixelWidth: image.asset.decodeWidth(
              contentWidth,
              MediaQuery.devicePixelRatioOf(context),
            ),
            decode: decode,
            builder: (context, bitmap) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: bitmap == null ? 0 : 1),
              duration:
                  MediaQuery.disableAnimationsOf(context) ||
                      animation.value <= _heroBlend.begin
                  ? Duration.zero
                  : _decodeBlendDuration,
              child: bitmap == null
                  ? null
                  : RawImage(image: bitmap, fit: .fill),
              builder: (context, decodeOpacity, fullResolution) {
                final media = _HeroMedia(
                  thumbnail: thumbnail,
                  fullResolution: fullResolution,
                  opacity: animation
                      .drive(CurveTween(curve: _heroBlend))
                      .drive(Tween(begin: 0.0, end: decodeOpacity)),
                );
                return FeedToSingleTransition(
                  animation: animation,
                  sourceRect: sourceRect,
                  targetMedia: targetMedia,
                  media: media,
                  child: _SingleDisplayView(
                    animation: animation,
                    media: media,
                    mediaTop: top,
                    mediaHeight: height,
                    decode: decode,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HeroMedia extends StatelessWidget {
  const _HeroMedia({
    required this.thumbnail,
    required this.fullResolution,
    required this.opacity,
  });

  final Widget thumbnail;
  final Widget? fullResolution;
  final Animation<double> opacity;

  @override
  Widget build(BuildContext context) => Stack(
    fit: .expand,
    children: [
      thumbnail,
      if (fullResolution != null)
        FadeTransition(opacity: opacity, child: fullResolution),
    ],
  );
}

class _SingleDisplayView extends StatelessWidget {
  const _SingleDisplayView({
    required this.animation,
    required this.media,
    required this.mediaTop,
    required this.mediaHeight,
    required this.decode,
  });

  final Animation<double> animation;
  final Widget media;
  final double mediaTop;
  final double mediaHeight;
  final AvifDecoder decode;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              SizedBox(height: mediaTop),
              _MainMedia(
                animation: animation,
                height: mediaHeight,
                child: media,
              ),
              const SizedBox(height: 16),
              const _ItemActions(),
              const SizedBox(height: 13),
              const _Attribution(),
              const SizedBox(height: 51),
            ],
          ),
        ),
        BlocBuilder<SingleDisplayCubit, SingleDisplayState>(
          builder: (context, state) => switch (state) {
            SingleDisplayInitial() => const FeedLoading(),
            SingleDisplayLoading() => const FeedLoading(),
            SingleDisplayLoaded(:final items) => ImageFeedSliver(
              items: items,
              loadImage: context.read<SingleDisplayCubit>().loadImage,
              decode: decode,
            ),
            SingleDisplayError() => const SliverToBoxAdapter(
              child: SizedBox.shrink(),
            ),
          },
        ),
      ],
    ),
  );
}

class _MainMedia extends StatelessWidget {
  const _MainMedia({
    required this.animation,
    required this.height,
    required this.child,
  });

  final Animation<double> animation;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) => Opacity(
      key: const ValueKey('single-display-media-visibility'),
      opacity: animation.value == 1 ? 1 : 0,
      child: child,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: _mediaInset),
      child: SizedBox(
        key: const ValueKey('single-display-media'),
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          position: .foreground,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xff333333),
              width: _mediaBorderWidth,
            ),
            borderRadius: BorderRadius.circular(_mediaRadius),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_mediaRadius),
                  child: Padding(
                    padding: const EdgeInsets.all(_mediaBorderWidth),
                    child: child,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 6,
                child: Material(
                  color: const Color(0xff263d49),
                  shape: const CircleBorder(
                    side: BorderSide(color: Color(0xff476a7c)),
                  ),
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => AppRouter.of(context).popCurrent(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                ),
              ),
              const Positioned(
                right: 12,
                bottom: 12,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xff333438),
                  child: Icon(Icons.volume_off, size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ItemActions extends StatelessWidget {
  const _ItemActions();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 13),
    child: Row(
      children: [
        Icon(Icons.chat_bubble_outline, size: 24),
        SizedBox(width: 24),
        Icon(Icons.ios_share, size: 24),
        SizedBox(width: 24),
        Icon(Icons.more_horiz, size: 27),
        Spacer(),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Save',
                  style: TextStyle(color: Color(0xff171717), fontSize: 16),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xff333333),
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Attribution extends StatelessWidget {
  const _Attribution();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 13),
    child: Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: Color(0xff333333),
          child: CircleAvatar(radius: 12, backgroundColor: Color(0xff0a0a0a)),
        ),
        SizedBox(width: 12),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '@nuecodesigner',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: ' and 53 others',
                  style: TextStyle(color: Color(0xff888888)),
                ),
              ],
            ),
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}
