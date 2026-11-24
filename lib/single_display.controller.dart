import 'package:flutter_bloc/flutter_bloc.dart';

import 'image_assets.dart';

sealed class SingleDisplayState {
  const SingleDisplayState();
}

final class SingleDisplayInitial extends SingleDisplayState {
  const SingleDisplayInitial();
}

final class SingleDisplayLoading extends SingleDisplayState {
  const SingleDisplayLoading();
}

final class SingleDisplayLoaded extends SingleDisplayState {
  const SingleDisplayLoaded(this.items);
  final List<ImageAsset> items;
}

final class SingleDisplayError extends SingleDisplayState {
  const SingleDisplayError();
}

class SingleDisplayRepository {
  SingleDisplayRepository(this._images);

  final ImageAssetRepository _images;

  Future<List<ImageAsset>> fetchRelatedItems(ImageAsset selected) async {
    return _images.loadRelated(selected);
  }

  Future<EncodedImage> loadImage(ImageAsset asset) => _images.loadImage(asset);
}

class SingleDisplayCubit extends Cubit<SingleDisplayState> {
  SingleDisplayCubit(this.repository, this.selected)
    : super(const SingleDisplayInitial());
  final SingleDisplayRepository repository;
  final ImageAsset selected;

  Future<EncodedImage> loadImage(ImageAsset asset) =>
      repository.loadImage(asset);

  Future<void> load() async {
    emit(const SingleDisplayLoading());
    try {
      final items = await repository.fetchRelatedItems(selected);
      if (!isClosed) emit(SingleDisplayLoaded(items));
    } catch (_) {
      if (!isClosed) emit(const SingleDisplayError());
    }
  }
}
