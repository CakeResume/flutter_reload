part of '../reload.dart';

const _guardViewControllerZonedKey = '_@guardViewControllerZone@_';

class GuardViewController extends ValueNotifier<GuardState> {
  GuardViewController([super.value = const NormalGuardState()]);

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

abstract class GuardViewChangeNotifier extends ChangeNotifier
    with GuardViewNotifierMixin
    implements ViewModel {
  GuardViewChangeNotifier(GuardState state, {this.parent})
      : guardViewController = GuardViewController(state);

  @override
  final GuardViewController guardViewController;

  @override
  final GuardViewNotifierMixin? parent;
}

abstract class GuardViewEventNotifier<T> extends GuardViewChangeNotifier
    with EventNotifier<T> //only for fit Riverpod's dispose lifecycle
{
  GuardViewEventNotifier(super.state, {super.parent});
}

enum GuardExceptionHandleResult {
  // [Guard] will handle it through default behavior.
  byDefault,
  // [Guard] won't handle it. So mute the default behavior.
  mute,
  muteOnlyForOffline;

  bool get shouldHandleOffline => this == byDefault;
}

mixin GuardViewNotifierMixin {
  GuardViewController get guardViewController;
  GuardViewNotifierMixin? get parent;

  FutureOr<T?> guard<T>(
    DataSupplier<FutureOr<T?>> action, {
    GuardExceptionHandleResult Function(dynamic exception, dynamic stacktrace)?
        onError,
  }) async {
    if (Zone.current[_guardViewControllerZonedKey] != null) {
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
              guardViewController:
                  parent?.guardViewController ?? guardViewController,
              onError: onError,
            );
            return null;
          }
        },
        zoneValues: {_guardViewControllerZonedKey: guardViewController},
        (Object ex, StackTrace st) async {
          ReloadConfiguration.instance.exceptionHandle(
            ex,
            st,
            silent: parent != null,
            guardViewController:
                parent?.guardViewController ?? guardViewController,
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
