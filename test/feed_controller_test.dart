import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tangerine/feed.controller.dart';
import 'package:tangerine/image_assets.dart';

class MockFeedRepository extends Mock implements FeedRepository {}

void main() {
  late MockFeedRepository repository;
  const items = [ImageAsset('asset/example.avif', 420, 300)];
  setUp(() => repository = MockFeedRepository());

  blocTest<CategoriesCubit, FeedSectionState<List<String>>>(
    'categories emit loading and loaded',
    setUp: () =>
        when(() => repository.fetchCategories())
            .thenAnswer((_) async => ['Popular']),
    build: () => CategoriesCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<FeedSectionLoading<List<String>>>(),
      isA<FeedSectionLoaded<List<String>>>(),
    ],
  );
  blocTest<TrendingUsersCubit, FeedSectionState<List<String>>>(
    'users emit loading and loaded',
    setUp: () =>
        when(() => repository.fetchTrendingUsers())
            .thenAnswer((_) async => ['@user']),
    build: () => TrendingUsersCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<FeedSectionLoading<List<String>>>(),
      isA<FeedSectionLoaded<List<String>>>(),
    ],
  );
  blocTest<FeedCubit, FeedSectionState<List<ImageAsset>>>(
    'feed emits loading and loaded',
    setUp: () =>
        when(() => repository.fetchFeed()).thenAnswer((_) async => items),
    build: () => FeedCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<FeedSectionLoading<List<ImageAsset>>>(),
      isA<FeedSectionLoaded<List<ImageAsset>>>().having(
        (state) => state.value,
        'items',
        items,
      ),
    ],
  );
  blocTest<FeedCubit, FeedSectionState<List<ImageAsset>>>(
    'a failed request emits an error',
    setUp: () =>
        when(() => repository.fetchFeed()).thenThrow(Exception('failed')),
    build: () => FeedCubit(repository),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<FeedSectionLoading<List<ImageAsset>>>(),
      isA<FeedSectionError<List<ImageAsset>>>(),
    ],
  );

  test('feed ignores a result after closing', () async {
    final pending = Completer<List<ImageAsset>>();
    when(() => repository.fetchFeed()).thenAnswer((_) => pending.future);
    final cubit = FeedCubit(repository);
    final load = cubit.load();
    await cubit.close();
    pending.complete(items);
    await load;
    expect(cubit.state, isA<FeedSectionLoading<List<ImageAsset>>>());
  });
}
