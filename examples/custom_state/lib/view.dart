import 'package:flutter/material.dart';
import 'package:flutter_reload/flutter_reload.dart';
import 'package:custom_state/model.dart';
import 'package:custom_state/states.dart';

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  final viewModel = ContentViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom State Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.reload,
            tooltip: 'Try different scenario',
          ),
        ],
      ),
      body: GuardView(
        model: viewModel,
        // Custom abnormalStateBuilder to handle InitGuardState with payload
        abnormalStateBuilder: (context, state, reload) {
          if (state case InitGuardState<LoadingStep>(:var payload)) {
            return _buildLoadingView(payload);
          }
          // Return null to use default handling for other abnormal states
          return null;
        },
        // The builder handles all NormalGuardState cases (including custom payloads)
        builder: (context) {
          return ListenableWidget(
            model: viewModel,
            builder: (context) {
              final state = viewModel.guardState;

              // Pattern match on NormalGuardState with payload
              if (state case NormalGuardState<ContentState>(:var payload)) {
                // Exhaustive switch - compiler ensures all cases are handled!
                return switch (payload) {
                  ContentReady(:var title, :var body) =>
                    _buildContentReadyView(title, body),
                  SubscriptionRequired(:var requiredTier, :var previewText) =>
                    _buildSubscriptionView(requiredTier, previewText),
                  ContentArchived(:var archivedAt, :var reason) =>
                    _buildArchivedView(archivedAt, reason),
                  MaintenanceMode(:var message, :var estimatedEndTime) =>
                    _buildMaintenanceView(message, estimatedEndTime),
                  // null case: NormalGuardState without payload (standard ready state)
                  null => const Center(child: Text('Content Ready')),
                };
              }

              // Fallback (shouldn't reach here if isNormal is true)
              return const Center(child: Text('Ready'));
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingView(LoadingStep? step) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator.adaptive(),
          const SizedBox(height: 16),
          Text(
            step?.message ?? 'Loading...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildContentReadyView(String title, String body) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildSubscriptionView(String tier, String previewText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            Text(
              '$tier Subscription Required',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              previewText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Upgrade flow would start here')),
                );
              },
              icon: const Icon(Icons.star),
              label: Text('Upgrade to $tier'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedView(DateTime archivedAt, String reason) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.archive, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              'Content Archived',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Archived on: ${archivedAt.toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceView(String message, DateTime? estimatedEndTime) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            Text(
              'Under Maintenance',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (estimatedEndTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Estimated completion: ${estimatedEndTime.hour}:${estimatedEndTime.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: viewModel.reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}
