import 'package:dentity/dentity.dart';
import 'benchmarks.dart';

class FrameSnapshot {
  final int frameNumber;
  final int activeEntities;
  final int recycledEntities;
  final Duration frameDuration;
  final Map<String, Duration> systemTimes;

  FrameSnapshot({
    required this.frameNumber,
    required this.activeEntities,
    required this.recycledEntities,
    required this.frameDuration,
    required this.systemTimes,
  });
}

class ArchetypeMetrics {
  final int totalArchetypes;
  final int totalEntities;
  final List<int> archetypeEntityCounts;
  final int largestArchetype;
  final double avgEntitiesPerArchetype;

  ArchetypeMetrics({
    required this.totalArchetypes,
    required this.totalEntities,
    required this.archetypeEntityCounts,
    required this.largestArchetype,
    required this.avgEntitiesPerArchetype,
  });

  factory ArchetypeMetrics.fromStats(WorldStats stats) {
    final counts = stats.archetypes.entityCounts.values.toList();
    final largest = counts.fold<int>(0, (max, count) => count > max ? count : max);
    final avg = stats.archetypes.totalArchetypes > 0
        ? stats.archetypes.totalEntities / stats.archetypes.totalArchetypes
        : 0.0;

    return ArchetypeMetrics(
      totalArchetypes: stats.archetypes.totalArchetypes,
      totalEntities: stats.archetypes.totalEntities,
      archetypeEntityCounts: counts,
      largestArchetype: largest,
      avgEntitiesPerArchetype: avg,
    );
  }
}

class ViewCacheMetrics {
  final int cacheSize;
  final int totalViews;
  final double estimatedHitRate;

  ViewCacheMetrics({
    required this.cacheSize,
    required this.totalViews,
    required this.estimatedHitRate,
  });

  factory ViewCacheMetrics.fromEntityManager(EntityManager entityManager, int totalViewCalls) {
    final cacheSize = entityManager.viewCacheSize;
    final estimatedHitRate = totalViewCalls > 0 && cacheSize > 0
        ? ((totalViewCalls - cacheSize) / totalViewCalls * 100)
        : 0.0;

    return ViewCacheMetrics(
      cacheSize: cacheSize,
      totalViews: totalViewCalls,
      estimatedHitRate: estimatedHitRate,
    );
  }
}

class MemoryMetrics {
  final int peakMemoryBytes;
  final int avgMemoryBytes;
  final double bytesPerEntity;
  final double bytesPerComponent;

  MemoryMetrics({
    required this.peakMemoryBytes,
    required this.avgMemoryBytes,
    required this.bytesPerEntity,
    required this.bytesPerComponent,
  });
}

class EntityLifecycleMetrics {
  final int totalCreated;
  final int totalDestroyed;
  final int recycled;
  final double creationRate;
  final double destructionRate;
  final double recycleRate;

  EntityLifecycleMetrics({
    required this.totalCreated,
    required this.totalDestroyed,
    required this.recycled,
    required this.creationRate,
    required this.destructionRate,
    required this.recycleRate,
  });

  factory EntityLifecycleMetrics.fromStats(WorldStats stats, Duration totalDuration) {
    final totalSeconds = totalDuration.inMicroseconds / 1000000.0;
    final creationRate = totalSeconds > 0 ? stats.entities.totalCreated / totalSeconds : 0.0;
    final destructionRate = totalSeconds > 0 ? stats.entities.totalDestroyed / totalSeconds : 0.0;
    final recycleRate = stats.entities.totalCreated > 0
        ? (stats.entities.recycledCount / stats.entities.totalCreated * 100)
        : 0.0;

    return EntityLifecycleMetrics(
      totalCreated: stats.entities.totalCreated,
      totalDestroyed: stats.entities.totalDestroyed,
      recycled: stats.entities.recycledCount,
      creationRate: creationRate,
      destructionRate: destructionRate,
      recycleRate: recycleRate,
    );
  }
}

class EnhancedBenchmarkResult extends BenchmarkResult {
  final Map<String, Duration> systemBreakdown;
  final List<FrameSnapshot> frameSnapshots;
  final ArchetypeMetrics? archetypeMetrics;
  final ViewCacheMetrics? cacheMetrics;
  final MemoryMetrics? memoryMetrics;
  final EntityLifecycleMetrics? lifecycleMetrics;

  EnhancedBenchmarkResult({
    required super.name,
    required super.duration,
    required super.entityCount,
    required super.operations,
    super.stats,
    this.systemBreakdown = const {},
    this.frameSnapshots = const [],
    this.archetypeMetrics,
    this.cacheMetrics,
    this.memoryMetrics,
    this.lifecycleMetrics,
  });
}
