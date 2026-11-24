import 'package:flutter/material.dart';

import 'avif_image.dart';
import 'feed.screen.dart';
import 'image_assets.dart';
import 'page_transition.dart';
import 'single_display.screen.dart';

enum RouterKey { feed, singleDisplay }

mixin WidgetWithRouterKey on Widget {
  RouterKey get routerKey;
}

class AppPage extends Page<void> {
  AppPage(this.screen) : super(key: ValueKey<RouterKey>(screen.routerKey));

  final WidgetWithRouterKey screen;

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
    settings: this,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, _, _) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FeedRetreat(animation: secondaryAnimation, child: child),
  );
}

class SingleDisplayPage extends AppPage {
  SingleDisplayPage(SingleDisplayScreen super.screen);

  @override
  Route<void> createRoute(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : feedTransitionDuration;
    return PageRouteBuilder<void>(
      settings: this,
      opaque: false,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (_, _, _) => screen,
    );
  }
}

abstract class RouterCore extends RouterDelegate<Object> with ChangeNotifier {
  RouterCore({ImageAssetRepository? images, AvifDecoder decode = decodeAvif})
    : _images = images ?? ImageAssetRepository(),
      _decode = decode {
    _pages.add(AppPage(FeedScreen(images: _images, decode: decode)));
  }

  final ImageAssetRepository _images;
  final AvifDecoder _decode;
  final List<AppPage> _pages = [];

  @protected
  void stackPushNoTransition(WidgetWithRouterKey screen) {
    if (_pages.any((page) => page.screen.routerKey == screen.routerKey)) return;
    _pages.add(AppPage(screen));
    notifyListeners();
  }

  @protected
  void pushSingleDisplay(
    EncodedImage image,
    int thumbnailWidth,
    Rect sourceRect,
  ) {
    if (_pages.any(
      (page) => page.screen.routerKey == RouterKey.singleDisplay,
    )) {
      return;
    }
    _pages.add(
      SingleDisplayPage(
        SingleDisplayScreen(
          image: image,
          thumbnailWidth: thumbnailWidth,
          sourceRect: sourceRect,
          images: _images,
          decode: _decode,
        ),
      ),
    );
    notifyListeners();
  }

  void popCurrent() {
    if (_pages.length <= 1) return;
    _pages.removeLast();
    notifyListeners();
  }

  @override
  Future<bool> popRoute() async {
    if (_pages.length <= 1) return false;
    popCurrent();
    return true;
  }

  @override
  Widget build(BuildContext context) => Navigator(
    pages: List.of(_pages),
    onDidRemovePage: (page) {
      if (_pages.length > 1 && identical(_pages.last, page)) popCurrent();
    },
  );

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}

mixin SingleDisplayRouter on RouterCore {
  void openSingleDisplay(
    EncodedImage image,
    int thumbnailWidth,
    Rect sourceRect,
  ) => pushSingleDisplay(image, thumbnailWidth, sourceRect);
}

class AppRouter extends RouterCore with SingleDisplayRouter {
  AppRouter({super.images, super.decode});

  static AppRouter of(BuildContext context) =>
      Router.of(context).routerDelegate as AppRouter;
}
