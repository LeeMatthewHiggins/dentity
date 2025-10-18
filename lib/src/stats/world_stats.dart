import 'package:dentity/src/stats/archetype_stats.dart';
import 'package:dentity/src/stats/entity_stats.dart';
import 'package:dentity/src/stats/system_stats.dart';

class WorldStats {
  final EntityStats entities;
  final ArchetypeStats archetypes;
  final Map<String, SystemStats> _systems = {};
  int _frameCount = 0;

  WorldStats()
      : entities = EntityStats(),
        archetypes = ArchetypeStats();

  int get frameCount => _frameCount;

  List<SystemStats> get systems => _systems.values.toList();

  SystemStats getOrCreateSystemStats(String systemName) {
    return _systems.putIfAbsent(systemName, () => SystemStats(systemName));
  }

  void incrementFrameCount() {
    _frameCount++;
  }

  void reset() {
    entities.reset();
    archetypes.reset();
    for (var system in _systems.values) {
      system.reset();
    }
    _frameCount = 0;
  }

  WorldStatsSnapshot snapshot() {
    return WorldStatsSnapshot(
      entities: entities.snapshot(),
      archetypes: archetypes.snapshot(),
      systems: Map.fromEntries(
        _systems.entries.map((e) => MapEntry(e.key, e.value.snapshot())),
      ),
      frameCount: _frameCount,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('WorldStats:');
    buffer.writeln('  Frames: $_frameCount');
    buffer.writeln('  $entities');
    buffer.writeln('  $archetypes');
    if (_systems.isNotEmpty) {
      buffer.writeln('  Systems:');
      for (var system in _systems.values) {
        buffer.writeln('    $system');
      }
    }
    return buffer.toString();
  }
}

class WorldStatsSnapshot {
  final EntityStatsSnapshot entities;
  final ArchetypeStatsSnapshot archetypes;
  final Map<String, SystemStatsSnapshot> systems;
  final int frameCount;

  const WorldStatsSnapshot({
    required this.entities,
    required this.archetypes,
    required this.systems,
    required this.frameCount,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('WorldStatsSnapshot:');
    buffer.writeln('  Frames: $frameCount');
    buffer.writeln('  $entities');
    buffer.writeln('  $archetypes');
    if (systems.isNotEmpty) {
      buffer.writeln('  Systems:');
      for (var system in systems.values) {
        buffer.writeln('    $system');
      }
    }
    return buffer.toString();
  }
}
