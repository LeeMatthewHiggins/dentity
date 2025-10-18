import 'package:dentity/src/archetype/archetype.dart';

class ArchetypeStats {
  final Map<Archetype, int> _entityCounts = {};
  final Map<Archetype, int> _recycleBinSizes = {};

  Map<Archetype, int> get entityCounts => Map.unmodifiable(_entityCounts);
  Map<Archetype, int> get recycleBinSizes => Map.unmodifiable(_recycleBinSizes);

  int get totalArchetypes => _entityCounts.length;

  int get totalEntities => _entityCounts.values.fold(0, (sum, count) => sum + count);

  int get totalInRecycleBin =>
      _recycleBinSizes.values.fold(0, (sum, count) => sum + count);

  void updateEntityCount(Archetype archetype, int count) {
    if (count > 0) {
      _entityCounts[archetype] = count;
    } else {
      _entityCounts.remove(archetype);
    }
  }

  void updateRecycleBinSize(Archetype archetype, int size) {
    if (size > 0) {
      _recycleBinSizes[archetype] = size;
    } else {
      _recycleBinSizes.remove(archetype);
    }
  }

  List<ArchetypeEntry> getMostUsedArchetypes({int limit = 10}) {
    final entries = _entityCounts.entries
        .map((e) => ArchetypeEntry(e.key, e.value))
        .toList();
    entries.sort((a, b) => b.count.compareTo(a.count));
    return entries.take(limit).toList();
  }

  void reset() {
    _entityCounts.clear();
    _recycleBinSizes.clear();
  }

  ArchetypeStatsSnapshot snapshot() {
    return ArchetypeStatsSnapshot(
      entityCounts: Map.from(_entityCounts),
      recycleBinSizes: Map.from(_recycleBinSizes),
    );
  }

  @override
  String toString() {
    return 'ArchetypeStats(archetypes: $totalArchetypes, '
        'totalEntities: $totalEntities, inRecycleBin: $totalInRecycleBin)';
  }
}

class ArchetypeEntry {
  final Archetype archetype;
  final int count;

  const ArchetypeEntry(this.archetype, this.count);

  @override
  String toString() => '$archetype: $count';
}

class ArchetypeStatsSnapshot {
  final Map<Archetype, int> entityCounts;
  final Map<Archetype, int> recycleBinSizes;

  const ArchetypeStatsSnapshot({
    required this.entityCounts,
    required this.recycleBinSizes,
  });

  int get totalArchetypes => entityCounts.length;

  int get totalEntities => entityCounts.values.fold(0, (sum, count) => sum + count);

  int get totalInRecycleBin =>
      recycleBinSizes.values.fold(0, (sum, count) => sum + count);

  @override
  String toString() {
    return 'ArchetypeStatsSnapshot(archetypes: $totalArchetypes, '
        'totalEntities: $totalEntities, inRecycleBin: $totalInRecycleBin)';
  }
}
