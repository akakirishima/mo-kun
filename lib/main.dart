import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GDGoC 2026 Prototype',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        scaffoldBackgroundColor: const Color(0xFFF5F7F2),
      ),
      home: const BootstrapHomePage(),
    );
  }
}

class BootstrapHomePage extends StatelessWidget {
  const BootstrapHomePage({super.key});

  static const setupItems = <String>[
    'Flutter 3.41.2 stable',
    'Android target ready',
    'README setup guide updated',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('GDGoC 2026 Prototype'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: _buildBodyChildren(context),
      ),
    );
  }

  List<Widget> _buildBodyChildren(BuildContext context) {
    return [
      Text('自分育成たまごっち（仮称）', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text(
        'Flutter 環境構築が完了し、Android 向けの最小アプリが起動できる状態です。',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildChecklistChildren(context),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Next step: replace this bootstrap screen with the first UI prototype.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ];
  }

  List<Widget> _buildChecklistChildren(BuildContext context) {
    final children = <Widget>[
      Text(
        'Bootstrap checklist',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
    ];

    children.addAll(_buildSetupItems(context));
    return children;
  }

  List<Widget> _buildSetupItems(BuildContext context) {
    return setupItems
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item)),
              ],
            ),
          ),
        )
        .toList();
  }
}
