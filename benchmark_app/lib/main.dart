import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'widgets/benchmark_widgets.dart';
import 'enhanced_benchmark_result.dart';
import 'realistic_scenarios.dart';
import 'benchmark_results_store.dart';
import 'benchmark_comparison.dart';
import 'dart:convert';
import 'web_utils.dart' if (dart.library.io) 'web_utils_stub.dart';

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
  BenchmarkBaseline? _baseline;
  BenchmarkComparison? _comparison;
  bool _useIsolate = true;

  @override
  void initState() {
    super.initState();
    _loadBaseline();
  }

  Future<void> _loadBaseline() async {
    final baseline = await BenchmarkResultsStore.loadBaseline();
    setState(() {
      _baseline = baseline;
    });
  }

  Future<void> _clearBaseline() async {
    await BenchmarkResultsStore.clearBaseline();
    setState(() {
      _baseline = null;
      _comparison = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baseline cleared')),
      );
    }
  }

  Future<void> _saveBaselineToFile() async {
    if (_results.isEmpty) return;

    try {
      final jsonString = BenchmarkResultsStore.getBaselineJson(_results);

      if (kIsWeb) {
        downloadFile(jsonString, 'benchmark_baseline.json');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Baseline downloaded')),
          );
        }
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Benchmark Baseline',
          fileName: 'benchmark_baseline.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (result == null) return;

        await BenchmarkResultsStore.saveBaselineToFile(_results, result);

        if (mounted) {
          final filename = result.split(RegExp(r'[/\\]')).last;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Baseline saved to $filename')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving baseline: $e')),
        );
      }
    }
  }

  Future<void> _loadBaselineFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final BenchmarkBaseline? baseline;

      if (kIsWeb) {
        if (file.bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to read file')),
            );
          }
          return;
        }
        final jsonString = utf8.decode(file.bytes!);
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        baseline = BenchmarkBaseline.fromJson(json);
      } else {
        if (file.path == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to get file path')),
            );
          }
          return;
        }
        baseline = await BenchmarkResultsStore.loadBaselineFromFile(file.path!);
      }

      if (baseline == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load baseline file')),
          );
        }
        return;
      }

      setState(() {
        _baseline = baseline;
      });

      _updateComparison();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Baseline loaded from ${baseline.systemInfo.platform} '
              '(${baseline.systemInfo.timestamp.split('T').first})',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading baseline: $e')),
        );
      }
    }
  }

  void _updateComparison() {
    setState(() {
      _comparison = BenchmarkComparison.compare(_baseline, _results);
    });
  }

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

    _updateComparison();
  }

  Future<void> _runBenchmark(
    String name,
    EnhancedBenchmarkResult Function(Map<String, int>) benchmarkFn,
    Map<String, int> params,
  ) async {
    setState(() {
      _currentBenchmark = name;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    final EnhancedBenchmarkResult result;
    if (_useIsolate) {
      result = await compute(benchmarkFn, params);
    } else {
      result = benchmarkFn(params);
    }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Realistic ECS Benchmarks', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        const Text('Testing with production-quality systems and realistic game scenarios'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isRunning ? null : _runAllBenchmarks,
                                icon: _isRunning
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.play_arrow),
                                label: Text(_isRunning ? 'Running Benchmarks...' : 'Run All Benchmarks'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            FilterChip(
                              label: const Text('Use Isolate'),
                              selected: _useIsolate,
                              onSelected: _isRunning ? null : (value) {
                                setState(() {
                                  _useIsolate = value;
                                });
                              },
                            ),
                          ],
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
                  if (_isRunning)
                    const LinearProgressIndicator(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_results.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.upload_file,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Compare with Baseline',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Load a baseline JSON file to compare',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _loadBaselineFromFile,
                              icon: const Icon(Icons.file_upload),
                              label: const Text('Load Baseline'),
                            ),
                            if (_baseline != null) ...[
                              const SizedBox(height: 12),
                              Chip(
                                label: Text(
                                  'Loaded: ${_baseline!.systemInfo.platform} '
                                  '(${_baseline!.systemInfo.timestamp.split('T').first})',
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: _clearBaseline,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.save_alt,
                              size: 48,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Save Results',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Save current benchmark results to file',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _saveBaselineToFile,
                              icon: const Icon(Icons.file_download),
                              label: const Text('Save to File'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_comparison != null) ...[
                PerformanceComparisonChart(comparison: _comparison!),
                const SizedBox(height: 16),
              ],
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
