import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_reload/flutter_reload.dart';

BuildContext? rootContext;

void globalExceptionHandle(
  exception,
  stackTrace, {
  GuardStateController? guardStateController,
  GuardExceptionHandleResult Function(dynamic, dynamic)? onError,
  required bool silent,
}) {
  exception = toNetworkException(exception, stackTrace) ?? exception;
  final errorHandlerResult = onError?.call(exception, stackTrace) ??
      GuardExceptionHandleResult.byDefault;

  if (guardStateController != null &&
      guardStateController.value is InitGuardState) {
    if (exception is CustomException) {
      if (exception.isOffline) {
        guardStateController.value = GuardState.offline;
      } else {
        // TODO: log unexpected error here
        guardStateController.value =
            ErrorGuardState<CustomException>(cause: exception);
      }
    } else {
      // TODO: log unexpected error here
      guardStateController.value = ErrorGuardState<Exception>(cause: exception);
    }
  } else {
    if (errorHandlerResult == GuardExceptionHandleResult.mute) {
      return;
    } else if (exception is CustomException) {
      if (exception.isOffline) {
        ScaffoldMessenger.of(rootContext!)
            .showSnackBar(const SnackBar(content: Text('Offline...')));
      } else {
        // TODO: log unexpected error here
        ScaffoldMessenger.of(rootContext!)
            .showSnackBar(SnackBar(content: Text(exception.message)));
      }
    } else {
      // TODO: log unexpected error here
      ScaffoldMessenger.of(rootContext!)
          .showSnackBar(SnackBar(content: Text('$exception')));
    }
  }
}

Widget? globalAbnormalStateBuilder(BuildContext context, GuardState guardState,
    DataSupplier<FutureOr<void>> dataReloader) {
  switch (guardState) {
    case InitGuardState():
      return const Center(child: CircularProgressIndicator.adaptive());
    case OfflineGuardState():
      return const Center(child: Text('Offline...'));
    case ErrorGuardState<CustomException>(cause: CustomException cause):
      return Center(child: Text('Error: ${cause.message}'));
    case ErrorGuardState<Exception>(cause: var cause):
      return Center(child: Text('Error: $cause'));
    default:
      return null;
  }
}

CustomException? toNetworkException(ex, st) {
  // Frequent bad file descriptor errors on iOS
  // https://github.com/dart-lang/http/issues/197
  const iOSDescriptorError = 'Bad file descriptor';

  switch (ex) {
    case http.ClientException ex:
      return CustomException(
          message: ex.message, stackTrace: st, isOffline: true);
    case HttpException ex
        when ex.message.contains(iOSDescriptorError) ||
            // HttpException: Connection closed before full header was received
            ex.message.contains('Connection closed before'):
      return CustomException(
          message: ex.message, stackTrace: st, isOffline: true);
    default:
      return null;
  }
}

class CustomException implements Exception {
  final dynamic message;
  final dynamic stackTrace;
  final bool isOffline;

  CustomException({
    required this.message,
    this.stackTrace,
    this.isOffline = false,
  });
}
