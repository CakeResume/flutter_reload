import 'dart:async';
import 'dart:convert';

import 'package:flutter_reload/flutter_reload.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo/entity.dart';

class TodoViewModel extends GuardViewModel {
  final _todos = <Todo>[];
  List<Todo> get todos => _todos;

  TodoViewModel() : super(GuardState.init) {
    reload();
  }

  @override
  FutureOr<void> reload() async {
    await guardReload(() async {
      // In a real-world scenario, you would fetch data from an API or database here.
      // For this example, we'll just simulate loading data.
      await Future.delayed(const Duration(seconds: 2));
      _loadTodos();
      notifyListeners();
    });
  }

  void addTodo(String title) {
    guard(() {
      final newTodo = Todo(
          id: DateTime.now().millisecondsSinceEpoch.toString(), title: title);
      _todos.add(newTodo);
      _saveTodos();
      notifyListeners();
    });
  }

  void toggleTodo(String id) {
    guard(() {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todos[index] =
            _todos[index].copyWith(completed: !_todos[index].completed);
        _saveTodos();
        notifyListeners();
      }
    });
  }

  void deleteTodo(String id) {
    guard(() {
      _todos.removeWhere((todo) => todo.id == id);
      _saveTodos();
      notifyListeners();
    });
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = prefs.getString('todos');
    if (todosJson != null) {
      final List<dynamic> decodedJson = jsonDecode(todosJson);
      _todos.clear();
      _todos.addAll(decodedJson.map((e) => Todo.fromJson(e)).toList());
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = jsonEncode(_todos.map((e) => e.toJson()).toList());
    await prefs.setString('todos', todosJson);
  }
}
