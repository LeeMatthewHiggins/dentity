import 'package:dentity/dentity.dart';
import 'basic_example.dart';

class BenchmarkConstants {
  static const int defaultRunTimes = 120;
  static const int smallEntityCount = 1024;
  static const int mediumEntityCount = 16384;
  static const int largeEntityCount = 65536;
  static const int veryLargeEntityCount = 1000000;
}

class BenchmarkResult {
  final String name;
  final Duration duration;
  final int entityCount;
  final int operations;
  final WorldStats? stats;

  BenchmarkResult({
    required this.name,
    required this.duration,
    required this.entityCount,
    required this.operations,
    this.stats,
  });

  int get durationMs => duration.inMilliseconds;
  double get durationMicros => duration.inMicroseconds.toDouble();
  double get durationNanos => duration.inMicroseconds * 1000.0;

  double get operationsPerSecond => durationMicros > 0 ? (operations / durationMicros) * 1000000 : 0;
  double get entitiesPerSecond => durationMicros > 0 ? (entityCount / durationMicros) * 1000000 : 0;
  double get nanosPerOperation => operations > 0 ? durationNanos / operations : 0;
  double get nanosPerEntity => entityCount > 0 ? durationNanos / entityCount : 0;
}

class StatsOverheadResult extends BenchmarkResult {
  final Duration durationWithoutStats;
  final Duration durationWithStats;

  StatsOverheadResult({
    required this.durationWithoutStats,
    required this.durationWithStats,
    required super.entityCount,
    required super.operations,
    super.stats,
  }) : super(
          name: 'Stats Overhead',
          duration: durationWithStats - durationWithoutStats,
        );

  double get overheadPercent =>
      durationWithoutStats.inMicroseconds > 0
          ? ((durationWithStats.inMicroseconds - durationWithoutStats.inMicroseconds) /
                  durationWithoutStats.inMicroseconds) *
              100
          : 0;

  int get durationWithoutStatsMs => durationWithoutStats.inMilliseconds;
  int get durationWithStatsMs => durationWithStats.inMilliseconds;
}

class Benchmarks {
  static BenchmarkResult creation({
    int entityCount = BenchmarkConstants.mediumEntityCount,
    bool enableStats = false,
  }) {
    final world = createBasicExampleWorld(enableStats: enableStats);
    final sw = Stopwatch()..start();
    for (var i = 0; i < entityCount; i++) {
      world.createEntity({Position(0, 0), Velocity(1, 1)});
    }
    sw.stop();

    return BenchmarkResult(
      name: 'Creation',
      duration: sw.elapsed,
      entityCount: entityCount,
      operations: entityCount,
      stats: world.stats,
    );
  }

  static BenchmarkResult processing({
    int entityCount = BenchmarkConstants.mediumEntityCount,
    int runTimes = BenchmarkConstants.defaultRunTimes,
    bool enableStats = false,
  }) {
    final world = createBasicExampleWorld(enableStats: enableStats);
    for (var i = 0; i < entityCount; i++) {
      world.createEntity({Position(0, 0), Velocity(1, 1)});
    }

    final sw = Stopwatch()..start();
    for (var i = 0; i < runTimes; i++) {
      world.process();
    }
    sw.stop();

    return BenchmarkResult(
      name: 'Processing',
      duration: sw.elapsed,
      entityCount: entityCount,
      operations: runTimes * entityCount,
      stats: world.stats,
    );
  }

  static BenchmarkResult removal({
    int entityCount = BenchmarkConstants.mediumEntityCount,
    bool enableStats = false,
  }) {
    final world = createBasicExampleWorld(enableStats: enableStats);
    final entities = <Entity>[];
    for (var i = 0; i < entityCount; i++) {
      entities.add(world.createEntity({Position(0, 0), Velocity(1, 1)}));
    }

    final sw = Stopwatch()..start();
    for (var i = 0; i < entityCount; i++) {
      world.destroyEntity(entities[i]);
    }
    sw.stop();

    return BenchmarkResult(
      name: 'Removal',
      duration: sw.elapsed,
      entityCount: entityCount,
      operations: entityCount,
      stats: world.stats,
    );
  }

  static BenchmarkResult recycling({
    int entityCount = BenchmarkConstants.mediumEntityCount,
    bool enableStats = true,
  }) {
    final world = createBasicExampleWorld(enableStats: enableStats);
    final entities = <Entity>[];

    for (var i = 0; i < entityCount; i++) {
      entities.add(world.createEntity({Position(0, 0), Velocity(1, 1)}));
    }
    world.process();

    final sw = Stopwatch()..start();
    for (var i = 0; i < entityCount; i++) {
      world.destroyEntity(entities[i]);
    }
    world.process();

    for (var i = 0; i < entityCount; i++) {
      world.createEntity({Position(0, 0), Velocity(1, 1)});
    }
    world.process();
    sw.stop();

    return BenchmarkResult(
      name: 'Entity Recycling',
      duration: sw.elapsed,
      entityCount: entityCount,
      operations: entityCount * 2,
      stats: world.stats,
    );
  }

  static BenchmarkResult mixedWorkload({
    int runTimes = BenchmarkConstants.defaultRunTimes,
    bool enableStats = true,
  }) {
    final world = createBasicExampleWorld(enableStats: enableStats);
    final entities = <Entity>[];
    int totalOps = 0;

    final sw = Stopwatch()..start();

    for (var frame = 0; frame < runTimes; frame++) {
      if (frame % 10 == 0) {
        for (var i = 0; i < 10; i++) {
          entities.add(world.createEntity({Position(0, 0), Velocity(1, 1)}));
          totalOps++;
        }
      }

      if (frame % 15 == 0 && entities.isNotEmpty) {
        world.destroyEntity(entities.removeLast());
        totalOps++;
      }

      if (frame % 5 == 0 && entities.isNotEmpty) {
        world.addComponents(entities.first, {OtherComponent()});
        totalOps++;
      }

      world.process();
      totalOps += entities.length;
    }
    sw.stop();

    return BenchmarkResult(
      name: 'Mixed Workload',
      duration: sw.elapsed,
      entityCount: entities.length,
      operations: totalOps,
      stats: world.stats,
    );
  }

  static StatsOverheadResult statsOverhead({
    int entityCount = BenchmarkConstants.mediumEntityCount,
    int runTimes = BenchmarkConstants.defaultRunTimes,
  }) {
    const warmupRuns = 50;
    const measurementRuns = 1000;

    final worldWithoutStats = createBasicExampleWorld(enableStats: false);
    final worldWithStats = createBasicExampleWorld(enableStats: true);

    for (var i = 0; i < entityCount; i++) {
      worldWithoutStats.createEntity({Position(0, 0), Velocity(1, 1)});
      worldWithStats.createEntity({Position(0, 0), Velocity(1, 1)});
    }

    for (var i = 0; i < warmupRuns; i++) {
      worldWithoutStats.process();
      worldWithStats.process();
    }

    final swWithoutStats = Stopwatch()..start();
    for (var i = 0; i < measurementRuns; i++) {
      worldWithoutStats.process();
    }
    swWithoutStats.stop();

    final swWithStats = Stopwatch()..start();
    for (var i = 0; i < measurementRuns; i++) {
      worldWithStats.process();
    }
    swWithStats.stop();

    return StatsOverheadResult(
      durationWithoutStats: swWithoutStats.elapsed,
      durationWithStats: swWithStats.elapsed,
      entityCount: entityCount,
      operations: measurementRuns * entityCount,
      stats: worldWithStats.stats,
    );
  }
}
