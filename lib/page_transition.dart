import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

const feedTransitionDuration = Duration(milliseconds: 600);
const feedHeroMotionStart = .2;

// Change this curve to tune the movement of the Feed, sheet, and hero.
const Curve feedTransitionCurve = Curves.easeOutQuad;

double feedTransitionProgress(double value) =>
    feedTransitionCurve.transform(value).clamp(0.0, 1.0);

const _boardWidth = 1180.0;
const _boardHeight = 2556.0;
const _source = Rect.fromLTWH(599, 201, 575, 323);

class _Shape {
  const _Shape(this.rect, this.radius, this.opacity);
  final Rect rect;
  final double radius;
  final double opacity;

  static _Shape lerp(_Shape a, _Shape b, double t) => _Shape(
    Rect.lerp(a.rect, b.rect, t)!,
    lerpDouble(a.radius, b.radius, t)!,
    lerpDouble(a.opacity, b.opacity, t)!,
  );
}

class _Frame {
  const _Frame(this.ms, this.feed, this.sheet);
  final double ms;
  final _Shape feed;
  final _Shape sheet;
}

const _frames = <_Frame>[
  _Frame(
    0,
    _Shape(Rect.fromLTWH(0, 0, 1180, 2556), 0, 1),
    _Shape(_source, 18, 0),
  ),
  _Frame(
    66.7,
    _Shape(Rect.fromLTWH(15, 31, 1150.5, 2492.1), 0, .93),
    _Shape(Rect.fromLTWH(433, 242, 744, 745), 27, .18),
  ),
  _Frame(
    100,
    _Shape(Rect.fromLTWH(26, 56, 1128.08, 2443.536), 0, .93),
    _Shape(Rect.fromLTWH(300, 221, 878, 1192), 65, .83),
  ),
  _Frame(
    133.3,
    _Shape(Rect.fromLTWH(35, 75, 1110.38, 2405.196), 0, .93),
    _Shape(Rect.fromLTWH(199, 174, 979, 1601), 97, 1),
  ),
  _Frame(
    166.7,
    _Shape(Rect.fromLTWH(44, 94, 1092.68, 2366.856), 0, .93),
    _Shape(Rect.fromLTWH(101, 101, 1078, 2047), 139, 1),
  ),
  _Frame(
    200,
    _Shape(Rect.fromLTWH(46, 98, 1087.96, 2356.632), 0, .93),
    _Shape(Rect.fromLTWH(79, 82, 1100, 2150), 144, 1),
  ),
  _Frame(
    233.3,
    _Shape(Rect.fromLTWH(48, 100, 1084.42, 2348.964), 0, .93),
    _Shape(Rect.fromLTWH(49, 51, 1131, 2305), 153, 1),
  ),
  _Frame(
    266.7,
    _Shape(Rect.fromLTWH(48, 101, 1084.42, 2348.964), 0, .93),
    _Shape(Rect.fromLTWH(30, 32, 1150, 2402), 160, 1),
  ),
];

_Shape _sample(double ms, _Shape Function(_Frame) select) {
  for (var i = 1; i < _frames.length; i++) {
    if (ms <= _frames[i].ms) {
      final a = _frames[i - 1];
      final b = _frames[i];
      return _Shape.lerp(select(a), select(b), (ms - a.ms) / (b.ms - a.ms));
    }
  }
  return select(_frames.last);
}

class FeedRetreat extends StatelessWidget {
  const FeedRetreat({super.key, required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final feed = _sample(
        feedTransitionProgress(animation.value) * 333.333,
        (f) => f.feed,
      );
      final top = MediaQuery.paddingOf(context).top;
      return LayoutBuilder(
        builder: (context, constraints) {
          final scale = feed.rect.width / _boardWidth;
          return ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                Positioned.fill(
                  top: top,
                  child: Opacity(
                    opacity: feed.opacity,
                    child: Transform.translate(
                      offset: Offset(
                        constraints.maxWidth * feed.rect.left / _boardWidth,
                        (constraints.maxHeight - top) *
                            feed.rect.top /
                            _boardHeight,
                      ),
                      child: Transform.scale(
                        alignment: Alignment.topLeft,
                        scale: scale,
                        child: OverflowBox(
                          alignment: Alignment.topLeft,
                          minWidth: constraints.maxWidth,
                          maxWidth: constraints.maxWidth,
                          minHeight: constraints.maxHeight,
                          maxHeight: constraints.maxHeight,
                          child: Transform.translate(
                            offset: Offset(0, -top),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class FeedToSingleTransition extends StatelessWidget {
  const FeedToSingleTransition({
    super.key,
    required this.animation,
    required this.sourceRect,
    required this.targetMedia,
    required this.media,
    required this.child,
  });
  final Animation<double> animation;
  final Rect sourceRect;
  final Rect targetMedia;
  final Widget media;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final size = constraints.biggest;
        final elapsed = animation.value;
        final motionTime =
            ((elapsed - feedHeroMotionStart) / (1 - feedHeroMotionStart)).clamp(
              0.0,
              1.0,
            );
        final ms = feedTransitionProgress(motionTime) * 333.333;
        final scaleX = size.width / _boardWidth;
        final settle = ((ms - 266.7) / (333.333 - 266.7)).clamp(0.0, 1.0);
        final sheetSample = _sample(ms, (f) => f.sheet);
        // Use the storyboard's sheet growth to drive both rectangles.
        final referenceHeight = lerpDouble(
          sheetSample.rect.height,
          _boardHeight,
          settle,
        )!;
        final expansion =
            (referenceHeight - _source.height) /
            (_boardHeight - _source.height);
        final startSheet = Rect.fromCenter(
          center: Offset(sourceRect.center.dx, size.height / 2),
          width: sourceRect.width,
          height: sourceRect.height.clamp(0.0, size.height),
        );
        final sheetRect = Rect.lerp(startSheet, Offset.zero & size, expansion)!;
        final radius = lerpDouble(sheetSample.radius * scaleX, 0, settle)!;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fromRect(
              key: const ValueKey('transition-sheet'),
              rect: sheetRect,
              child: Opacity(
                opacity: sheetSample.opacity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      OverflowBox(
                        alignment: Alignment.topLeft,
                        minWidth: size.width,
                        maxWidth: size.width,
                        minHeight: size.height,
                        maxHeight: size.height,
                        child: Transform.scale(
                          alignment: Alignment.topLeft,
                          scale: sheetRect.width / size.width,
                          child: SizedBox(
                            width: size.width,
                            height: size.height,
                            child: IgnorePointer(
                              ignoring: elapsed < 1,
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _TransitionMedia(
              key: const ValueKey('transition-hero-media'),
              rect: Rect.lerp(sourceRect, targetMedia, expansion)!,
              radius: lerpDouble(6, 20, expansion)!,
              borderWidth: lerpDouble(.7, 1, expansion)!,
              visible: elapsed > 0 && elapsed < 1,
              media: media,
            ),
          ],
        );
      },
    ),
  );
}

class _TransitionMedia extends StatelessWidget {
  const _TransitionMedia({
    super.key,
    required this.rect,
    required this.radius,
    required this.borderWidth,
    required this.visible,
    required this.media,
  });
  final Rect rect;
  final double radius;
  final double borderWidth;
  final bool visible;
  final Widget media;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
    rect: rect,
    child: IgnorePointer(
      child: Opacity(
        opacity: visible ? 1 : 0,
        child: DecoratedBox(
          position: .foreground,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xff333333),
              width: borderWidth,
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Padding(padding: EdgeInsets.all(borderWidth), child: media),
          ),
        ),
      ),
    ),
  );
}
