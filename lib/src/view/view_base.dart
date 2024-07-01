part of '../reload.dart';

typedef NormalStateBuilder = Widget Function(BuildContext context);
typedef AbnormalStateBuilder = Widget Function(
    BuildContext context, GuardState state);
typedef GuardViewWrapper = Widget Function(BuildContext context, Widget child);

class GuardView extends RawGuardView {
  GuardView({
    super.key,
    required GuardViewChangeNotifier model,
    required super.builder,
    super.abnormalStateBuilder,
    super.wrapper,
  }) : super(
            guardViewController: model.guardViewController,
            // page_base and model_base are UI-Model pair. should know each other
            // ignore: invalid_use_of_protected_member
            reload: model.reload);

  @override
  State<GuardView> createState() {
    return GuardViewState<GuardView>();
  }

  static GuardAbnormalStateBuilder defaultAbnormalStateBuilder =
      RawGuardView.defaultAbnormalStateBuilder;
}

class RawGuardView extends StatefulWidget {
  final GuardViewController guardViewController;
  final DataSupplier<FutureOr<void>> reload;
  final NormalStateBuilder builder;
  final GuardAbnormalStateBuilder? abnormalStateBuilder;
  final GuardViewWrapper? wrapper;

  const RawGuardView({
    super.key,
    required this.guardViewController,
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
      ReloadConfiguration.instance.stateBuilder;
}

class GuardViewState<T extends RawGuardView> extends State<T> {
  GuardViewController get guardViewController => widget.guardViewController;

  @override
  void initState() {
    super.initState();
    guardViewController.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.guardViewController.removeListener(_onStateChanged);
    widget.guardViewController.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    guardViewController.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget w;
    if (guardViewController.value.isNormal) {
      w = widget.builder(context);
    } else {
      w = widget.abnormalStateBuilder
              ?.call(context, guardViewController.value, widget.reload) ??
          RawGuardView.defaultAbnormalStateBuilder(
              context, guardViewController.value, widget.reload) ??
          const SizedBox();
    }

    return widget.wrapper?.call(context, w) ?? w;
  }
}
