part of 'reload.dart';

typedef ExceptionHandler = void Function(
  dynamic exception,
  dynamic stackTrace, {
  bool silent,
  GuardViewController? guardViewController,
  GuardExceptionHandleResult Function(dynamic exception, dynamic stackTrace)?
      onError,
});

typedef GuardAbnormalStateBuilder = Widget? Function(
  BuildContext context,
  GuardState guardState,
  DataSupplier<FutureOr<void>> dataReloader,
);

class ReloadConfiguration {
  static ReloadConfiguration get instance => _instance!;
  static ReloadConfiguration? _instance;
  static init({
    required ExceptionHandler exceptionHandle,
    required GuardAbnormalStateBuilder stateBuilder,
  }) {
    _instance ??= ReloadConfiguration._(
      exceptionHandle: exceptionHandle,
      stateBuilder: stateBuilder,
    );
  }

  ReloadConfiguration._({
    required this.exceptionHandle,
    required this.stateBuilder,
  });
  final ExceptionHandler exceptionHandle;
  final GuardAbnormalStateBuilder stateBuilder;
}
