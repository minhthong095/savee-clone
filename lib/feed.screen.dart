import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.router.dart';
import 'avif_image.dart';
import 'feed.controller.dart';
import 'image_assets.dart';
import 'image_feed.dart';

class FeedScreen extends StatefulWidget with WidgetWithRouterKey {
  @override
  RouterKey get routerKey => RouterKey.feed;
  const FeedScreen({super.key, this.images, this.decode = decodeAvif});

  final ImageAssetRepository? images;
  final AvifDecoder decode;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final _repository = FeedRepository(images: widget.images);
  String? _selectedPath;
  int selectedCategory = 0;
  int selectedTab = 1;

  void _openImage(EncodedImage image, int thumbnailWidth, Rect sourceRect) {
    setState(() => _selectedPath = image.asset.path);
    AppRouter.of(context).openSingleDisplay(image, thumbnailWidth, sourceRect);
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => CategoriesCubit(_repository)..load()),
      BlocProvider(create: (_) => TrendingUsersCubit(_repository)..load()),
      BlocProvider(create: (_) => FeedCubit(_repository)..load()),
    ],
    child: Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    SizedBox(height: MediaQuery.paddingOf(context).top + 15),
                    const _SearchTools(),
                    const SizedBox(height: 12),
                    BlocBuilder<
                      CategoriesCubit,
                      FeedSectionState<List<String>>
                    >(
                      builder: (context, state) => switch (state) {
                        FeedSectionInitial() ||
                        FeedSectionLoading() => _Categories(
                          categories: const ['Popular'],
                          selected: 0,
                          onSelected: (_) {},
                        ),
                        FeedSectionLoaded(:final value) => _Categories(
                          categories: value,
                          selected: selectedCategory,
                          onSelected: (index) =>
                              setState(() => selectedCategory = index),
                        ),
                        FeedSectionError() => const SizedBox.shrink(),
                      },
                    ),
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        'Trending users',
                        style: TextStyle(
                          color: Color(0xff888888),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    BlocBuilder<
                      TrendingUsersCubit,
                      FeedSectionState<List<String>>
                    >(
                      builder: (context, state) => switch (state) {
                        FeedSectionInitial() ||
                        FeedSectionLoading() => const _TrendingUsersLoading(),
                        FeedSectionLoaded(:final value) => _TrendingUsers(
                          users: value,
                        ),
                        FeedSectionError() => const SizedBox.shrink(),
                      },
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              BlocBuilder<FeedCubit, FeedSectionState<List<ImageAsset>>>(
                builder: (context, state) => switch (state) {
                  FeedSectionInitial() => const FeedLoading(),
                  FeedSectionLoading() => const FeedLoading(),
                  FeedSectionLoaded(:final value) => ImageFeedSliver(
                    items: value,
                    loadImage: context.read<FeedCubit>().loadImage,
                    decode: widget.decode,
                    onOpen: _openImage,
                    hiddenPath: _selectedPath,
                    coverAnimation: ModalRoute.of(context)?.secondaryAnimation,
                  ),
                  FeedSectionError() => const SliverToBoxAdapter(
                    child: SizedBox.shrink(),
                  ),
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          Positioned(
            left: 36,
            right: 36,
            bottom: MediaQuery.paddingOf(context).bottom + 28,
            child: _BottomNavigation(
              selected: selectedTab,
              onSelected: (index) => setState(() => selectedTab = index),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Categories extends StatelessWidget {
  const _Categories({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });
  final List<String> categories;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      scrollDirection: .horizontal,
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (context, index) => _CategoryChip(
        label: categories[index],
        selected: selected == index,
        onTap: () => onSelected(index),
      ),
    ),
  );
}

class _TrendingUsersLoading extends StatelessWidget {
  const _TrendingUsersLoading();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView.separated(
      scrollDirection: .horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (_, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xff1e1e1e),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              _Skeleton(width: 25, height: 25, radius: 25),
              SizedBox(width: 8),
              _Skeleton(width: 86, height: 11, radius: 10),
              SizedBox(width: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({this.width, required this.height, required this.radius});
  final double? width;
  final double height;
  final double radius;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff282828),
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

class FeedLoading extends StatefulWidget {
  const FeedLoading({super.key});

  @override
  State<FeedLoading> createState() => _FeedLoadingState();
}

class _FeedLoadingState extends State<FeedLoading>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1440),
  );

  // Penpot frames 21–63 form one cycle; frame 64 repeats frame 21.
  // Each row samples the horizontal gradient at 10% intervals.
  static final _gradients = _loadingGradientFrames
      .map(
        (frame) => LinearGradient(
          colors: frame
              .map((shade) => Color.fromARGB(255, shade, shade, shade))
              .toList(),
        ),
      )
      .toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final position = _controller.value * _gradients.length;
          final index = position.floor();
          final gradient = LinearGradient.lerp(
            _gradients[index % _gradients.length],
            _gradients[(index + 1) % _gradients.length],
            position - index,
          )!;
          return Row(
            crossAxisAlignment: .start,
            children: [
              Expanded(
                child: _LoadingColumn(
                  heights: const [250, 288, 210],
                  gradient: gradient,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _LoadingColumn(
                  heights: const [144, 191, 126, 220],
                  gradient: gradient,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _LoadingColumn extends StatelessWidget {
  const _LoadingColumn({required this.heights, required this.gradient});

  final List<double> heights;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final height in heights)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
    ],
  );
}

// Grayscale stops exported from the Penpot loading-card gradient.
const _loadingGradientFrames = <List<int>>[
  [0x25, 0x24, 0x23, 0x22, 0x20, 0x1f, 0x1e, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x26, 0x25, 0x24, 0x23, 0x21, 0x20, 0x1f, 0x1e, 0x1d, 0x1d, 0x1d],
  [0x25, 0x26, 0x25, 0x23, 0x23, 0x21, 0x20, 0x1f, 0x1e, 0x1d, 0x1d],
  [0x25, 0x25, 0x25, 0x24, 0x23, 0x22, 0x20, 0x1f, 0x1f, 0x1d, 0x1d],
  [0x23, 0x25, 0x26, 0x25, 0x24, 0x23, 0x22, 0x20, 0x1f, 0x1e, 0x1d],
  [0x23, 0x24, 0x25, 0x26, 0x25, 0x24, 0x23, 0x21, 0x20, 0x1f, 0x1e],
  [0x22, 0x23, 0x24, 0x25, 0x25, 0x24, 0x23, 0x22, 0x21, 0x20, 0x1f],
  [0x22, 0x23, 0x24, 0x25, 0x25, 0x24, 0x23, 0x22, 0x21, 0x20, 0x1f],
  [0x1f, 0x20, 0x22, 0x23, 0x24, 0x25, 0x26, 0x25, 0x24, 0x23, 0x21],
  [0x1f, 0x20, 0x21, 0x22, 0x23, 0x25, 0x25, 0x25, 0x24, 0x23, 0x22],
  [0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x25, 0x26, 0x25, 0x24, 0x23],
  [0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x23, 0x24, 0x25, 0x26, 0x25, 0x24],
  [0x1d, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x25, 0x25, 0x25],
  [0x1d, 0x1d, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x23, 0x23, 0x25, 0x26],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1e, 0x1f, 0x20, 0x22, 0x23, 0x24],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1f, 0x20, 0x20, 0x22, 0x23],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1f, 0x20, 0x21, 0x22],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1e, 0x1f, 0x20, 0x21],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1e, 0x1f, 0x20],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1e, 0x1f],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1e],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1f, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x1f, 0x1e, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x20, 0x1f, 0x1e, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x21, 0x20, 0x1f, 0x1e, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x22, 0x21, 0x20, 0x1f, 0x1e, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x23, 0x22, 0x21, 0x20, 0x1f, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
  [0x24, 0x23, 0x22, 0x20, 0x1f, 0x1f, 0x1d, 0x1d, 0x1d, 0x1d, 0x1d],
];

