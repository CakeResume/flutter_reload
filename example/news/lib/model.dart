import 'dart:async';

import 'package:flutter_reload/flutter_reload.dart';
import 'package:news/entity.dart';
import 'package:news/service.dart';

class HackNewsViewModel extends GuardViewModel
    with PaginationViewMixin<NewsEntity> {
  static const int pageSize = 20;

  @override
  late final PaginationModel<NewsEntity> paginationModel;

  HackNewsViewModel() : super(GuardState.init) {
    paginationModel = PaginationModel(
      guardViewController: guardViewController,
      onNextPage: fetchNextPage,
    );
  }

  @override
  FutureOr<void> reload() async {
    guardViewController.value = GuardState.init;
    await guard(() async {
      final paging = _pageToStartEnd(PaginationModel.firstPage);
      final res = await newsService.getNews(
        start: paging.start,
        end: paging.end,
        force: true,
      );
      paginationModel.reset(
        currentPage: PaginationModel.firstPage,
        lastPage: PaginationModel.infinityPage,
        data: res,
      );
      guardViewController.value = GuardState.normal;
      notifyListeners();
    });
  }

  @override
  FutureOr<({int page, List<NewsEntity> data})?> fetchNextPage(
      int nextPage) async {
    return (await guard(() async {
      final paging = _pageToStartEnd(nextPage);
      final res =
          await newsService.getNews(start: paging.start, end: paging.end);
      notifyListeners();
      return res.isNotEmpty ? (page: nextPage, data: res) : null;
    }));
  }

  int calculateTotalPages(int totalEntries) {
    return (totalEntries / pageSize).ceil();
  }

  ({int start, int end}) _pageToStartEnd(int page) {
    final int start = (page - 1) * pageSize;
    final int end = start + pageSize;
    return (start: start, end: end);
  }
}

mixin PaginationViewMixin<T> on GuardViewModelMixin {
  PaginationModel<T> get paginationModel;

  /// return null means this call is failed due to exception for example.
  FutureOr<({int page, List<NewsEntity> data})?> fetchNextPage(int nextPage);
}

typedef OnNextPage<T> = FutureOr<({int page, List<T> data})?> Function(
    int nextPage);
typedef AllowNextPage = bool Function();

class PaginationModel<T> {
  static const firstPage = 1;
  static const infinityPage = (1 << 63) - 1;

  final _list = <T>[];
  final GuardViewController guardViewController;
  final OnNextPage<T> onNextPage;
  final AllowNextPage? allowNextPage;
  int get currentPage => _currentPage;
  int _currentPage = firstPage;
  int get lastPage => _lastPage;
  int _lastPage = firstPage;
  int? _count;

  PaginationModel({
    required this.guardViewController,
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
    if (guardViewController.value == GuardState.init) return;

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
    return index < _listCount ? _list[index] : null;
  }

  int rowCountWithTrigger() {
    return _listCount + (hasNextPage ? 1 : 0);
  }

  int get _listCount => _count ?? (_count = _list.length);
}
