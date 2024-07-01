part of '../reload.dart';

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

class BeforeInitGuardState extends GuardState {
  const BeforeInitGuardState() : super();

  @override
  bool get isNormal => false;

  @override
  bool get isError => false;
}

class InitGuardState extends GuardState {
  const InitGuardState() : super();

  @override
  bool get isNormal => false;

  @override
  bool get isError => false;
}

class NormalGuardState extends GuardState {
  const NormalGuardState() : super();

  @override
  bool get isNormal => true;

  @override
  bool get isError => false;
}

class OfflineGuardState extends GuardState {
  const OfflineGuardState() : super();

  @override
  bool get isNormal => false;

  @override
  bool get isError => false;
}

class ErrorGuardState<T> extends GuardState {
  final T cause;
  const ErrorGuardState({required this.cause}) : super();

  @override
  bool get isNormal => false;

  @override
  bool get isError => true;
}
