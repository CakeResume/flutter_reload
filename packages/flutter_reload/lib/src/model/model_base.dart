part of '../reload.dart';

const _guardStateControllerZonedKey = '_@guardStateControllerZone@_';

/// An interface to define the listenable state for guard state changes.
abstract class GuardStateListenable extends ValueListenable<GuardState> {
  const GuardStateListenable();

  /// Method to wait until the state becomes normal.
  /// It checks the current state, and if it's not normal,
  /// it sets up a listener and waits for the state to change to normal.
  ///
  /// A timeout of 10 seconds is used to avoid indefinite waiting, throwing a
  /// [TimeoutException] if the state does not become normal within this period.
  FutureOr<void> waitOnNormalState({int timeoutSeconds = 10});
}

/// GuardStateController class extends ValueNotifier to manage and notify changes in the GuardState.
///
/// see also [GuardState]
class GuardStateController extends ValueNotifier<GuardState>
    implements GuardStateListenable {
  /// Constructor initializes the GuardStateController with a default state of NormalGuardState.
  GuardStateController([super.value = const NormalGuardState()]);

  @override
  FutureOr<void> waitOnNormalState({int timeoutSeconds = 10}) async {
    if (!value.isNormal) {
      final completer = Completer();
      void onChange() {
        if (value.isNormal) {
          completer.complete();
        }
      }

      addListener(onChange);
      Future.delayed(Duration(seconds: timeoutSeconds)).whenComplete(() {
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
  /// The subclass should implement this method to handle the reload concept.
  /// This concept is used to represent a data reload action.
  ///
  /// You can think of this method as similar to initially loading all necessary data,
  /// followed by multiple update operations due to user interactions.
  ///
  /// For example, in a chat application, you might load the initial page of recent
  /// chat history when opening a chat view.
  /// After the user sends or receives a new message, this chat record is added
  /// to the model.
  ///
  /// The [reload] lifecycle is useful for defining a clear structure:
  /// 1. Initializing data. (This is where the [reload] action occurs.)
  /// 2. Performing all subsequent operations that update the local data and
  ///    sync it with the online server.
  /// If unexpected cases cause the data to become out of sync, we can simply
  /// call [reload] with an optional state (e.g., chat keyword search)
  /// to reload the entire model's data.
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

/// This enum defines the possible results when intercepting a guard exception.
/// See more details in the [onError] function of [guardReload] and [guard].
enum GuardExceptionHandleResult {
  // Use the default behavior after interception.
  byDefault,
  // Ignore the rest of the default behavior.
  mute,
  // Ignore the rest of the default behavior only for offline errors.
  muteOnlyForOffline;

  bool get shouldHandleOffline => this == byDefault;
}

typedef GuardRawAction<T> = FutureOr<T?> Function(
    GuardStateController guardStateController);

/// The mixin is used to integrate the model with `guard` protection.
///
/// You can customize a guard-based UI model with any state management.
/// Subclass should call [guardReload] inside [reload] method
/// or call [guard] in any model action that will trigger the side effect.
///
/// With [guardRaw], you have the ability to control the guard state manually.
///
/// [guardReload]: Executes with a change in [guardState].
/// [guard]: Executes without a change in [guardState].
/// [guardRaw]: Executes with a [guardState] controller.
mixin GuardViewModelMixin {
  GuardStateController get _guardStateController;
  GuardState get guardState;
  GuardStateListenable get guardStateListenable;
  GuardViewModelMixin? get parent;

  /// Executes with the exception protection only.
  ///
  /// See [guardReload] if you want to execute action with auto state change.
  /// See [guardRaw] for exception protection with manual state control.
  @mustCallSuper
  FutureOr<T?> guard<T>(
    DataSupplier<FutureOr<T?>> action, {
    GuardExceptionHandleResult Function(dynamic exception, dynamic stacktrace)?
        onError,
  }) {
    return _guard<T>(action, onError: onError);
  }

  /// Executes with a change in [guardState].
  /// Before the [action], [guardState] will be changed to [GuardState.init],
  /// and will finally change to [GuardState.normal] when the [action] is done.
  ///
  /// See [guard] for exception protection only.
  /// See [guardRaw] for exception protection with manual state control.
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

  /// The [action] will provide a [GuardStateController] that can be
  /// manually controlled by the callee.
  @mustCallSuper
  FutureOr<T?> guardRaw<T>(
    GuardRawAction<T> action, {
    GuardExceptionHandleResult Function(dynamic exception, dynamic stacktrace)?
        onError,
  }) {
    return _guard<T>(() => action(_guardStateController), onError: onError);
  }

  /// Internal use only.
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

  /// see [ViewModel.reload]
  @protected
  FutureOr<void> reload();

  bool get inited => _inited;
  var _inited = false;
  var _disposed = false;

  /// see [ViewModel.init]
  @mustCallSuper
  void init() {
    assert(() {
      if (_inited) return false;
      _inited = true;
      return true;
    }(), 'init should be called only once.');
  }

  /// see [ViewModel.dispose]
  @mustCallSuper
  void dispose() {
    assert(() {
      if (_disposed) return false;
      _disposed = true;
      return true;
    }(), 'dispose should be called only once.');
  }
}
