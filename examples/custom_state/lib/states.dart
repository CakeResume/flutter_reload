/// Custom business states for the content viewer.
///
/// Using a sealed class ensures exhaustive pattern matching - the compiler
/// will enforce that all cases are handled in switch statements.
sealed class ContentState {
  const ContentState();
}

/// Content is ready to be displayed.
class ContentReady extends ContentState {
  final String title;
  final String body;

  const ContentReady({
    required this.title,
    required this.body,
  });
}

/// User needs a subscription to view this content.
class SubscriptionRequired extends ContentState {
  final String requiredTier;
  final String previewText;

  const SubscriptionRequired({
    required this.requiredTier,
    required this.previewText,
  });
}

/// The content has been archived and is no longer available.
class ContentArchived extends ContentState {
  final DateTime archivedAt;
  final String reason;

  const ContentArchived({
    required this.archivedAt,
    required this.reason,
  });
}

/// The service is under maintenance.
class MaintenanceMode extends ContentState {
  final String message;
  final DateTime? estimatedEndTime;

  const MaintenanceMode({
    required this.message,
    this.estimatedEndTime,
  });
}

/// Custom loading steps for init state.
enum LoadingStep {
  authenticating('Authenticating...'),
  fetchingContent('Fetching content...'),
  processingData('Processing data...');

  final String message;
  const LoadingStep(this.message);
}
