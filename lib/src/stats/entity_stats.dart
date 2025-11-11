class EntityStats {
  int _totalCreated = 0;
  int _totalDestroyed = 0;
  int _activeCount = 0;
  int _recycledCount = 0;
  int _peakCount = 0;
  int _creationQueueSize = 0;
  int _deletionQueueSize = 0;

  int get totalCreated => _totalCreated;
  int get totalDestroyed => _totalDestroyed;
  int get activeCount => _activeCount;
  int get recycledCount => _recycledCount;
  int get peakCount => _peakCount;
  int get creationQueueSize => _creationQueueSize;
  int get deletionQueueSize => _deletionQueueSize;

  void incrementCreated() {
    _totalCreated++;
    _activeCount++;
    if (_activeCount > _peakCount) {
      _peakCount = _activeCount;
    }
  }

  void incrementDestroyed() {
    _totalDestroyed++;
    _activeCount--;
  }

  void incrementRecycled() {
    _recycledCount++;
  }

  void updateCreationQueueSize(int size) {
    _creationQueueSize = size;
  }

  void updateDeletionQueueSize(int size) {
    _deletionQueueSize = size;
  }

  void reset() {
    _totalCreated = 0;
    _totalDestroyed = 0;
    _activeCount = 0;
    _recycledCount = 0;
    _peakCount = 0;
    _creationQueueSize = 0;
    _deletionQueueSize = 0;
  }

  EntityStatsSnapshot snapshot() {
    return EntityStatsSnapshot(
      totalCreated: _totalCreated,
      totalDestroyed: _totalDestroyed,
      activeCount: _activeCount,
      recycledCount: _recycledCount,
      peakCount: _peakCount,
      creationQueueSize: _creationQueueSize,
      deletionQueueSize: _deletionQueueSize,
    );
  }

  @override
  String toString() {
    return 'EntityStats(active: $_activeCount, created: $_totalCreated, '
        'destroyed: $_totalDestroyed, recycled: $_recycledCount, '
        'peak: $_peakCount, creationQueue: $_creationQueueSize, '
        'deletionQueue: $_deletionQueueSize)';
  }
}

class EntityStatsSnapshot {
  final int totalCreated;
  final int totalDestroyed;
  final int activeCount;
  final int recycledCount;
  final int peakCount;
  final int creationQueueSize;
  final int deletionQueueSize;

  const EntityStatsSnapshot({
    required this.totalCreated,
    required this.totalDestroyed,
    required this.activeCount,
    required this.recycledCount,
    required this.peakCount,
    required this.creationQueueSize,
    required this.deletionQueueSize,
  });

  EntityStatsSnapshot diff(EntityStatsSnapshot other) {
    return EntityStatsSnapshot(
      totalCreated: totalCreated - other.totalCreated,
      totalDestroyed: totalDestroyed - other.totalDestroyed,
      activeCount: activeCount - other.activeCount,
      recycledCount: recycledCount - other.recycledCount,
      peakCount: peakCount,
      creationQueueSize: creationQueueSize,
      deletionQueueSize: deletionQueueSize,
    );
  }

  @override
  String toString() {
    return 'EntityStatsSnapshot(active: $activeCount, created: $totalCreated, '
        'destroyed: $totalDestroyed, recycled: $recycledCount, '
        'peak: $peakCount, creationQueue: $creationQueueSize, '
        'deletionQueue: $deletionQueueSize)';
  }
}
