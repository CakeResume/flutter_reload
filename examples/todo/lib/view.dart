import 'package:flutter/material.dart';
import 'package:flutter_reload/flutter_reload.dart';
import 'package:todo/main.dart';
import 'package:todo/model.dart';

class TodoListView extends StatefulWidget {
  const TodoListView({super.key});

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  final todoViewModel = TodoViewModel();

  @override
  void initState() {
    super.initState();
    todoViewModel.reload();
  }

  @override
  Widget build(BuildContext context) {
    rootContext = context;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO List'),
      ),
      body: GuardView(
        model: todoViewModel,
        builder: (context) {
          return ListenableWidget(
            model: todoViewModel,
            builder: (context) {
              return ListView.builder(
                itemCount: todoViewModel.todos.length,
                itemBuilder: (context, index) {
                  final todo = todoViewModel.todos[index];
                  return ListTile(
                    leading: Checkbox(
                      value: todo.completed,
                      onChanged: (value) => todoViewModel.toggleTodo(todo.id),
                    ),
                    title: Text(todo.title),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => todoViewModel.deleteTodo(todo.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTodoTitle = await showDialog<String>(
            context: context,
            builder: (context) {
              return const AddTodoDialog();
            },
          );
          if (newTodoTitle != null) {
            todoViewModel.addTodo(newTodoTitle);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTodoDialog extends StatefulWidget {
  const AddTodoDialog({super.key});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add TODO'),
      content: TextField(
        controller: _textController,
        decoration: const InputDecoration(hintText: 'Enter TODO title'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _textController.text),
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
