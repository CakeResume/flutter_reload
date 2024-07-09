part of 'reload.dart';

typedef ExceptionHandler = void Function(
  dynamic exception,
  dynamic stackTrace, {
  required bool silent,
  GuardStateController? guardStateController,
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
    required GuardAbnormalStateBuilder abnormalStateBuilder,
  }) {
    _instance ??= ReloadConfiguration._(
      exceptionHandle: exceptionHandle,
      abnormalStateBuilder: abnormalStateBuilder,
    );
  }

  ReloadConfiguration._({
    required this.exceptionHandle,
    required this.abnormalStateBuilder,
  });
  final ExceptionHandler exceptionHandle;
  final GuardAbnormalStateBuilder abnormalStateBuilder;
}
