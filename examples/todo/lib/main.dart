import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reload/flutter_reload.dart';
import 'package:todo/view.dart';

late BuildContext rootContext;

void main() {
  ReloadConfiguration.init(
    exceptionHandle: globalExceptionHandle,
    abnormalStateBuilder: globalAbnormalStateBuilder,
  );
  runApp(const MyApp());
}

// Global exception and abnormal state handling (replace with your own implementation)
void globalExceptionHandle(
  exception,
  stackTrace, {
  GuardStateController? guardStateController,
  GuardExceptionHandleResult Function(dynamic, dynamic)? onError,
  required bool silent,
}) {
  if (guardStateController?.value.isNormal ?? false) {
    ScaffoldMessenger.of(rootContext)
        .showSnackBar(SnackBar(content: Text('$exception')));
  } else {
    guardStateController?.value = ErrorGuardState<Exception>(cause: exception);
  }
}

Widget? globalAbnormalStateBuilder(
  BuildContext context,
  GuardState guardState,
  DataSupplier<FutureOr<void>> dataReloader,
) {
  switch (guardState) {
    case InitGuardState():
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    case OfflineGuardState():
      return _buildErrorView('Offline...', dataReloader);
    case ErrorGuardState<Exception>(cause: var cause):
      return _buildErrorView('Error: $cause', dataReloader);
    default:
      return null;
  }
}

Widget _buildErrorView(
  String errorText,
  DataSupplier<FutureOr<void>> dataReloader,
) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(errorText),
        ElevatedButton(
          onPressed: dataReloader,
          child: const Text('Reload'),
        ),
      ],
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TodoListView(),
    );
  }
}
