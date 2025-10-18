import 'package:flutter/material.dart';
import 'package:dentity/dentity_examples.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const BenchmarkApp());
}

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  final List<BenchmarkResult> _results = [];
  bool _isRunning = false;
  String _currentBenchmark = '';
  int _completedBenchmarks = 0;
  final int _totalBenchmarks = 6;

  Future<void> _runAllBenchmarks() async {
    setState(() {
      _results.clear();
      _isRunning = true;
      _completedBenchmarks = 0;
    });

    await _runBenchmark('Creation (65K entities)', () => Benchmarks.creation(
      entityCount: BenchmarkConstants.largeEntityCount,
      enableStats: true,
    ));

    await _runBenchmark('Processing (65K entities × 120 frames)', () => Benchmarks.processing(
      entityCount: BenchmarkConstants.largeEntityCount,
      runTimes: BenchmarkConstants.defaultRunTimes,
      enableStats: true,
    ));

    await _runBenchmark('Removal (65K entities)', () => Benchmarks.removal(
      entityCount: BenchmarkConstants.largeEntityCount,
      enableStats: true,
    ));

    await _runBenchmark('Entity Recycling (16K entities)', () => Benchmarks.recycling(
      entityCount: BenchmarkConstants.mediumEntityCount,
      enableStats: true,
    ));

    await _runBenchmark('Mixed Workload (120 frames)', () => Benchmarks.mixedWorkload(
      runTimes: BenchmarkConstants.defaultRunTimes,
      enableStats: true,
    ));

    await _runBenchmark('Stats Overhead (16K entities × 1000 runs)', () => Benchmarks.statsOverhead(
      entityCount: BenchmarkConstants.mediumEntityCount,
      runTimes: BenchmarkConstants.defaultRunTimes,
    ));

    setState(() {
      _isRunning = false;
      _currentBenchmark = '';
    });
  }

  Future<void> _runBenchmark(String name, BenchmarkResult Function() benchmark) async {
    setState(() {
      _currentBenchmark = name;
    });

    await Future.delayed(const Duration(milliseconds: 50));

    final result = benchmark();

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
                    Text('Industry-Standard ECS Benchmarks', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Testing with ${BenchmarkConstants.largeEntityCount.toString()} entities (65K)',
                      style: Theme.of(context).textTheme.bodyMedium),
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
              BenchmarkResultsChart(results: _results),
              const SizedBox(height: 16),
              Text('Benchmark Results', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ..._results.map((result) => BenchmarkResultCard(result: result)),
            ],
          ],
        ),
      ),
    );
  }
}

class BenchmarkResultCard extends StatelessWidget {
  final BenchmarkResult result;

  const BenchmarkResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(result.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: result is StatsOverheadResult
          ? Text('${(result as StatsOverheadResult).overheadPercent.toStringAsFixed(2)}% overhead - ${result.durationMs}ms slower with stats')
          : Text('${result.durationMs}ms - ${_formatLargeNumber(result.operationsPerSecond)} ops/s'),
        children: [
          if (result.stats != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result is StatsOverheadResult) ...[
                    _buildStatRow('Without Stats', '${(result as StatsOverheadResult).durationWithoutStatsMs}ms'),
                    _buildStatRow('With Stats', '${(result as StatsOverheadResult).durationWithStatsMs}ms'),
                    _buildStatRow('Overhead', '${result.durationMs}ms (${(result as StatsOverheadResult).overheadPercent.toStringAsFixed(2)}%)'),
                    _buildStatRow('Entity Count', result.entityCount.toString()),
                    _buildStatRow('Operations', result.operations.toString()),
                  ] else ...[
                    _buildStatRow('Entity Count', result.entityCount.toString()),
                    _buildStatRow('Duration', '${result.durationMs}ms (${result.durationMicros.toInt()}μs)'),
                    _buildStatRow('Operations', result.operations.toString()),
                    const Divider(),
                    Text('Throughput Metrics', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildStatRow('ops/s', _formatLargeNumber(result.operationsPerSecond)),
                    _buildStatRow('entities/s', _formatLargeNumber(result.entitiesPerSecond)),
                    const Divider(),
                    Text('Cost Metrics', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildStatRow('ns/op', result.nanosPerOperation.toStringAsFixed(2)),
                    _buildStatRow('ns/entity', result.nanosPerEntity.toStringAsFixed(2)),
                  ],
                  const Divider(),
                  Text('Entity Stats', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildStatRow('Active', result.stats!.entities.activeCount.toString()),
                  _buildStatRow('Total Created', result.stats!.entities.totalCreated.toString()),
                  _buildStatRow('Total Destroyed', result.stats!.entities.totalDestroyed.toString()),
                  _buildStatRow('Recycled', result.stats!.entities.recycledCount.toString()),
                  _buildStatRow('Peak', result.stats!.entities.peakCount.toString()),
                  if (result.stats!.systems.isNotEmpty) ...[
                    const Divider(),
                    Text('System Performance', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...result.stats!.systems.map((sys) => _buildStatRow(
                          sys.name,
                          '${sys.averageTimeMs.toStringAsFixed(3)}ms avg',
                        )),
                  ],
                  if (result.stats!.archetypes.totalArchetypes > 0) ...[
                    const Divider(),
                    Text('Archetypes', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildStatRow('Total Archetypes', result.stats!.archetypes.totalArchetypes.toString()),
                    _buildStatRow('Total Entities', result.stats!.archetypes.totalEntities.toString()),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatLargeNumber(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    } else {
      return value.toStringAsFixed(2);
    }
  }
}

class BenchmarkResultsChart extends StatelessWidget {
  final List<BenchmarkResult> results;

  const BenchmarkResultsChart({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final throughputResults = results.where((r) => r is! StatsOverheadResult).toList();
    final statsOverhead = results.whereType<StatsOverheadResult>().firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Benchmark Durations (ms)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < results.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: Text(
                                  results[index].name,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}ms'),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: results.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.durationMs.toDouble(),
                          color: _getColorForBenchmark(entry.value.name),
                          width: 24,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            if (throughputResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Throughput (Million ops/s)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < throughputResults.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: Text(
                                  throughputResults[index].name,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(1)}M'),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: throughputResults.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.operationsPerSecond / 1000000,
                          color: _getColorForBenchmark(entry.value.name),
                          width: 24,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            ],
            if (statsOverhead != null) ...[
              const SizedBox(height: 16),
              Text('Stats Collection Overhead', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    gridData: const FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('Without\nStats');
                            if (value == 1) return const Text('With\nStats');
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) => Text('${value.toInt()}ms'),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: statsOverhead.durationWithoutStatsMs.toDouble(),
                            color: Colors.green,
                            width: 40,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: statsOverhead.durationWithStatsMs.toDouble(),
                            color: Colors.yellow,
                            width: 40,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Overhead: ${statsOverhead.durationMs}ms (${statsOverhead.overheadPercent.toStringAsFixed(2)}%)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.yellow),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColorForBenchmark(String name) {
    switch (name) {
      case 'Creation':
        return Colors.blue;
      case 'Processing':
        return Colors.green;
      case 'Removal':
        return Colors.red;
      case 'Entity Recycling':
        return Colors.orange;
      case 'Mixed Workload':
        return Colors.purple;
      case 'Stats Overhead':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}
