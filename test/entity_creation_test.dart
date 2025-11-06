import 'package:dentity/dentity.dart';
import 'package:dentity/dentity_examples.dart';
import 'package:test/test.dart';

class SpawnTag extends Component {
  final int count;

  SpawnTag(this.count);

  @override
  SpawnTag clone() => SpawnTag(count);

  @override
  bool operator ==(Object other) => other is SpawnTag && count == other.count;

  @override
  int get hashCode => count.hashCode;

  @override
  int compareTo(other) => other is SpawnTag ? count.compareTo(other.count) : -1;
}

class SpawnerSystem extends EntitySystem {
  final Set<Entity> spawnedEntities = {};

  @override
  Set<Type> get filterTypes => {Position, SpawnTag};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    final tag = componentLists.get<SpawnTag>(entity);
    if (tag != null) {
      for (var i = 0; i < tag.count; i++) {
        final spawned = entityManager.createEntity({
          Position(i.toDouble(), i.toDouble()),
        });
        spawnedEntities.add(spawned);
      }
    }
  }
}

class CountingSystem extends EntitySystem {
  int processedCount = 0;

  @override
  Set<Type> get filterTypes => {Position};

  @override
  void processEntity(
    Entity entity,
    EntityComposition componentLists,
    Duration delta,
  ) {
    processedCount++;
  }
}

World _createCreationTestWorld(List<System> systems) {
  final componentManager = ComponentManager(
    archetypeManagerFactory: (types) => ArchetypeManagerBigInt(types),
    componentArrayFactories: {
      Position: () => ContiguousSparseList<Position>(),
      Velocity: () => ContiguousSparseList<Velocity>(),
      SpawnTag: () => ContiguousSparseList<SpawnTag>(),
    },
  );
  final entityManager = EntityManager(componentManager);
  return World(
    componentManager,
    entityManager,
    systems,
  );
}

void main() {
  group('Entity Creation During System Processing', () {
    test('creating entities during processEntity does not process them immediately', () {
      final spawnerSystem = SpawnerSystem();
      final countingSystem = CountingSystem();
      final world = _createCreationTestWorld([
        spawnerSystem,
        countingSystem,
      ]);

      world.createEntity({
        Position(0, 0),
        SpawnTag(3),
      });

      world.process();

      expect(spawnerSystem.spawnedEntities.length, equals(3));
      expect(countingSystem.processedCount, equals(1));
    });

    test('created entities are processed in next frame', () {
      final spawnerSystem = SpawnerSystem();
      final countingSystem = CountingSystem();
      final world = _createCreationTestWorld([
        spawnerSystem,
        countingSystem,
      ]);

      world.createEntity({
        Position(0, 0),
        SpawnTag(3),
      });

      world.process();
      expect(countingSystem.processedCount, equals(1));

      countingSystem.processedCount = 0;
      world.process();
      expect(countingSystem.processedCount, equals(4));
    });

    test('entities created before process are available immediately', () {
      final countingSystem = CountingSystem();
      final world = _createCreationTestWorld([countingSystem]);

      world.createEntity({Position(0, 0)});
      world.createEntity({Position(1, 1)});
      world.createEntity({Position(2, 2)});

      world.process();

      expect(countingSystem.processedCount, equals(3));
    });

    test('entities created by first system not processed by second system in same frame', () {
      final spawnerSystem = SpawnerSystem();
      final countingSystem = CountingSystem();
      final world = _createCreationTestWorld([
        spawnerSystem,
        countingSystem,
      ]);

      world.createEntity({
        Position(0, 0),
        SpawnTag(5),
      });

      world.process();

      expect(countingSystem.processedCount, equals(1));
    });

    test('multiple systems creating entities', () {
      final spawnerSystem1 = SpawnerSystem();
      final spawnerSystem2 = SpawnerSystem();
      final countingSystem = CountingSystem();
      final world = _createCreationTestWorld([
        spawnerSystem1,
        spawnerSystem2,
        countingSystem,
      ]);

      world.createEntity({
        Position(0, 0),
        SpawnTag(2),
      });

      world.process();

      expect(spawnerSystem1.spawnedEntities.length, equals(2));
      expect(spawnerSystem2.spawnedEntities.length, equals(2));
      expect(countingSystem.processedCount, equals(1));
    });

    test('entity creation queue processes before systems run', () {
      final countingSystem = CountingSystem();
      final world = _createCreationTestWorld([countingSystem]);

      world.createEntity({Position(0, 0)});
      world.createEntity({Position(1, 1)});

      world.process();

      expect(countingSystem.processedCount, equals(2));
    });

    test('entity recycling works with creation queue', () {
      final world = _createCreationTestWorld([]);

      final entity1 = world.createEntity({Position(0, 0)});
      world.entityManager.processCreationQueue();

      world.destroyEntity(entity1);
      world.entityManager.processDeletionQueue();

      final recycledEntity = world.createEntity({Position(10, 10)});
      world.entityManager.processCreationQueue();

      expect(recycledEntity, equals(entity1));
      final position = world.getComponent<Position>(recycledEntity);
      expect(position?.x, equals(10));
      expect(position?.y, equals(10));
    });

    test('cascading entity creation', () {
      final spawnerSystem = SpawnerSystem();
      final countingSystem = CountingSystem();
      final world = _createCreationTestWorld([
        spawnerSystem,
        countingSystem,
      ]);

      final spawner = world.createEntity({
        Position(0, 0),
        SpawnTag(3),
      });

      world.process();
      expect(countingSystem.processedCount, equals(1));

      world.removeComponents(spawner, {SpawnTag});

      countingSystem.processedCount = 0;
      world.process();
      expect(countingSystem.processedCount, equals(4));

      countingSystem.processedCount = 0;
      world.process();
      expect(countingSystem.processedCount, equals(4));
    });

    test('creation and deletion in same frame', () {
      final spawnerSystem = SpawnerSystem();
      final world = _createCreationTestWorld([spawnerSystem]);

      final entity = world.createEntity({
        Position(0, 0),
        SpawnTag(2),
      });

      world.destroyEntity(entity);
      world.process();

      expect(spawnerSystem.spawnedEntities.length, equals(2));
      expect(world.getComponent<Position>(entity), isNull);

      world.process();

      for (final spawned in spawnerSystem.spawnedEntities) {
        expect(world.getComponent<Position>(spawned), isNotNull);
      }
    });

    test('view reflects entities after creation queue processed', () {
      final world = _createCreationTestWorld([]);

      world.createEntity({Position(0, 0)});
      world.createEntity({Position(1, 1)});

      final viewBeforeProcess = world.viewForTypes({Position});
      expect(viewBeforeProcess.length, equals(0));

      world.entityManager.processCreationQueue();

      final viewAfterProcess = world.viewForTypes({Position});
      expect(viewAfterProcess.length, equals(2));
    });
  });
}
