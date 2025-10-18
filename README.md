
# Dentity - Example Usage

`Dentity` is a powerful and flexible Entity-Component-System (ECS) framework for Dart applications. This README provides a basic example to help you get started with the `Dentity` package.

## Introduction

This example demonstrates how to use `Dentity` to create a simple ECS world where entities have `Position` and `Velocity` components, and a `MovementSystem` updates their positions based on their velocities.

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  dentity: ^1.4.0
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
  void processEntity(Entity entity, Map<Type, SparseList<Component>> componentLists, Duration delta) {
    final position = componentLists[Position]?[entity] as Position;
    final velocity = componentLists[Velocity]?[entity] as Velocity;
    position.x += velocity.x;
    position.y += velocity.y;
  }
}
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

## Contributing

Contributions are welcome! Please feel free to submit issues, fork the repository, and create pull requests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Hire us

Please checkout our work on www.wearemobilefirst.com