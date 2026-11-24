import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.router.dart';

const imageCacheTestUrl = 'https://www.gstatic.com/webp/gallery/2.webp';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const DiscoveryApp());
}

class DiscoveryApp extends StatefulWidget {
  const DiscoveryApp({super.key});

  @override
  State<DiscoveryApp> createState() => _DiscoveryAppState();
}

class _DiscoveryAppState extends State<DiscoveryApp> {
  final AppRouter router = AppRouter();

  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xff0a0a0a),
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Arial'),
    ),
    routerDelegate: router,
    backButtonDispatcher: RootBackButtonDispatcher(),
  );
}
