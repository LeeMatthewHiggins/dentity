import 'benchmark_results_store.dart';
import 'enhanced_benchmark_result.dart';

class BenchmarkDelta {
  final String benchmarkName;
  final int baselineDurationMs;
  final int currentDurationMs;
  final double percentChange;
  final bool isRegression;

  BenchmarkDelta({
    required this.benchmarkName,
    required this.baselineDurationMs,
    required this.currentDurationMs,
    required this.percentChange,
    required this.isRegression,
  });

  bool get isImprovement => !isRegression && percentChange.abs() > 1.0;
  bool get isSignificantRegression => isRegression && percentChange.abs() > 5.0;
}

class BenchmarkComparison {
  final BenchmarkBaseline baseline;
  final List<EnhancedBenchmarkResult> currentResults;
  final List<BenchmarkDelta> deltas;
  final bool isCompatible;
  final String? incompatibilityReason;

  BenchmarkComparison({
    required this.baseline,
    required this.currentResults,
    required this.deltas,
    required this.isCompatible,
    this.incompatibilityReason,
  });

  List<BenchmarkDelta> get regressions =>
      deltas.where((d) => d.isRegression && d.percentChange.abs() > 1.0).toList()
        ..sort((a, b) => b.percentChange.compareTo(a.percentChange));

  List<BenchmarkDelta> get improvements =>
      deltas.where((d) => d.isImprovement).toList()
        ..sort((a, b) => b.percentChange.abs().compareTo(a.percentChange.abs()));

  int get regressionCount => regressions.length;
  int get improvementCount => improvements.length;

  bool get hasSignificantRegressions =>
      deltas.any((d) => d.isSignificantRegression);

  static BenchmarkComparison? compare(
    BenchmarkBaseline? baseline,
    List<EnhancedBenchmarkResult> currentResults,
  ) {
    if (baseline == null) return null;

    final currentSystemInfo = SystemInfo.current();
    final isCompatible = baseline.systemInfo.isCompatibleWith(currentSystemInfo);
    String? incompatibilityReason;

    if (!isCompatible) {
      incompatibilityReason =
          'Baseline platform (${baseline.systemInfo.platform}) differs from current platform (${currentSystemInfo.platform})';
    }

    final deltas = <BenchmarkDelta>[];

    for (final current in currentResults) {
      final baselineSnapshot = baseline.benchmarks[current.name];
      if (baselineSnapshot == null) continue;

      final baselineMs = baselineSnapshot.durationMs;
      final currentMs = current.durationMs;
      final percentChange =
          ((currentMs - baselineMs) / baselineMs) * 100.0;

      deltas.add(BenchmarkDelta(
        benchmarkName: current.name,
        baselineDurationMs: baselineMs,
        currentDurationMs: currentMs,
        percentChange: percentChange,
        isRegression: percentChange > 0,
      ));
    }

    return BenchmarkComparison(
      baseline: baseline,
      currentResults: currentResults,
      deltas: deltas,
      isCompatible: isCompatible,
      incompatibilityReason: incompatibilityReason,
    );
  }

  String getSummaryText() {
    final buffer = StringBuffer();

    buffer.writeln('Performance Summary (vs baseline from ${_formatDate(baseline.systemInfo.timestamp)})');
    buffer.writeln('Platform: ${baseline.systemInfo.platform}');
    buffer.writeln('');

    if (!isCompatible) {
      buffer.writeln('⚠️  WARNING: $incompatibilityReason');
      buffer.writeln('');
    }

    if (regressions.isNotEmpty) {
      buffer.writeln('⚠️  REGRESSIONS (${regressions.length}):');
      for (final delta in regressions) {
        buffer.writeln('  • ${delta.benchmarkName}: ${delta.percentChange.toStringAsFixed(1)}% slower '
            '(${delta.baselineDurationMs}ms → ${delta.currentDurationMs}ms)');
      }
      buffer.writeln('');
    }

    if (improvements.isNotEmpty) {
      buffer.writeln('✅ IMPROVEMENTS (${improvements.length}):');
      for (final delta in improvements) {
        buffer.writeln('  • ${delta.benchmarkName}: ${delta.percentChange.abs().toStringAsFixed(1)}% faster '
            '(${delta.baselineDurationMs}ms → ${delta.currentDurationMs}ms)');
      }
    }

    if (regressions.isEmpty && improvements.isEmpty) {
      buffer.writeln('✅ No significant performance changes');
    }

    return buffer.toString();
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }
}
