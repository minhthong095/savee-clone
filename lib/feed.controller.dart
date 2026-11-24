import 'package:flutter_bloc/flutter_bloc.dart';

import 'image_assets.dart';

sealed class FeedSectionState<T> {
  const FeedSectionState();
}

final class FeedSectionInitial<T> extends FeedSectionState<T> {
  const FeedSectionInitial();
}

final class FeedSectionLoading<T> extends FeedSectionState<T> {
  const FeedSectionLoading();
}

final class FeedSectionLoaded<T> extends FeedSectionState<T> {
  const FeedSectionLoaded(this.value);
  final T value;
}

final class FeedSectionError<T> extends FeedSectionState<T> {
  const FeedSectionError();
}

class FeedRepository {
  FeedRepository({ImageAssetRepository? images})
    : _images = images ?? ImageAssetRepository();

  final ImageAssetRepository _images;

  Future<List<String>> fetchCategories() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return ['Popular', 'Interface Design', 'Branding', 'Web Design'];
  }

  Future<List<String>> fetchTrendingUsers() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return ['@djshiflet', '@neodrah', '@caspar'];
  }

  Future<List<ImageAsset>> fetchFeed() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    return _images.loadCatalog();
  }

  Future<EncodedImage> loadImage(ImageAsset asset) => _images.loadImage(asset);
}

abstract class FeedSectionCubit<T> extends Cubit<FeedSectionState<T>> {
  FeedSectionCubit() : super(const FeedSectionInitial());

  Future<T> fetch();

  Future<void> load() async {
    emit(const FeedSectionLoading());
    try {
      final value = await fetch();
      if (!isClosed) emit(FeedSectionLoaded(value));
    } catch (_) {
      if (!isClosed) emit(const FeedSectionError());
    }
  }
}

class CategoriesCubit extends FeedSectionCubit<List<String>> {
  CategoriesCubit(this.repository);
  final FeedRepository repository;
  @override
  Future<List<String>> fetch() => repository.fetchCategories();
}

class TrendingUsersCubit extends FeedSectionCubit<List<String>> {
  TrendingUsersCubit(this.repository);
  final FeedRepository repository;
  @override
  Future<List<String>> fetch() => repository.fetchTrendingUsers();
}

class FeedCubit extends FeedSectionCubit<List<ImageAsset>> {
  FeedCubit(this.repository);
  final FeedRepository repository;
  @override
  Future<List<ImageAsset>> fetch() => repository.fetchFeed();

  Future<EncodedImage> loadImage(ImageAsset asset) =>
      repository.loadImage(asset);
}
