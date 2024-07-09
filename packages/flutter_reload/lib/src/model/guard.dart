part of '../reload.dart';

/// A base class representing the state of a guard mechanism.
///
/// This class is designed to be extended to represent various states that a guard can be in.
/// The states are defined as static constants for easy access.
///
/// The basic idea for state change is:
/// - BeforeInit: Indicates a state that has not been initialized yet.
/// - Init: A common view initialization state. The view depends on async data
///         to display its UI. We set this state because the view is loading
///         the data.
/// - Normal: After loading data, the view now has enough information to display
///           the UI, and the user is ready to interact with this view.
/// - Offline: This state is classified as a separate state
///            because the connectivity is usually unstable.
/// - Error: This state is usually set when an exception occurs during the [Init] state.
///
/// Subclasses should override the [isNormal] and [isError] getters to indicate their specific state.
///
/// Available states:
/// - [BeforeInitGuardState]: The guard is not yet initialized.
/// - [InitGuardState]: The guard is in the initialization process.
/// - [NormalGuardState]: The guard is in a normal, operational state.
/// - [OfflineGuardState]: The guard is offline.
/// - [ErrorGuardState]: The guard has encountered an error.
///
/// Properties:
/// - [isNormal]: Indicates whether the guard is in a normal state. Must be overridden by subclasses.
/// - [isError]: Indicates whether the guard is in an error state. Must be overridden by subclasses.
sealed class GuardState {
  const GuardState();
  static GuardState beforeInit = const BeforeInitGuardState();
  static GuardState init = const InitGuardState();
  static GuardState normal = const NormalGuardState();
  static GuardState offline = const OfflineGuardState();

  @mustCallSuper
  bool get isNormal;

  @mustCallSuper
  bool get isError;
}

/// Indicates a state that has not been initialized yet.
///
/// see [GuardState]
class BeforeInitGuardState extends GuardState {
  const BeforeInitGuardState() : super();

  @override
  bool get isNormal => false;

  @override
  bool get isError => false;
}

/// A common view initialization state. The view depends on async data
/// to display its UI. We set this state because the view is loading
/// the data.
///
/// see [GuardState]
class InitGuardState extends GuardState {
  const InitGuardState() : super();

  @override
  bool get isNormal => false;

  @override
  bool get isError => false;
}

/// After loading data, the view now has enough information to display
/// the UI, and the user is ready to interact with this view.
///
/// see [GuardState]
class NormalGuardState extends GuardState {
  const NormalGuardState() : super();

  @override
  bool get isNormal => true;

  @override
  bool get isError => false;
}

/// This state is classified as a separate state
/// because the connectivity is usually unstable.
///
/// see [GuardState]
class OfflineGuardState extends GuardState {
  const OfflineGuardState() : super();

  @override
  bool get isNormal => false;

  @override
  bool get isError => false;
}

/// This state is usually set when an exception occurs during the [Init] state.
///
/// see [GuardState]
class ErrorGuardState<T> extends GuardState {
  final T cause;
  const ErrorGuardState({required this.cause}) : super();

  @override
  bool get isNormal => false;

  @override
  bool get isError => true;
}
