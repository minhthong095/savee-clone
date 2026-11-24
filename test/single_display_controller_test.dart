import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tangerine/image_assets.dart';
import 'package:tangerine/single_display.controller.dart';

class MockSingleDisplayRepository extends Mock
    implements SingleDisplayRepository {}

void main() {
  late MockSingleDisplayRepository repository;
  const selected = ImageAsset('asset/selected.avif', 420, 420);
  const related = [ImageAsset('asset/related.avif', 420, 300)];
  setUp(() => repository = MockSingleDisplayRepository());

  blocTest<SingleDisplayCubit, SingleDisplayState>(
    'loads related items for the selected item',
    setUp: () =>
        when(() => repository.fetchRelatedItems(selected))
            .thenAnswer((_) async => related),
    build: () => SingleDisplayCubit(repository, selected),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<SingleDisplayLoading>(),
      isA<SingleDisplayLoaded>().having((s) => s.items, 'items', related),
    ],
    verify: (_) =>
        verify(() => repository.fetchRelatedItems(selected)).called(1),
  );

  blocTest<SingleDisplayCubit, SingleDisplayState>(
    'emits an error when loading fails',
    setUp: () =>
        when(() => repository.fetchRelatedItems(selected))
            .thenThrow(Exception('failed')),
    build: () => SingleDisplayCubit(repository, selected),
    act: (cubit) => cubit.load(),
    expect: () => [isA<SingleDisplayLoading>(), isA<SingleDisplayError>()],
  );

  test('does not emit after closing while a request is pending', () async {
    final pending = Completer<List<ImageAsset>>();
    when(() => repository.fetchRelatedItems(selected))
        .thenAnswer((_) => pending.future);
    final cubit = SingleDisplayCubit(repository, selected);
    final load = cubit.load();
    await cubit.close();
    pending.complete(related);
    await load;
  });
}
