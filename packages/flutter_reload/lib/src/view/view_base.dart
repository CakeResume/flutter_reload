part of '../reload.dart';

typedef NormalStateBuilder = Widget Function(BuildContext context);
typedef AbnormalStateBuilder = Widget Function(
    BuildContext context, GuardState state);
typedef GuardViewWrapper = Widget Function(BuildContext context, Widget child);

class GuardView extends RawGuardView {
  GuardView({
    super.key,
    required GuardViewModel model,
    required super.builder,
    super.abnormalStateBuilder,
    super.wrapper,
  }) : super(
            guardStateController: model._guardStateController,
            reload: model.reload);

  @override
  State<GuardView> createState() {
    return GuardViewState<GuardView>();
  }

  static GuardAbnormalStateBuilder defaultAbnormalStateBuilder =
      RawGuardView.defaultAbnormalStateBuilder;
}

class RawGuardView extends StatefulWidget {
  final GuardStateController guardStateController;
  final DataSupplier<FutureOr<void>> reload;
  final NormalStateBuilder builder;
  final GuardAbnormalStateBuilder? abnormalStateBuilder;
  final GuardViewWrapper? wrapper;

  const RawGuardView({
    super.key,
    required this.guardStateController,
    required this.reload,
    required this.builder,
    this.abnormalStateBuilder,
    this.wrapper,
  });

  @override
  State<StatefulWidget> createState() {
    return GuardViewState();
  }

  static GuardAbnormalStateBuilder defaultAbnormalStateBuilder =
      ReloadConfiguration.instance.abnormalStateBuilder;
}

class GuardViewState<T extends RawGuardView> extends State<T> {
  GuardStateController get guardStateController => widget.guardStateController;

  @override
  void initState() {
    super.initState();
    guardStateController.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.guardStateController.removeListener(_onStateChanged);
    widget.guardStateController.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    guardStateController.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget w;
    if (guardStateController.value.isNormal) {
      w = widget.builder(context);
    } else {
      w = widget.abnormalStateBuilder
              ?.call(context, guardStateController.value, widget.reload) ??
          RawGuardView.defaultAbnormalStateBuilder(
              context, guardStateController.value, widget.reload) ??
          const SizedBox();
    }

    return widget.wrapper?.call(context, w) ?? w;
  }
}
