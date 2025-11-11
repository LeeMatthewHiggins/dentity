## 1.0.0

- Initial version.

## 1.1.0

- Change the serialiser to use a map of components instead of a list.

## 1.1.1

- Add the entity serialiser json.

## 1.1.2

- Add component deserialisation method to entity serialiser.

## 1.1.3

- Add system get method to world.

## 1.2.0

- expose the component serialiser to the world.
- remove the need to pass the entity manager to the component serialiser.

## 1.2.1

- Fix entity deletion queue processing to prevent entities from being processed after deletion.
- Entity deletion queue is now processed after each system runs, ensuring proper entity lifecycle management.
- Add comprehensive entity deletion tests covering edge cases like cascading deletions and multi-system interactions.

## 1.4.0

- Add comprehensive stats collection system for profiling and debugging
  - Optional stats tracking via `enableStats: true` flag in World constructor
  - Entity lifecycle tracking (created, destroyed, recycled, peak count)
  - Queue size monitoring (creation and deletion queues)
  - System performance profiling with timing measurements
  - Archetype distribution tracking
  - Snapshot and diff capabilities for comparing stats over time
  - Reset functionality for clearing stats
- Add industry-standard benchmark metrics
  - ns/op (nanoseconds per operation) - Google Benchmark standard
  - ops/s (operations per second) - throughput metric
  - entities/s (entities per second) - entity-specific throughput
  - ns/entity (cost per entity) - performance cost metric
- Add shared benchmark library for consistent testing
  - Standardized entity counts: 1,024 (small), 16,384 (medium), 65,536 (large), 1,000,000 (very large)
  - Reusable benchmark functions: creation, processing, removal, recycling, mixed workload
  - Stats overhead measurement with accurate percentage calculation
- Enhanced benchmark Flutter app with professional UI
  - Real-time progress tracking with progress bar
  - Three chart types: Duration, Throughput, Stats Overhead comparison
  - Expandable cards showing detailed metrics for each benchmark
  - Dark theme with color-coded visualizations
  - Industry-standard metric display (ops/s, ns/op, entities/s)
- All stats collection has minimal overhead (~24-32%) and zero overhead when disabled

## 1.3.0

- Add entity creation queue to prevent newly created entities from being processed by subsequent systems in the same frame.
- Entity creation queue is processed at the start of each world.process() call.
- Add comprehensive entity creation tests covering spawning, recycling, and multi-system interactions.
- Entities created during system processing are now deferred until the next frame for consistent behavior.

## 1.4.1

- Add world time tracking to WorldStats
  - WorldStats now tracks accumulated world time using Duration type
  - World time is displayed in stats output and snapshots
  - World time is properly reset when stats are reset

## 1.6.0

- Add EntityView caching for improved performance
  - Entity views are now automatically cached by archetype
  - Calling viewForTypes() or view() with the same archetype returns the same instance
  - Eliminates redundant object creation in hot paths
  - New clearViewCache() method to clear cache if needed
  - New viewCacheSize getter to inspect cache size
  - Zero performance overhead - cached views automatically reflect entity changes
- Introduce EntityComposition class for cleaner component access
  - Replaces Map<Type, SparseList<Component>> with semantic wrapper
  - New get<T>(entity) method for clean, type-safe component access
  - New listFor<T>() method to get sparse list for a component type
  - Fully backwards compatible - implements Map interface
  - Deprecated EntityView.getComponentArray() and getComponentForType()
- **Breaking Change**: EntitySystem.processEntity signature updated
  - Now takes EntityComposition instead of Map<Type, SparseList<Component>>
  - Old code continues to work due to Map implementation
  - Recommended to migrate to componentLists.get<T>(entity) pattern

## 1.7.0

- Improve entity queue API for better ergonomics and discoverability
  - Add flushEntityQueues() method for explicit queue flushing
  - Add autoFlush parameter to viewForTypes() and view() (defaults to true)
  - Entity queries now automatically flush creation queue by default
  - Eliminates common "Bad state: No element" errors when querying newly created entities
  - Can opt-out of auto-flush with autoFlush: false for performance-critical code
  - Zero breaking changes - existing code continues to work
- Add comprehensive Asteroids game example demonstrating ECS patterns
  - Complete game with ship, asteroids, lasers, collision, and scoring
  - Demonstrates proper component/system separation
  - Shows frame-rate independent physics using delta time
  - Includes shield system with damage-over-time mechanics
  - Full Flutter UI with game loop and input handling

## 1.5.0

- Add global world time and frame count tracking to World class
  - World now tracks worldTime and frameCount as first-class properties
  - Accessible via world.worldTime and world.frameCount
  - Stats mirror these values as single source of truth
- Add world reference to System class
  - Systems can now access their world via system.world
  - New attachToWorld method replaces deprecated attach method
  - Systems have direct access to world time and frame count
  - Old attach method is deprecated but still functional for backwards compatibility
