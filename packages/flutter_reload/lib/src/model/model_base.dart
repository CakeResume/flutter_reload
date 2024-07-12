part of '../reload.dart';

const _guardStateControllerZonedKey = '_@guardStateControllerZone@_';

abstract class GuardStateListenable extends ValueListenable<GuardState> {
  const GuardStateListenable();

  /// Method to wait until the state becomes normal.
  /// It checks the current state, and if it's not normal,
  /// it sets up a listener and waits for the state to change to normal.
  ///
  /// A timeout of 10 seconds is used to avoid indefinite waiting, throwing a
  /// [TimeoutException] if the state does not become normal within this period.
  FutureOr<void> waitOnNormalState();
}

/// GuardStateController class extends ValueNotifier to manage and notify changes in the GuardState.
///
/// see also [GuardState]
class GuardStateController extends ValueNotifier<GuardState>
    implements GuardStateListenable {
  /// Constructor initializes the GuardStateController with a default state of NormalGuardState.
  GuardStateController([super.value = const NormalGuardState()]);

  @override
  FutureOr<void> waitOnNormalState() async {
    if (!value.isNormal) {
      final completer = Completer();
      void onChange() {
        if (value.isNormal) {
          completer.complete();
        }
      }

      addListener(onChange);
      Future.delayed(const Duration(seconds: 10)).whenComplete(() {
        if (!completer.isCompleted) {
          completer.completeError(
              TimeoutException('Failed to wait for normal state.'));
        }
      });
      await completer.future.whenComplete(() {
        removeListener(onChange);
      });
    }
  }
}

abstract class ViewModel implements Listenable {
  @protected
  FutureOr<void> reload();

  /// the model owner should call this when it's going to be initiated.
  void init();

  /// the model owner should call this when it's going to be disposed.
  void dispose();
}

abstract class GuardViewModel extends ChangeNotifier
    with GuardViewModelMixin
    implements ViewModel {
  GuardViewModel(GuardState state, {this.parent})
      : _guardStateController = GuardStateController(state);

  @override
  final GuardStateController _guardStateController;

  @override
  GuardState get guardState => _guardStateController.value;

  @override
  GuardStateListenable get guardStateListenable => _guardStateController;

  @override
  final GuardViewModelMixin? parent;
}

enum GuardExceptionHandleResult {
  // [Guard] will handle it through default behavior.
  byDefault,
  // [Guard] won't handle it. So mute the default behavior.
  mute,
  muteOnlyForOffline;

  bool get shouldHandleOffline => this == byDefault;
}

typedef GuardRawAction<T> = FutureOr<T?> Function(
    GuardStateController guardStateController);

mixin GuardViewModelMixin {
  GuardStateController get _guardStateController;
  GuardState get guardState;
  GuardStateListenable get guardStateListenable;
  GuardViewModelMixin? get parent;

  @mustCallSuper
  FutureOr<T?> guard<T>(
    DataSupplier<FutureOr<T?>> action, {
    GuardExceptionHandleResult Function(dynamic exception, dynamic stacktrace)?
        onError,
  }) {
    return _guard<T>(action, onError: onError);
  }

  @mustCallSuper
  FutureOr<T?> guardReload<T>(
    DataSupplier<FutureOr<T?>> action, {
    GuardExceptionHandleResult Function(dynamic exception, dynamic stacktrace)?
        onError,
  }) {
    return _guard<T>(() async {
      _guardStateController.value = GuardState.init;
      final result = await action();
      _guardStateController.value = GuardState.normal;
      return result;
    }, onError: onError);
  }

  @mustCallSuper
  FutureOr<T?> guardRaw<T>(
    GuardRawAction<T> action, {
    GuardExceptionHandleResult Function(dynamic exception, dynamic stacktrace)?
        onError,
  }) {
    return _guard<T>(() => action(_guardStateController), onError: onError);
  }

  @mustCallSuper
  FutureOr<T?> _guard<T>(
    DataSupplier<FutureOr<T?>> action, {
    GuardExceptionHandleResult Function(dynamic exception, dynamic stacktrace)?
        onError,
  }) async {
    if (Zone.current[_guardStateControllerZonedKey] != null) {
      try {
        return await action();
      } catch (ex, st) {
        final result = onError?.call(ex, st);
        if (result != null && result != GuardExceptionHandleResult.byDefault) {
          if (kDebugMode) {
            print(
                'There is an outer guard function wrapped. The [onError] function is return an ignored signal, '
                'but the inner guard function can not determine to ignore it. [$result]:$st');
          }
        }
        rethrow;
      }
    } else {
      final tValue = await runZonedGuarded<FutureOr<T?>>(
        () async {
          try {
            return await action();
          } catch (ex, st) {
            ReloadConfiguration.instance.exceptionHandle(
              ex,
              st,
              silent: parent != null,
              guardStateController:
                  parent?._guardStateController ?? _guardStateController,
              onError: onError,
            );
            return null;
          }
        },
        zoneValues: {_guardStateControllerZonedKey: _guardStateController},
        (Object ex, StackTrace st) async {
          ReloadConfiguration.instance.exceptionHandle(
            ex,
            st,
            silent: parent != null,
            guardStateController:
                parent?._guardStateController ?? _guardStateController,
            onError: onError,
          );
        },
      );

      return tValue;
    }
  }

  bool get supportReload => true;

  @protected
  FutureOr<void> reload();

  bool get inited => _inited;
  var _inited = false;
  var _disposed = false;

  @mustCallSuper
  void init() {
    assert(() {
      if (_inited) return false;
      _inited = true;
      return true;
    }(), 'init should be called only once.');
  }

  @mustCallSuper
  void dispose() {
    assert(() {
      if (_disposed) return false;
      _disposed = true;
      return true;
    }(), 'dispose should be called only once.');
  }
}
