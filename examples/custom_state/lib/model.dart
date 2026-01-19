import 'dart:async';
import 'dart:math';

import 'package:flutter_reload/flutter_reload.dart';
import 'package:custom_state/states.dart';

/// A ViewModel that demonstrates custom state payloads.
///
/// This example simulates loading content that can result in different
/// business outcomes: ready, subscription required, archived, or maintenance.
class ContentViewModel extends GuardViewModel {
  ContentViewModel() : super(GuardState.init);

  /// Simulated content scenarios for demonstration.
  static const _scenarios = [
    'ready',
    'subscription',
    'archived',
    'maintenance',
  ];

  int _scenarioIndex = 0;

  @override
  FutureOr<void> reload() async {
    // Using guardRaw for manual control of state transitions.
    // This allows us to set custom payloads during both init and normal states.
    await guardRaw((guardStateController) async {
      // Simulate multi-step loading with InitGuardState payload
      guardStateController.value = const InitGuardState(
        payload: LoadingStep.authenticating,
      );
      await Future.delayed(const Duration(milliseconds: 500));

      guardStateController.value = const InitGuardState(
        payload: LoadingStep.fetchingContent,
      );
      await Future.delayed(const Duration(milliseconds: 500));

      guardStateController.value = const InitGuardState(
        payload: LoadingStep.processingData,
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // Simulate different business outcomes
      final scenario = _scenarios[_scenarioIndex % _scenarios.length];
      _scenarioIndex++;

      switch (scenario) {
        case 'ready':
          guardStateController.value = const NormalGuardState(
            payload: ContentReady(
              title: 'Welcome to flutter_reload!',
              body: 'This is an example of custom state payloads. '
                  'The content loaded successfully and is ready to display.\n\n'
                  'Tap the refresh button to see different scenarios.',
            ),
          );

        case 'subscription':
          guardStateController.value = const NormalGuardState(
            payload: SubscriptionRequired(
              requiredTier: 'Premium',
              previewText:
                  'This is a preview of premium content. Upgrade to unlock full access.',
            ),
          );

        case 'archived':
          guardStateController.value = NormalGuardState(
            payload: ContentArchived(
              archivedAt: DateTime.now().subtract(const Duration(days: 30)),
              reason:
                  'This content has been archived due to outdated information.',
            ),
          );

        case 'maintenance':
          guardStateController.value = NormalGuardState(
            payload: MaintenanceMode(
              message: 'We are performing scheduled maintenance.',
              estimatedEndTime: DateTime.now().add(const Duration(hours: 2)),
            ),
          );
      }

      notifyListeners();
    });
  }

  /// Simulate a random error to demonstrate error state.
  void triggerError() {
    guard(() {
      if (Random().nextBool()) {
        throw Exception('Simulated random error for demonstration');
      }
    });
  }
}
