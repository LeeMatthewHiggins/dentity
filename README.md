
# Dentity - Entity-Component-System Framework

`Dentity` is a powerful and flexible Entity-Component-System (ECS) framework for Dart applications. This README provides examples and documentation to help you get started with the `Dentity` package.

## Live Demos

Try out Dentity in your browser:

- **[Asteroids Game](https://leematthewhiggins.github.io/dentity/asteroids/)** - Complete game demonstrating ECS patterns with collision detection, shield system, and scoring
- **[Performance Benchmarks](https://leematthewhiggins.github.io/dentity/benchmark/)** - Real-time performance visualization with industry-standard metrics

## Introduction

This documentation demonstrates how to use `Dentity` to create ECS-based applications. The examples show how entities with `Position` and `Velocity` components are updated by a `MovementSystem`.

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  dentity: ^1.8.0
```

Then, run the following command to install the package:

```bash
dart pub get
```

## Creating Components

Components are the data containers that represent different aspects of an entity. In this example, we define `Position` and `Velocity` components.

```dart
class Position extends Component {
  double x;
  double y;

  Position(this.x, this.y);

  @override
  Position clone() => Position(x, y);

  @override
  int compareTo(other) {
    if (other is Position) {
      return x.compareTo(other.x) + y.compareTo(other.y);
    }
    return -1;
  }
}

class Velocity extends Component {
  double x;
  double y;

  Velocity(this.x, this.y);

  @override
  Velocity clone() => Velocity(x, y);

  @override
  int compareTo(other) {
    if (other is Velocity) {
      return x.compareTo(other.x) + y.compareTo(other.y);
    }
    return -1;
  }
}
```

## Defining Component Serializers

To enable serialization of components, you need to define serializers for each component type.

```dart
class PositionJsonSerializer extends ComponentSerializer<Position> {
  static const type = 'Position';
  
  @override
  ComponentRepresentation? serialize(Position component) {
    return {
      'x': component.x,
      'y': component.y,
      EntitySerialiserJson.typeField: type,
    };
  }

  @override
  Position deserialize(ComponentRepresentation data) {
    final positionData = data as Map<String, dynamic>;
    return Position(positionData['x'] as double, positionData['y'] as double);
  }
}

class VelocityJsonSerializer extends ComponentSerializer<Velocity> {
  static const type = 'Velocity';

  @override
  ComponentRepresentation? serialize(Velocity component) {
    return {
      'x': component.x,
      'y': component.y,
      EntitySerialiserJson.typeField: type,
    };
  }

  @override
  Velocity deserialize(ComponentRepresentation data) {
    final velocityData = data as Map<String, dynamic>;
    return Velocity(velocityData['x'] as double, velocityData['y'] as double);
  }
}
```

## Creating a System

Systems contain the logic that operates on entities with specific components. The `MovementSystem` updates the `Position` of entities based on their `Velocity`.

```dart
class MovementSystem extends EntitySystem {
  @override
  Set<Type> get filterTypes => const {Position, Velocity};

  @override
  void processEntity(Entity entity, EntityComposition componentLists, Duration delta) {
    final position = componentLists.get<Position>(entity)!;
    final velocity = componentLists.get<Velocity>(entity)!;
    position.x += velocity.x;
    position.y += velocity.y;
  }
}
```

### Component Access

The `EntityComposition` class provides clean, type-safe component access:

```dart
// Clean, type-safe access
final position = componentLists.get<Position>(entity);

// Get the sparse list for a component type
final positionList = componentLists.listFor<Position>();

// Backwards compatible Map access
final position = componentLists[Position]?[entity] as Position?;
```

## Setting Up the World

The `World` class ties everything together. It manages entities, components, and systems.

```dart
World createBasicExampleWorld() {
  final componentManager = ComponentManager(
    archetypeManagerFactory: (types) => ArchetypeManagerBigInt(types),
    componentArrayFactories: {
      Position: () => ContiguousSparseList<Position>(),
      Velocity: () => ContiguousSparseList<Velocity>(),
      OtherComponent: () => ContiguousSparseList<OtherComponent>(),
    },
  );
  
  final entityManager = EntityManager(componentManager);
  final movementSystem = MovementSystem();

  return World(
    componentManager,
    entityManager,
    [movementSystem],
  );
}
```

## Example Usage

Here's how you can use the above setup:

```dart
void main() {
  final world = createBasicExampleWorld();

  // Create an entity with Position and Velocity components
  final entity = world.createEntity({
    Position(0, 0),
    Velocity(1, 1),
  });

  // Run the system to update positions based on velocity
  world.process();

  // Check the updated position
  final position = world.componentManager.getComponent<Position>(entity);
  print('Updated position: (\${position?.x}, \${position?.y})'); // Should output (1, 1)
}
```

## Stats Collection & Profiling

Dentity includes a comprehensive stats collection system for profiling and debugging. Enable stats tracking to monitor entity lifecycle, system performance, and archetype distribution.

### Enabling Stats

```dart
World createWorldWithStats() {
  final componentManager = ComponentManager(
    archetypeManagerFactory: (types) => ArchetypeManagerBigInt(types),
    componentArrayFactories: {
      Position: () => ContiguousSparseList<Position>(),
      Velocity: () => ContiguousSparseList<Velocity>(),
    },
  );

  final entityManager = EntityManager(componentManager);
  final movementSystem = MovementSystem();

  return World(
    componentManager,
    entityManager,
    [movementSystem],
    enableStats: true,  // Enable stats collection
  );
}
```

### Accessing Stats

```dart
void main() {
  final world = createWorldWithStats();

  for (var i = 0; i < 1000; i++) {
    world.createEntity({Position(0, 0), Velocity(1, 1)});
  }

  world.process();

  // Access entity stats
  print('Entities created: ${world.stats!.entities.totalCreated}');
  print('Active entities: ${world.stats!.entities.activeCount}');
  print('Peak entities: ${world.stats!.entities.peakCount}');
  print('Recycled entities: ${world.stats!.entities.recycledCount}');

  // Access system performance stats
  for (final systemStats in world.stats!.systems) {
    print('${systemStats.name}: ${systemStats.averageTimeMs.toStringAsFixed(3)}ms avg');
  }

  // Access archetype distribution
  final mostUsed = world.stats!.archetypes.getMostUsedArchetypes();
  for (final archetype in mostUsed.take(5)) {
    print('Archetype ${archetype.archetype}: ${archetype.count} entities');
  }
}
```

### Available Metrics

**Entity Stats:**
- `totalCreated` - Total entities created
- `totalDestroyed` - Total entities destroyed
- `activeCount` - Currently active entities
- `recycledCount` - Number of recycled entities
- `peakCount` - Maximum concurrent entities
- `creationQueueSize` - Current creation queue size
- `deletionQueueSize` - Current deletion queue size

**System Stats:**
- `callCount` - Number of times the system has run
- `totalEntitiesProcessed` - Total entities processed
- `totalTime` - Cumulative processing time
- `averageTimeMicros` - Average time in microseconds
- `averageTimeMs` - Average time in milliseconds
- `minTime` - Minimum processing time
- `maxTime` - Maximum processing time

**Archetype Stats:**
- `totalArchetypes` - Number of unique archetypes
- `totalEntities` - Total entities across all archetypes
- `getMostUsedArchetypes()` - Returns archetypes sorted by entity count

**Note:** Stats collection adds ~24-32% overhead. Disable for production builds.

## Benchmarking

Dentity includes industry-standard benchmarks using metrics like `ns/op` (nanoseconds per operation), `ops/s` (operations per second), and `entities/s` (entities per second).

See the [benchmark_app](benchmark_app/) for a Flutter app with real-time performance visualization.

## Entity Deletion

Entities can be destroyed using `world.destroyEntity(entity)`. Deletions are queued and processed automatically after each system runs during `world.process()`.

```dart
void main() {
  final world = createBasicExampleWorld();

  final entity = world.createEntity({
    Position(0, 0),
    Velocity(1, 1),
  });

  // Queue entity for deletion
  world.destroyEntity(entity);

  // Deletion happens after systems process
  world.process();

  // Entity is now deleted
  final position = world.componentManager.getComponent<Position>(entity);
  print(position); // null
}
```

If you need to manually process deletions outside of `world.process()`, you can call:

```dart
world.entityManager.processDeletionQueue();
```

## Serialization Example

To serialize and deserialize entities:

```dart
void main() {
  final world = createBasicExampleWorld();
  
  // Create an entity
  final entity = world.createEntity({
    Position(0, 0),
    Velocity(1, 1),
  });

  // Set up serializers
  final entitySerialiser = EntitySerialiserJson(
    world.entityManager,
    {
      Position: PositionJsonSerializer(),
      Velocity: VelocityJsonSerializer(),
    },
  );

  // Serialize the entity
  final serialized = entitySerialiser.serializeEntityComponents(entity, [
    Position(0, 0),
    Velocity(1, 1),
  ]);
  print(serialized);

  // Deserialize the entity
  final deserializedEntity = entitySerialiser.deserializeEntity(serialized);
  final deserializedPosition = world.componentManager.getComponent<Position>(deserializedEntity);
  print('Deserialized position: (\${deserializedPosition?.x}, \${deserializedPosition?.y})');
}
```

## View Caching

**New in v1.6.0**: Entity views are now automatically cached for improved performance. When you call `viewForTypes()` or `view()` with the same archetype, the same `EntityView` instance is returned, eliminating redundant object creation.

```dart
// These return the same cached instance
final view1 = world.viewForTypes({Position, Velocity});
final view2 = world.viewForTypes({Position, Velocity});
assert(identical(view1, view2)); // true

// Clear the cache if needed (rare)
world.entityManager.clearViewCache();

// Check cache size
print(world.entityManager.viewCacheSize);
```

**Benefits:**
- Zero performance overhead - views are reused across systems
- Reduced memory allocations in hot paths
- Consistent view instances throughout the frame

## Migration Guide (v1.5 → v1.6)

### Component Access Updates

The old manual casting pattern has been replaced with the cleaner `EntityComposition.get<T>()` method:

**Old Pattern (v1.5 and earlier):**
```dart
class MovementSystem extends EntitySystem {
  @override
  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    final position = componentLists[Position]?[entity] as Position;
    final velocity = componentLists[Velocity]?[entity] as Velocity;
    position.x += velocity.x;
    position.y += velocity.y;
  }
}
```

**New Pattern (v1.6+):**
```dart
class MovementSystem extends EntitySystem {
  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final position = componentLists.get<Position>(entity)!;
    final velocity = componentLists.get<Velocity>(entity)!;
    position.x += velocity.x;
    position.y += velocity.y;
  }
}
```

### Breaking Changes

1. **System signature change**: `processEntity` now takes `EntityComposition` instead of `Map<Type, SparseList<Component>>`
2. **EntityView.componentLists**: Now returns `EntityComposition` instead of `Map`

### Backwards Compatibility

`EntityComposition` implements `Map<Type, SparseList<Component>>`, so old code continues to work:

```dart
// Still works (backwards compatible)
final position = componentLists[Position]?[entity] as Position?;

// But the new way is cleaner
final position = componentLists.get<Position>(entity);
```

### Deprecated Methods

The following methods are deprecated and will be removed in v2.0:
- `EntityView.getComponentArray(Type)` - Use `componentLists[type]` or `componentLists.listFor<T>()`
- `EntityView.getComponentForType(Type, Entity)` - Use `componentLists.get<T>(entity)`

## Contributing

Contributions are welcome! Please feel free to submit issues, fork the repository, and create pull requests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Hire us

Please checkout our work on www.wearemobilefirst.com