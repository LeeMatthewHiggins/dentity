import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dentity/dentity_examples.dart';

class SummaryDashboard extends StatelessWidget {
  final List<EnhancedBenchmarkResult> results;

  const SummaryDashboard({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final totalEntities = results.fold<int>(0, (sum, r) => sum + r.entityCount);
    final totalSystems = results.fold<int>(0, (sum, r) => sum + (r.systemBreakdown.length));
    final avgCacheHitRate = results.where((r) => r.cacheMetrics != null).isEmpty
        ? 0.0
        : results
            .where((r) => r.cacheMetrics != null)
            .map((r) => r.cacheMetrics!.estimatedHitRate)
            .reduce((a, b) => a + b) / results.where((r) => r.cacheMetrics != null).length;
    final totalDuration = results.fold<int>(0, (sum, r) => sum + r.durationMs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(child: _MetricCard('Total Entities', _formatNumber(totalEntities), Icons.grid_on)),
            Expanded(child: _MetricCard('Systems Run', totalSystems.toString(), Icons.play_arrow)),
            Expanded(child: _MetricCard('Cache Hit Rate', '${avgCacheHitRate.toStringAsFixed(1)}%', Icons.cached)),
            Expanded(child: _MetricCard('Total Time', '${totalDuration}ms', Icons.timer)),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

class ScenarioComparisonChart extends StatelessWidget {
  final List<EnhancedBenchmarkResult> results;

  const ScenarioComparisonChart({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scenario Duration Comparison', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: results.map((r) => r.durationMs.toDouble()).reduce((a, b) => a > b ? a : b) * 1.1,
                  barGroups: results.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.durationMs.toDouble(),
                          color: _getColorForIndex(entry.key),
                          width: 32,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}ms', style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < results.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: Text(results[index].name, style: const TextStyle(fontSize: 10)),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    return colors[index % colors.length];
  }
}

class ThroughputComparisonChart extends StatelessWidget {
  final List<EnhancedBenchmarkResult> results;

  const ThroughputComparisonChart({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Throughput Comparison (Million ops/sec)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: results.map((r) => r.operationsPerSecond / 1000000).reduce((a, b) => a > b ? a : b) * 1.1,
                  barGroups: results.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.operationsPerSecond / 1000000,
                          color: _getColorForIndex(entry.key),
                          width: 32,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) => Text('${value.toStringAsFixed(1)}M', style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < results.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: RotatedBox(
                                quarterTurns: 1,
                                child: Text(results[index].name, style: const TextStyle(fontSize: 10)),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    return colors[index % colors.length];
  }
}

class SystemPerformanceBreakdown extends StatelessWidget {
  final EnhancedBenchmarkResult result;

  const SystemPerformanceBreakdown({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.systemBreakdown.isEmpty) return const SizedBox.shrink();

    final sortedSystems = result.systemBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.name} - System Performance Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...sortedSystems.map((entry) {
              final percentage = (entry.value.inMicroseconds / result.duration.inMicroseconds * 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('${entry.value.inMilliseconds}ms (${percentage.toStringAsFixed(1)}%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ArchetypeDistributionChart extends StatelessWidget {
  final EnhancedBenchmarkResult result;

  const ArchetypeDistributionChart({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.archetypeMetrics == null) return const SizedBox.shrink();

    final metrics = result.archetypeMetrics!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.name} - Archetype Distribution', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow('Total Archetypes', metrics.totalArchetypes.toString()),
                      _buildStatRow('Total Entities', metrics.totalEntities.toString()),
                      _buildStatRow('Avg Entities/Archetype', metrics.avgEntitiesPerArchetype.toStringAsFixed(1)),
                      _buildStatRow('Largest Archetype', metrics.largestArchetype.toString()),
                      if (result.cacheMetrics != null) ...[
                        const Divider(),
                        _buildStatRow('Cache Size', result.cacheMetrics!.cacheSize.toString()),
                        _buildStatRow('Cache Hit Rate', '${result.cacheMetrics!.estimatedHitRate.toStringAsFixed(1)}%'),
                      ],
                    ],
                  ),
                ),
                if (metrics.archetypeEntityCounts.isNotEmpty)
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _generatePieSections(metrics.archetypeEntityCounts),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
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

  List<PieChartSectionData> _generatePieSections(List<int> counts) {
    final sortedCounts = counts.toList()..sort((a, b) => b.compareTo(a));
    final topCounts = sortedCounts.take(5).toList();
    final otherCount = sortedCounts.skip(5).fold<int>(0, (sum, count) => sum + count);

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    final sections = <PieChartSectionData>[];

    for (var i = 0; i < topCounts.length; i++) {
      sections.add(PieChartSectionData(
        value: topCounts[i].toDouble(),
        title: topCounts[i].toString(),
        color: colors[i % colors.length],
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    if (otherCount > 0) {
      sections.add(PieChartSectionData(
        value: otherCount.toDouble(),
        title: 'Other',
        color: Colors.grey,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    }

    return sections;
  }
}

class EntityLifecycleChart extends StatelessWidget {
  final EnhancedBenchmarkResult result;

  const EntityLifecycleChart({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.frameSnapshots.isEmpty) return const SizedBox.shrink();

    final maxEntities = result.frameSnapshots
        .map((s) => s.activeEntities)
        .reduce((a, b) => a > b ? a : b);
    final minEntities = result.frameSnapshots
        .map((s) => s.activeEntities)
        .reduce((a, b) => a < b ? a : b);
    final entityVariation = maxEntities - minEntities;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.name} - Entity Count Over Time', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Range: ${_formatNumber(minEntities)} - ${_formatNumber(maxEntities)} (Δ ${_formatNumber(entityVariation)})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: result.frameSnapshots.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.activeEntities.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  minY: minEntities > 0 ? minEntities * 0.95 : 0,
                  maxY: maxEntities * 1.05,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) => Text(_formatNumber(value.toInt()), style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('Frame', style: TextStyle(fontSize: 12)),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: result.frameSnapshots.length > 60 ? 20 : 10,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: const FlGridData(show: true),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (result.lifecycleMetrics != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('Initial', result.entityCount.toString()),
                  _buildMetric('Created', result.lifecycleMetrics!.totalCreated),
                  _buildMetric('Destroyed', result.lifecycleMetrics!.totalDestroyed),
                  _buildMetric('Final', result.frameSnapshots.last.activeEntities),
                  if (result.lifecycleMetrics!.recycled > 0)
                    _buildMetric('Recycled', '${result.lifecycleMetrics!.recycled} (${result.lifecycleMetrics!.recycleRate.toStringAsFixed(1)}%)'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, dynamic value) {
    return Column(
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}
