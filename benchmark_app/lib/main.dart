import 'package:flutter/material.dart';
import 'package:dentity/dentity.dart' as dentity;

void main() {
  runApp(const BenchmarkApp());
}

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dentity package profiler'),
        ),
        body: const BenchmarkScreen(),
      ),
    );
  }
}

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  BenchmarkScreenState createState() => BenchmarkScreenState();
}

class BenchmarkScreenState extends State<BenchmarkScreen> {
  static const runTimes = 120; // 120 fps
  static const entityCount = 10000;

  String _createBenchmarkResult = '';
  String _processBenchmarkResult = '';
  String _removalBenchmarkResult = '';

  void _runBenchmarks() {
    setState(() {
      _createBenchmarkResult = benchmarkCreate();
      _processBenchmarkResult = benchmarkProcess();
      _removalBenchmarkResult = benchmarkRemoval();
    });
  }

  String benchmarkCreate() {
    final world = dentity.createBasicExampleWorld();
    final sw = Stopwatch()..start();
    for (var i = 0; i < entityCount; i++) {
      world.createEntity([dentity.Position(0, 0), dentity.Velocity(1, 1)]);
    }
    sw.stop();
    return 'Creation benchmark took ${sw.elapsedMilliseconds}ms to create $entityCount entities';
  }

  String benchmarkProcess() {
    final world = dentity.createBasicExampleWorld();
    for (var i = 0; i < entityCount; i++) {
      world.createEntity([dentity.Position(0, 0), dentity.Velocity(1, 1)]);
    }

    final sw = Stopwatch()..start();
    for (var i = 0; i < runTimes; i++) {
      world.process();
    }
    sw.stop();
    const ops = runTimes * entityCount;
    return 'Processing benchmark took ${sw.elapsedMilliseconds}ms for $runTimes runs ($ops operations)';
  }

  String benchmarkRemoval() {
    final world = dentity.createBasicExampleWorld();
    final entities = <dentity.Entity>[];
    for (var i = 0; i < entityCount; i++) {
      entities.add(
          world.createEntity([dentity.Position(0, 0), dentity.Velocity(1, 1)]));
    }

    final sw = Stopwatch()..start();
    for (var i = 0; i < entityCount; i++) {
      world.destroyEntity(entities[i]);
    }
    sw.stop();
    return 'Removal benchmark took ${sw.elapsedMilliseconds}ms to remove $entityCount entities';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _runBenchmarks,
              child: const Text('Run Benchmarks'),
            ),
            const SizedBox(height: 16),
            const Text('Create Benchmark:'),
            Text(_createBenchmarkResult),
            const SizedBox(height: 16),
            const Text('Process Benchmark:'),
            Text(_processBenchmarkResult),
            const SizedBox(height: 16),
            const Text('Removal Benchmark:'),
            Text(_removalBenchmarkResult),
          ],
        ),
      ),
    );
  }
}
