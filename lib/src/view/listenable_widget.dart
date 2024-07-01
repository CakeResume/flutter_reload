import 'package:flutter/widgets.dart';
import 'package:flutter_reload/flutter_reload.dart';

typedef ViewBuilder = Widget Function(BuildContext context);

class ListenableWidget extends StatefulWidget {
  final Iterable<Listenable> models;
  final ViewBuilder builder;
  final DataSupplier? observer;

  ListenableWidget({
    super.key,
    required Listenable model,
    required this.builder,
    this.observer,
  }) : models = [model];

  const ListenableWidget.models({
    super.key,
    required this.models,
    required this.builder,
    this.observer,
  });

  @override
  State<StatefulWidget> createState() {
    return _ListenableWidgetState();
  }
}

class _ListenableWidgetState extends State<ListenableWidget> {
  // only work if [widget.shouldRebuild] != null
  dynamic lastValue;

  @override
  void initState() {
    super.initState();
    if (widget.observer != null) {
      lastValue = widget.observer!();
    }
    for (final model in widget.models) {
      model.addListener(onNotified);
    }
  }

  @override
  void didUpdateWidget(covariant ListenableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final model in oldWidget.models) {
      model.removeListener(onNotified);
    }
    for (final model in widget.models) {
      model.addListener(onNotified);
    }
  }

  @override
  void dispose() {
    for (final model in widget.models) {
      model.removeListener(onNotified);
    }
    super.dispose();
  }

  void onNotified() {
    if (widget.observer != null) {
      final oldValue = lastValue;
      lastValue = widget.observer!();
      if (oldValue == lastValue) {
        return;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
