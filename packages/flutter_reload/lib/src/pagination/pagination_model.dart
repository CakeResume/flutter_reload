part of '../pagination.dart';

mixin PaginationViewMixin<T> on GuardViewModelMixin {
  PaginationModel<T> get paginationModel;

  /// return null means this call is failed due to exception for example.
  FutureOr<({int page, List<T> data})?> fetchNextPage(int nextPage);
}

typedef OnNextPage<T> = FutureOr<({int page, List<T> data})?> Function(
    int nextPage);
typedef AllowNextPage = bool Function();
typedef GuardStateSupplier = GuardState Function();

class PaginationModel<T> {
  static const firstPage = 1;
  static const infinityPage = (1 << 63) - 1;

  final _list = <T>[];
  UnmodifiableListView<T> get list => UnmodifiableListView<T>(_list);
  final GuardStateSupplier guardStateSupplier;
  final OnNextPage<T> onNextPage;
  final AllowNextPage? allowNextPage;
  int get currentPage => _currentPage;
  int _currentPage = firstPage;
  int get lastPage => _lastPage;
  int _lastPage = firstPage;
  int? _count;

  PaginationModel({
    required this.guardStateSupplier,
    required this.onNextPage,
    this.allowNextPage,
  });

  bool get hasNextPage =>
      (allowNextPage?.call() ?? true) && (_currentPage < _lastPage);

  void reset({
    required int currentPage,
    required int lastPage,
    required List<T> data,
  }) {
    _currentPage = currentPage;
    _lastPage = lastPage;
    _count = null;
    _list
      ..clear()
      ..addAll(data);
  }

  void nextPage() async {
    if (guardStateSupplier() == GuardState.init) return;

    final oldPage = _currentPage;
    final pagingData = await onNextPage(++_currentPage);
    if (pagingData != null) {
      _currentPage = pagingData.page;
      _count = null;
      _list.addAll(pagingData.data);
    } else {
      _currentPage = oldPage;
    }
  }

  T? getData(int index) {
    return index < listCount ? _list[index] : null;
  }

  int get rowCountWithTrigger {
    return listCount + (hasNextPage ? 1 : 0);
  }

  int get listCount => _count ?? (_count = _list.length);
}