class _SearchTools extends StatelessWidget {
  const _SearchTools();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              style: const TextStyle(fontSize: 17, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Graphic design systems',
                hintStyle: const TextStyle(
                  color: Color(0xff888888),
                  fontSize: 17,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xff888888),
                  size: 23,
                ),
                filled: true,
                fillColor: const Color(0xff1e1e1e),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: .none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 13),
        const Icon(Icons.center_focus_weak, color: Color(0xff888888), size: 22),
        const SizedBox(width: 18),
        IconButton(
          tooltip: 'Open image cache test',
          onPressed: () => Navigator.of(context).pushNamed('/image-cache-test'),
          icon: const Icon(Icons.image_search, color: Color(0xff888888)),
        ),
        const _ColorWheel(),
        const SizedBox(width: 3),
      ],
    ),
  );
}

class _ColorWheel extends StatelessWidget {
  const _ColorWheel();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 22,
    height: 22,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: .circle,
        gradient: SweepGradient(
          colors: [
            Colors.red,
            Colors.yellow,
            Colors.green,
            Colors.cyan,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
        ),
      ),
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xffe5e6e6) : Colors.transparent,
    shape: StadiumBorder(
      side: BorderSide(
        color: selected ? Colors.transparent : const Color(0xff414141),
      ),
    ),
    child: InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: selected ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    ),
  );
}

class _TrendingUsers extends StatelessWidget {
  const _TrendingUsers({required this.users});
  final List<String> users;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: ListView.separated(
      scrollDirection: .horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (context, index) => _UserChip(name: users[index]),
    ),
  );
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xff1e1e1e),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      child: Row(
        children: [
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: .circle,
              border: Border.all(color: const Color(0xff888888), width: .6),
            ),
          ),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: .w600)),
          const SizedBox(width: 5),
          const Icon(Icons.verified, color: Color(0xffcccccc), size: 13),
        ],
      ),
    ),
  );
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xfa191a18), Color(0xf5484848)],
      ),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: const Color(0xff626262), width: .7),
    ),
    child: Row(
      mainAxisAlignment: .spaceEvenly,
      children: List.generate(6, (index) {
        final icons = [
          Icons.home_outlined,
          Icons.search,
          Icons.add,
          Icons.favorite_border,
          Icons.verified,
          Icons.circle,
        ];
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => onSelected(index),
            child: Center(
              child: Container(
                width: 51,
                height: 42,
                decoration: BoxDecoration(
                  color: selected == index
                      ? const Color(0xff3c3d3a)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: index == 5
                    ? const Center(
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xff282828),
                          child: Text(
                            '2',
                            style: TextStyle(
                              color: Color(0xffa6a6a6),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        icons[index],
                        color: Colors.white,
                        size: index == 2 ? 30 : 25,
                      ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}
