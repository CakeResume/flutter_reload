part of '../reload.dart';

/// A base class representing the state of a guard mechanism.
///
/// ## State Machine
///
/// The guard state machine follows a simple lifecycle:
/// ```
/// BeforeInit -> Init -> Normal (success)
///                    -> Error/Offline (failure)
/// ```
///
/// ## Design Philosophy: Two-Layer State
///
/// GuardState separates concerns into two layers:
///
/// 1. **System layer** (GuardState): Is the data loaded?
///    - [InitGuardState]: Loading in progress
///    - [NormalGuardState]: Loading completed successfully
///    - [ErrorGuardState]: An unexpected error occurred
///    - [OfflineGuardState]: Network connectivity issue
///
/// 2. **Business layer** (payload): What is the outcome?
///    - [InitGuardState] and [NormalGuardState] accept an optional generic [payload]
///    - Use payload to represent business-level states without creating new guard states
///
/// ## Custom States via Payload
///
/// Instead of creating new guard state types, use the [payload] field in
/// [InitGuardState] or [NormalGuardState] to carry custom business states:
///
/// ```dart
/// // Define your business states as a sealed class
/// sealed class ContentState {}
/// class ContentReady extends ContentState { ... }
/// class SubscriptionRequired extends ContentState { ... }
/// class MaintenanceMode extends ContentState { ... }
///
/// // Set custom state via payload
/// guardStateController.value = NormalGuardState(
///   payload: SubscriptionRequired(tier: 'premium'),
/// );
///
/// // Handle in GuardView's builder (NOT abnormalStateBuilder)
/// builder: (context) {
///   if (viewModel.guardState case NormalGuardState(:var payload)) {
///     return switch (payload) {
///       null => ContentWidget(),
///       SubscriptionRequired(:var tier) => UpgradePrompt(tier),
///       MaintenanceMode() => MaintenanceWidget(),
///       // Compiler enforces exhaustive handling for sealed classes
///     };
///   }
///   return const SizedBox();
/// }
/// ```
///
/// ## Available States
///
/// - [BeforeInitGuardState]: The guard is not yet initialized.
/// - [InitGuardState]: Loading in progress. Supports optional payload for loading context.
/// - [NormalGuardState]: Loading completed. Supports optional payload for business outcomes.
/// - [OfflineGuardState]: Network connectivity issue.
/// - [ErrorGuardState]: An unexpected error occurred.
///
/// ## Properties
///
/// - [isNormal]: Returns true only for [NormalGuardState].
/// - [isError]: Returns true only for [ErrorGuardState].
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
/// The optional [payload] allows carrying custom loading context,
/// such as loading progress or current loading step.
///
/// Example with loading steps:
/// ```dart
/// enum LoadingStep { authenticating, fetchingData, processingData }
///
/// guardStateController.value = InitGuardState(payload: LoadingStep.fetchingData);
/// ```
///
/// see [GuardState]
class InitGuardState<T extends Object> extends GuardState {
  /// Optional payload for custom loading context.
  final T? payload;

  const InitGuardState({this.payload}) : super();

  @override
  bool get isNormal => false;

  @override
  bool get isError => false;
}

/// After loading data, the view now has enough information to display
/// the UI, and the user is ready to interact with this view.
///
/// **Design Philosophy**: "Normal" means the system successfully completed
/// loading and determined an outcome. It does not mean "everything is fine".
/// The [payload] describes the business-level outcome.
///
/// The optional [payload] allows carrying custom business states,
/// such as subscription requirements, maintenance mode, or content status.
/// This enables separation of concerns:
/// - **Guard layer** (system): Is the data loaded? (Init/Normal/Error)
/// - **Business layer** (app): What is the business outcome? (payload)
///
/// Example with business states:
/// ```dart
/// sealed class ContentState {}
/// class ContentReady extends ContentState { final String content; ... }
/// class SubscriptionRequired extends ContentState { final String tier; ... }
///
/// // In ViewModel
/// guardStateController.value = NormalGuardState(
///   payload: SubscriptionRequired(tier: 'premium'),
/// );
///
/// // In GuardView builder (NOT abnormalStateBuilder)
/// builder: (context) {
///   if (viewModel.guardState case NormalGuardState(:var payload)) {
///     return switch (payload) {
///       null => ContentWidget(),
///       ContentReady(:var content) => Text(content),
///       SubscriptionRequired(:var tier) => UpgradePrompt(tier: tier),
///     };
///   }
///   return const SizedBox();
/// }
/// ```
///
/// see [GuardState]
class NormalGuardState<T extends Object> extends GuardState {
  /// Optional payload for custom business state.
  final T? payload;

  const NormalGuardState({this.payload}) : super();

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
