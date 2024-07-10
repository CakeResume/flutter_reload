import 'dart:async';

import 'package:flutter_reload/flutter_reload.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:news/entity.dart';
import 'package:news/service.dart';

final hackNewsProvider =
    ChangeNotifierProvider((ref) => HackNewsViewModel()..reload());

class HackNewsViewModel extends GuardViewModel
    with PaginationViewMixin<NewsEntity> {
  static const int pageSize = 20;

  @override
  late final PaginationModel<NewsEntity> paginationModel;

  HackNewsViewModel() : super(GuardState.init) {
    paginationModel = PaginationModel(
      guardStateController: guardStateController,
      onNextPage: fetchNextPage,
    );
  }

  @override
  FutureOr<void> reload() async {
    guardStateController.value = GuardState.init;
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
      guardStateController.value = GuardState.normal;
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
