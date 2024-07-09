part of '../pagination.dart';

typedef PaginationTriggerBuilder = Widget Function(BuildContext);

class PaginationTriggerWidget<T> extends StatefulWidget {
  final PaginationModel<T> model;
  final PaginationTriggerBuilder? builder;
  final double? height;

  PaginationTriggerWidget({required this.model, this.builder, this.height})
      : super(key: UniqueKey());

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
    return SizedBox(
      height: widget.height ?? 48.0,
      child: widget.builder?.call(context) ??
          const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
    );
  }
}
