import 'package:flutter/material.dart';
import 'package:flutter_reload/flutter_reload.dart';
import 'package:news/entity.dart';
import 'package:news/model.dart';

class HackNewsListView extends StatelessWidget {
  final HackNewsViewModel model;

  const HackNewsListView({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return GuardView(
      model: model,
      builder: (context) {
        return ListenableWidget(
          model: model,
          builder: (context) {
            return ListView.separated(
              itemBuilder: (BuildContext context, int index) {
                final rowData = model.paginationModel.getData(index);
                return rowData != null
                    ? _buildRow(rowData)
                    : PaginationTriggerWidget(model: model.paginationModel);
              },
              separatorBuilder: (context, index) => const Divider(),
              itemCount: model.paginationModel.rowCountWithTrigger(),
            );
          },
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

class PaginationTriggerWidget extends StatefulWidget {
  final PaginationModel model;

  PaginationTriggerWidget({required this.model}) : super(key: UniqueKey());
  @override
  State<StatefulWidget> createState() {
    return PaginationTriggerWidgetState();
  }
}

class PaginationTriggerWidgetState extends State<PaginationTriggerWidget> {
  @override
  void initState() {
    super.initState();
    widget.model.nextPage();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}
