part of '../reload.dart';

typedef DataSupplier<T> = T Function();
typedef DataConverter<R, T> = R Function(T data);
typedef EventListener<T> = void Function(T event);
typedef EventAction = void Function();

class DataEvent<T> {
  final T type;
  final dynamic data;

  DataEvent(this.type, this.data);
}

abstract class NotifierBase<E> {
  @protected
  final listeners = <E>[];
  void addEventListener(E listener) {
    assert(!listeners.contains(listener));
    listeners.add(listener);
  }

  void removeEventListener(E listener) {
    assert(listeners.contains(listener));
    listeners.remove(listener);
  }
}

class ChangeListener<T> {
  final Listenable model;
  final DataSupplier<T> observer;
  final EventAction onChanged;
  T _value;
  T get value {
    assert(observer() == _value);
    return _value;
  }

  ChangeListener({
    required this.model,
    required this.observer,
    required this.onChanged,
  }) : _value = observer() {
    model.addListener(_onModelUpdated);
  }

  void _onModelUpdated() {
    final oldValue = _value;
    _value = observer();
    if (oldValue != _value) {
      onChanged();
    }
  }

  void dispose() {
    model.removeListener(_onModelUpdated);
  }
}
