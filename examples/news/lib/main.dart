import 'package:flutter/material.dart';
import 'package:flutter_reload/flutter_reload.dart';
import 'package:news/model.dart';
import 'package:news/util.dart';
import 'package:news/view.dart';

void main() {
  /// must call [ReloadConfiguration.init] to setup
  /// exception handler and abnormal state's UI
  ReloadConfiguration.init(
    abnormalStateBuilder: globalAbnormalStateBuilder,
    exceptionHandle: globalExceptionHandle,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HackNews',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeView(title: 'HackNews'),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.title});

  final String title;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final hackNewsViewModel = HackNewsViewModel();

  @override
  void initState() {
    super.initState();
    hackNewsViewModel.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Builder(
        builder: (context) {
          rootContext = context;
          return Center(child: HackNewsListView(model: hackNewsViewModel));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: hackNewsViewModel.reload,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
