import 'package:flutter/material.dart';
import 'package:flutter_reload/flutter_reload.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:news/model.dart';
import 'package:news/util.dart';
import 'package:news/view.dart';

void main() {
  ReloadConfiguration.init(
    abnormalStateBuilder: globalAbnormalStateBuilder,
    exceptionHandle: globalExceptionHandle,
  );
  runApp(const ProviderScope(child: MyApp()));
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

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key, required this.title});

  final String title;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _HomeViewState();
  }
}

class _HomeViewState extends ConsumerState<HomeView> {
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
          return const Center(child: HackNewsListView());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ref.read(hackNewsProvider).reload,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
