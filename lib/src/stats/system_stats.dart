class SystemStats {
  final String name;
  int _callCount = 0;
  int _totalEntitiesProcessed = 0;
  Duration _totalTime = Duration.zero;
  Duration _minTime = Duration(days: 365);
  Duration _maxTime = Duration.zero;

  SystemStats(this.name);

  int get callCount => _callCount;
  int get totalEntitiesProcessed => _totalEntitiesProcessed;
  Duration get totalTime => _totalTime;
  Duration get minTime => _minTime;
  Duration get maxTime => _maxTime;

  double get averageTimeMicros =>
      _callCount > 0 ? _totalTime.inMicroseconds / _callCount : 0;

  double get averageTimeMs => averageTimeMicros / 1000;

  void recordExecution(Duration duration, int entitiesProcessed) {
    _callCount++;
    _totalEntitiesProcessed += entitiesProcessed;
    _totalTime += duration;
    if (duration < _minTime) {
      _minTime = duration;
    }
    if (duration > _maxTime) {
      _maxTime = duration;
    }
  }

  void reset() {
    _callCount = 0;
    _totalEntitiesProcessed = 0;
    _totalTime = Duration.zero;
    _minTime = Duration(days: 365);
    _maxTime = Duration.zero;
  }

  SystemStatsSnapshot snapshot() {
    return SystemStatsSnapshot(
      name: name,
      callCount: _callCount,
      totalEntitiesProcessed: _totalEntitiesProcessed,
      totalTime: _totalTime,
      minTime: _minTime == Duration(days: 365) ? Duration.zero : _minTime,
      maxTime: _maxTime,
    );
  }

  @override
  String toString() {
    return 'SystemStats($name: calls=$_callCount, avg=${averageTimeMs.toStringAsFixed(3)}ms, '
        'min=${_minTime.inMicroseconds / 1000}ms, max=${_maxTime.inMicroseconds / 1000}ms, '
        'entities=$_totalEntitiesProcessed)';
  }
}

class SystemStatsSnapshot {
  final String name;
  final int callCount;
  final int totalEntitiesProcessed;
  final Duration totalTime;
  final Duration minTime;
  final Duration maxTime;

  const SystemStatsSnapshot({
    required this.name,
    required this.callCount,
    required this.totalEntitiesProcessed,
    required this.totalTime,
    required this.minTime,
    required this.maxTime,
  });

  double get averageTimeMicros =>
      callCount > 0 ? totalTime.inMicroseconds / callCount : 0;

  double get averageTimeMs => averageTimeMicros / 1000;

  @override
  String toString() {
    return 'SystemStatsSnapshot($name: calls=$callCount, avg=${averageTimeMs.toStringAsFixed(3)}ms, '
        'min=${minTime.inMicroseconds / 1000}ms, max=${maxTime.inMicroseconds / 1000}ms, '
        'entities=$totalEntitiesProcessed)';
  }
}
