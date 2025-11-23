import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'enhanced_benchmark_result.dart';

const String _resultsFileName = 'benchmark_results.json';

class SystemInfo {
  final String platform;
  final String dartVersion;
  final String timestamp;

  SystemInfo({
    required this.platform,
    required this.dartVersion,
    required this.timestamp,
  });

  factory SystemInfo.current() {
    final String platform;
    final String dartVersion;

    if (kIsWeb) {
      platform = 'web';
      dartVersion = 'unknown';
    } else {
      platform = Platform.operatingSystem;
      dartVersion = Platform.version.split(' ').first;
    }

    final timestamp = DateTime.now().toIso8601String();

    return SystemInfo(
      platform: platform,
      dartVersion: dartVersion,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'dartVersion': dartVersion,
        'timestamp': timestamp,
      };

  factory SystemInfo.fromJson(Map<String, dynamic> json) => SystemInfo(
        platform: json['platform'] as String,
        dartVersion: json['dartVersion'] as String,
        timestamp: json['timestamp'] as String,
      );

  bool isCompatibleWith(SystemInfo other) {
    return platform == other.platform;
  }
}

class BenchmarkSnapshot {
  final String name;
  final int durationMs;
  final int entityCount;
  final int operations;
  final double operationsPerSecond;
  final double nanosPerOperation;
  final double entitiesPerSecond;
  final Map<String, int> systemBreakdown;

  BenchmarkSnapshot({
    required this.name,
    required this.durationMs,
    required this.entityCount,
    required this.operations,
    required this.operationsPerSecond,
    required this.nanosPerOperation,
    required this.entitiesPerSecond,
    required this.systemBreakdown,
  });

  factory BenchmarkSnapshot.fromResult(EnhancedBenchmarkResult result) {
    final systemBreakdown = <String, int>{};
    for (final entry in result.systemBreakdown.entries) {
      systemBreakdown[entry.key] = entry.value.inMicroseconds;
    }

    return BenchmarkSnapshot(
      name: result.name,
      durationMs: result.durationMs,
      entityCount: result.entityCount,
      operations: result.operations,
      operationsPerSecond: result.operationsPerSecond,
      nanosPerOperation: result.nanosPerOperation,
      entitiesPerSecond: result.entitiesPerSecond,
      systemBreakdown: systemBreakdown,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'durationMs': durationMs,
        'entityCount': entityCount,
        'operations': operations,
        'operationsPerSecond': operationsPerSecond,
        'nanosPerOperation': nanosPerOperation,
        'entitiesPerSecond': entitiesPerSecond,
        'systemBreakdown': systemBreakdown,
      };

  factory BenchmarkSnapshot.fromJson(Map<String, dynamic> json) {
    final systemBreakdown = <String, int>{};
    final breakdownData = json['systemBreakdown'] as Map<String, dynamic>?;
    if (breakdownData != null) {
      breakdownData.forEach((key, value) {
        systemBreakdown[key] = value as int;
      });
    }

    return BenchmarkSnapshot(
      name: json['name'] as String,
      durationMs: json['durationMs'] as int,
      entityCount: json['entityCount'] as int,
      operations: json['operations'] as int,
      operationsPerSecond: (json['operationsPerSecond'] as num).toDouble(),
      nanosPerOperation: (json['nanosPerOperation'] as num).toDouble(),
      entitiesPerSecond: (json['entitiesPerSecond'] as num).toDouble(),
      systemBreakdown: systemBreakdown,
    );
  }
}

class BenchmarkBaseline {
  final String version;
  final SystemInfo systemInfo;
  final Map<String, BenchmarkSnapshot> benchmarks;

  BenchmarkBaseline({
    required this.version,
    required this.systemInfo,
    required this.benchmarks,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'systemInfo': systemInfo.toJson(),
        'benchmarks': benchmarks.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory BenchmarkBaseline.fromJson(Map<String, dynamic> json) {
    final benchmarksData = json['benchmarks'] as Map<String, dynamic>;
    final benchmarks = <String, BenchmarkSnapshot>{};

    benchmarksData.forEach((key, value) {
      benchmarks[key] = BenchmarkSnapshot.fromJson(value as Map<String, dynamic>);
    });

    return BenchmarkBaseline(
      version: json['version'] as String,
      systemInfo: SystemInfo.fromJson(json['systemInfo'] as Map<String, dynamic>),
      benchmarks: benchmarks,
    );
  }
}

class BenchmarkResultsStore {
  static const String _baselineVersion = '1.0.0';

  static Future<BenchmarkBaseline?> loadBaseline() async {
    if (kIsWeb) return null;

    try {
      final file = File(_resultsFileName);
      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return BenchmarkBaseline.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  static Future<BenchmarkBaseline?> loadBaselineFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return BenchmarkBaseline.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveBaseline(List<EnhancedBenchmarkResult> results) async {
    if (kIsWeb) return;

    final benchmarks = <String, BenchmarkSnapshot>{};
    for (final result in results) {
      benchmarks[result.name] = BenchmarkSnapshot.fromResult(result);
    }

    final baseline = BenchmarkBaseline(
      version: _baselineVersion,
      systemInfo: SystemInfo.current(),
      benchmarks: benchmarks,
    );

    final file = File(_resultsFileName);
    final json = jsonEncode(baseline.toJson());
    await file.writeAsString(json);
  }

  static Future<void> saveBaselineToFile(
    List<EnhancedBenchmarkResult> results,
    String filePath,
  ) async {
    final jsonString = getBaselineJson(results);
    final file = File(filePath);
    await file.writeAsString(jsonString);
  }

  static String getBaselineJson(List<EnhancedBenchmarkResult> results) {
    final benchmarks = <String, BenchmarkSnapshot>{};
    for (final result in results) {
      benchmarks[result.name] = BenchmarkSnapshot.fromResult(result);
    }

    final baseline = BenchmarkBaseline(
      version: _baselineVersion,
      systemInfo: SystemInfo.current(),
      benchmarks: benchmarks,
    );

    return const JsonEncoder.withIndent('  ').convert(baseline.toJson());
  }

  static Future<void> clearBaseline() async {
    if (kIsWeb) return;

    try {
      final file = File(_resultsFileName);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors
    }
  }
}
