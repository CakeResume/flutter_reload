# flutter_reload
Simplifies error handling by managing low-level errors, allowing developers to focus solely on business logic.

## Why use `flutter_reload`
We love and usually choose one of many state management mechanisms as our base architecture.
In many cases, such as using networking APIs, there is always a need for a “when” condition to handle exceptions in each view.

`Flutter_reload` tries to create a lightweight layer to handle all common error cases.
With an additional protection `guard`, we don’t need to manage each abnormal case for each UI and model anymore,
e.g. network error, storage error, programming exception.
We call such enjoyable development experience as `without exception awareness`. :D :)

*Concept with exception awareness in UI*
```dart
Widget build(BuildContext context) {
  switch (result) {
    case loading:
      return Text('Loading view data...');
    case error:
      return Text('Load data failed.');
    case data(data):
      return Text('Yes!! Here is the $data!!');
  }
}
```

*Concept without exception awareness in UI*
```dart
Widget build(BuildContext context) {
  return GuardView(
    builder: (context) {
      return Text('Yes!! Here is the ${result.data}!!');
    }
  )
}
```

*Concept with exception awareness in Model*
```dart
Future<void> createTodo(Todo todo) {
  try {
    state = Result.loading();
    final data = await todoService.createTodo();
    state = Result.success(Todo.fromJson(data));
  } catch (ex) {
    if (ex is NetworkException) {
      state = Result.error(ex);
    } else if ...
  }
}
```

*Concept without exception awareness in Model*
```dart
Future<void> createTodo(Todo todo) {
  await guard(() {
    final data = await todoService.createTodo();
    state = Result.success(Todo.fromJson(data));
  });
}
```

## Install
Follow the [pub.dev's install site](https://pub.dev/packages/flutter_reload/install) to install this package.

After the installation, you can easily integrate flutter_reload with three major steps:

1. Initiate configuration for `exception handling` and `abnormal UI builder`.

```dart
void main() {
  ReloadConfiguration.init(
    abnormalStateBuilder: globalAbnormalStateBuilder,
    exceptionHandle: globalExceptionHandle,
  );
  runApp(const MyApp());
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

void globalExceptionHandle(
  exception,
  stackTrace, {
  GuardStateController? guardStateController,
  GuardExceptionHandleResult Function(dynamic, dynamic)? onError,
  required bool silent,
}) {
  final errorHandlerResult = onError?.call(exception, stackTrace) ??
      GuardExceptionHandleResult.byDefault;

  if (guardStateController != null &&
      guardStateController.value is InitGuardState) {
    
    // TODO: log unexpected error here
    guardStateController.value = ErrorGuardState<Exception>(cause: exception);
  } else {
    if (errorHandlerResult == GuardExceptionHandleResult.mute) {
      return;
    } else {
      // TODO: log unexpected error here
      ScaffoldMessenger.of(rootContext!)
          .showSnackBar(SnackBar(content: Text('$exception')));
    }
  }
}
```

2. support reload lifecycle in your (UI) model.

```dart
class MyViewModel extends GuardViewModel {
  final randomWords = <String>[];

  MyViewModel() : super(GuardState.init);

  @override
  FutureOr<void> reload() async {
    await guard(() async {
      guardStateController.value = GuardState.init;
      randomWords..clear()..addAll(await myNetworkService.getRandomWordsFromServer());
      guardStateController.value = GuardState.normal;
      notifyListeners();
    });
  }
}
```

3. use `GuardView()` for your UI.

```dart
@override
Widget build(BuildContext context) {
  return GuardView(
    model: myViewModel,
    builder: (context) {
      return ListenableWidget(
        model: myViewModel,
        builder: (context) {
          return ListView.separated(
            itemBuilder: (BuildContext context, int index) {
              final rowData = myViewModel.randomWords[index];
              return ListTile(
                key: ValueKey(rowData),
                title: Text(rowData),
              );
            },
            separatorBuilder: (context, index) => const Divider(),
            itemCount: myViewModel.randomWords.length,
          );
        },
      );
    },
  );
}
```

## Architecture
![Architecture](resources/layer_design.png)

## Lifecycle
![Architecture](resources/lifecycle.png)
