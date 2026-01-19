import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reload/flutter_reload.dart';
import 'package:custom_state/view.dart';

late BuildContext rootContext;

void main() {
  ReloadConfiguration.init(
    exceptionHandle: globalExceptionHandle,
    abnormalStateBuilder: globalAbnormalStateBuilder,
  );
  runApp(const MyApp());
}

/// Global exception handler.
///
/// This handles exceptions that occur during guard operations.
void globalExceptionHandle(
  exception,
  stackTrace, {
  GuardStateController? guardStateController,
  GuardExceptionHandleResult Function(dynamic, dynamic)? onError,
  required bool silent,
}) {
  if (guardStateController?.value.isNormal ?? false) {
    // During normal operation - show snackbar
    ScaffoldMessenger.of(rootContext)
        .showSnackBar(SnackBar(content: Text('Error: $exception')));
  } else {
    // During init - set error state
    guardStateController?.value = ErrorGuardState<Exception>(cause: exception);
  }
}

/// Global abnormal state builder.
///
/// This provides default UI for system-level abnormal states:
/// - Init (loading)
/// - Offline
/// - Error
///
/// Note: Custom business states (via NormalGuardState payload) are handled
/// in GuardView's builder, NOT here.
Widget? globalAbnormalStateBuilder(
  BuildContext context,
  GuardState guardState,
  DataSupplier<FutureOr<void>> dataReloader,
) {
  switch (guardState) {
    case InitGuardState():
      // Default loading UI (can be overridden per-view)
      return const Center(child: CircularProgressIndicator.adaptive());

    case OfflineGuardState():
      return _buildErrorView(
        context,
        Icons.wifi_off,
        'You are offline',
        'Please check your internet connection.',
        dataReloader,
      );

    case ErrorGuardState<Exception>(cause: var cause):
      return _buildErrorView(
        context,
        Icons.error_outline,
        'Something went wrong',
        cause.toString(),
        dataReloader,
      );

    default:
      return null;
  }
}

Widget _buildErrorView(
  BuildContext context,
  IconData icon,
  String title,
  String message,
  DataSupplier<FutureOr<void>> dataReloader,
) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: dataReloader,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom State Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) {
          rootContext = context;
          return const ContentView();
        },
      ),
    );
  }
}
