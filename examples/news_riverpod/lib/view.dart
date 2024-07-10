import 'package:flutter/material.dart';
import 'package:flutter_reload/flutter_reload.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:news/entity.dart';
import 'package:news/model.dart';

class HackNewsListView extends ConsumerWidget {
  const HackNewsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(hackNewsProvider);

    return GuardView(
      model: model,
      builder: (context) {
        print('test...');
        return ListView.separated(
          itemBuilder: (BuildContext context, int index) {
            final rowData = model.paginationModel.getData(index);
            return rowData != null
                ? _buildRow(rowData)
                : PaginationTriggerWidget(model: model.paginationModel);
          },
          separatorBuilder: (context, index) => const Divider(),
          itemCount: model.paginationModel.rowCountWithTrigger,
        );
      },
    );
  }

  Widget _buildRow(NewsEntity news) {
    return ListTile(
      key: ValueKey(news.id),
      title: Text(news.title),
    );
  }
}
