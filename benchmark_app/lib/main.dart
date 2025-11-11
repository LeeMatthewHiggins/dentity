import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dentity/dentity_examples.dart';
import 'widgets/benchmark_widgets.dart';

EnhancedBenchmarkResult _runSpaceShooter(Map<String, int> params) {
  return RealisticScenarios.spaceShooter(
    bulletCount: params['bulletCount']!,
    enemyCount: params['enemyCount']!,
    particleCount: params['particleCount']!,
    frameCount: params['frameCount']!,
  );
}

EnhancedBenchmarkResult _runRtsUnits(Map<String, int> params) {
  return RealisticScenarios.rtsUnits(
    unitCount: params['unitCount']!,
    buildingCount: params['buildingCount']!,
    frameCount: params['frameCount']!,
  );
}

EnhancedBenchmarkResult _runArchetypeChaos(Map<String, int> params) {
  return RealisticScenarios.archetypeChaos(
    entityCount: params['entityCount']!,
    frameCount: params['frameCount']!,
  );
}

EnhancedBenchmarkResult _runStatusEffects(Map<String, int> params) {
  return RealisticScenarios.statusEffects(
    entityCount: params['entityCount']!,
    frameCount: params['frameCount']!,
  );
}

void main() {
  runApp(const BenchmarkApp());
}

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dentity ECS Profiler',
      theme: ThemeData.dark(),
      home: const BenchmarkScreen(),
    );
  }
}

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  BenchmarkScreenState createState() => BenchmarkScreenState();
}

class BenchmarkScreenState extends State<BenchmarkScreen> {
  final List<EnhancedBenchmarkResult> _results = [];
  bool _isRunning = false;
  String _currentBenchmark = '';
  int _completedBenchmarks = 0;
  final int _totalBenchmarks = 4;

  Future<void> _runAllBenchmarks() async {
    setState(() {
      _results.clear();
      _isRunning = true;
      _completedBenchmarks = 0;
    });

    await _runBenchmark(
      'Space Shooter (61K entities)',
      _runSpaceShooter,
      {
        'bulletCount': 50000,
        'enemyCount': 10000,
        'particleCount': 1000,
        'frameCount': 120,
      },
    );

    await _runBenchmark(
      'RTS Units (5.1K entities)',
      _runRtsUnits,
      {
        'unitCount': 5000,
        'buildingCount': 100,
        'frameCount': 120,
      },
    );

    await _runBenchmark(
      'Archetype Chaos (10K entities)',
      _runArchetypeChaos,
      {
        'entityCount': 10000,
        'frameCount': 120,
      },
    );

    await _runBenchmark(
      'Status Effects (1K entities)',
      _runStatusEffects,
      {
        'entityCount': 1000,
        'frameCount': 120,
      },
    );

    setState(() {
      _isRunning = false;
      _currentBenchmark = '';
    });
  }

  Future<void> _runBenchmark(
    String name,
    EnhancedBenchmarkResult Function(Map<String, int>) benchmarkFn,
    Map<String, int> params,
  ) async {
    setState(() {
      _currentBenchmark = name;
    });

    await Future.delayed(const Duration(milliseconds: 50));

    final result = await compute(benchmarkFn, params);

    setState(() {
      _results.add(result);
      _completedBenchmarks++;
    });

    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dentity ECS Profiler'),
        actions: [
          if (!_isRunning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _runAllBenchmarks,
              tooltip: 'Run All Benchmarks',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Realistic ECS Benchmarks', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Testing with production-quality systems and realistic game scenarios'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isRunning ? null : _runAllBenchmarks,
                      icon: _isRunning
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow),
                      label: Text(_isRunning ? 'Running Benchmarks...' : 'Run All Benchmarks'),
                    ),
                    if (_isRunning) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: _completedBenchmarks / _totalBenchmarks),
                      const SizedBox(height: 8),
                      Text('$_completedBenchmarks / $_totalBenchmarks completed',
                        style: Theme.of(context).textTheme.bodySmall),
                      if (_currentBenchmark.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Running: $_currentBenchmark',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_results.isNotEmpty) ...[
              SummaryDashboard(results: _results),
              const SizedBox(height: 16),
              ScenarioComparisonChart(results: _results),
              const SizedBox(height: 16),
              ThroughputComparisonChart(results: _results),
              const SizedBox(height: 24),
              Text('System Performance', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ..._results.map((result) => Column(
                children: [
                  SystemPerformanceBreakdown(result: result),
                  const SizedBox(height: 24),
                ],
              )),
            ],
          ],
        ),
      ),
    );
  }
}
