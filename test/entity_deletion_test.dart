import 'package:dentity/dentity.dart';
import 'package:dentity/dentity_examples.dart';
import 'package:test/test.dart';

class Health extends Component {
  double hp;

  Health(this.hp);

  @override
  Health clone() => Health(hp);

  @override
  bool operator ==(Object other) => other is Health && hp == other.hp;

  @override
  int get hashCode => hp.hashCode;

  @override
  int compareTo(other) => other is Health ? hp.compareTo(other.hp) : -1;
}

class Tag extends Component {
  final String value;

  Tag(this.value);

  @override
  Tag clone() => Tag(value);

  @override
  bool operator ==(Object other) => other is Tag && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(other) => other is Tag ? value.compareTo(other.value) : -1;
}

class DestructionSystem extends EntitySystem {
  final Set<Entity> destroyedEntities = {};

  @override
  Set<Type> get filterTypes => {Position, Health};

  @override
  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    final health = componentLists[Health]?[entity] as Health?;
    if (health != null && health.hp <= 0) {
      destroyedEntities.add(entity);
      entityManager.destroyEntity(entity);
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
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    processedCount++;
  }
}

class CascadingDestructionSystem extends EntitySystem {
  final Set<Entity> destroyedEntities = {};

  @override
  Set<Type> get filterTypes => {Position, Tag};

  @override
  void processEntity(
    Entity entity,
    Map<Type, SparseList<Component>> componentLists,
    Duration delta,
  ) {
    final tag = componentLists[Tag]?[entity] as Tag?;
    if (tag != null && tag.value == 'destroy_all') {
      final allEntities = entityManager.viewForTypes({Position}).toList();
      for (final otherEntity in allEntities) {
        destroyedEntities.add(otherEntity);
        entityManager.destroyEntity(otherEntity);
      }
    }
  }
}

World _createDestructionTestWorld(List<System> systems) {
  final componentManager = ComponentManager(
    archetypeManagerFactory: (types) => ArchetypeManagerBigInt(types),
    componentArrayFactories: {
      Position: () => ContiguousSparseList<Position>(),
      Velocity: () => ContiguousSparseList<Velocity>(),
      Health: () => ContiguousSparseList<Health>(),
      Tag: () => ContiguousSparseList<Tag>(),
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
  group('Entity Deletion During System Processing', () {
    test('destroying current entity during processEntity does not crash', () {
      final destructionSystem = DestructionSystem();
      final world = _createDestructionTestWorld([destructionSystem]);

      final entity1 = world.createEntity({
        Position(0, 0),
        Health(100),
      });
      final entity2 = world.createEntity({
        Position(10, 10),
        Health(0),
      });
      final entity3 = world.createEntity({
        Position(20, 20),
        Health(50),
      });

      world.process();

      expect(destructionSystem.destroyedEntities, contains(entity2));
      expect(world.getComponent<Position>(entity1), isNotNull);
      expect(world.getComponent<Position>(entity2), isNull);
      expect(world.getComponent<Position>(entity3), isNotNull);
    });

    test('destroying multiple entities with same archetype during iteration',
        () {
      final destructionSystem = DestructionSystem();
      final world = _createDestructionTestWorld([destructionSystem]);

      final entities = <Entity>[];
      for (var i = 0; i < 10; i++) {
        entities.add(world.createEntity({
          Position(i.toDouble(), i.toDouble()),
          Health(i <= 5 ? 0 : 100),
        }));
      }

      world.process();

      for (var i = 0; i <= 5; i++) {
        expect(world.getComponent<Position>(entities[i]), isNull);
      }
      for (var i = 6; i < 10; i++) {
        expect(world.getComponent<Position>(entities[i]), isNotNull);
      }
    });

    test('destroying first entity in iteration', () {
      final destructionSystem = DestructionSystem();
      final world = _createDestructionTestWorld([destructionSystem]);

      final entity1 = world.createEntity({
        Position(0, 0),
        Health(0),
      });
      final entity2 = world.createEntity({
        Position(10, 10),
        Health(100),
      });

      world.process();

      expect(world.getComponent<Position>(entity1), isNull);
      expect(world.getComponent<Position>(entity2), isNotNull);
    });

    test('destroying last entity in iteration', () {
      final destructionSystem = DestructionSystem();
      final world = _createDestructionTestWorld([destructionSystem]);

      final entity1 = world.createEntity({
        Position(0, 0),
        Health(100),
      });
      final entity2 = world.createEntity({
        Position(10, 10),
        Health(0),
      });

      world.process();

      expect(world.getComponent<Position>(entity1), isNotNull);
      expect(world.getComponent<Position>(entity2), isNull);
    });

    test('destroying middle entity in iteration', () {
      final destructionSystem = DestructionSystem();
      final world = _createDestructionTestWorld([destructionSystem]);

      final entity1 = world.createEntity({
        Position(0, 0),
        Health(100),
      });
      final entity2 = world.createEntity({
        Position(10, 10),
        Health(0),
      });
      final entity3 = world.createEntity({
        Position(20, 20),
        Health(100),
      });

      world.process();

      expect(world.getComponent<Position>(entity1), isNotNull);
      expect(world.getComponent<Position>(entity2), isNull);
      expect(world.getComponent<Position>(entity3), isNotNull);
    });

    test('system processes correct number of entities after deletion', () {
      final destructionSystem = DestructionSystem();
      final countingSystem = CountingSystem();
      final world = _createDestructionTestWorld([
        destructionSystem,
        countingSystem,
      ]);

      final entity1 = world.createEntity({
        Position(0, 0),
        Health(0),
      });
      final entity2 = world.createEntity({
        Position(10, 10),
        Health(100),
      });
      final entity3 = world.createEntity({
        Position(20, 20),
        Health(0),
      });

      world.process();

      expect(countingSystem.processedCount, equals(1));
      expect(world.getComponent<Position>(entity1), isNull);
      expect(world.getComponent<Position>(entity2), isNotNull);
      expect(world.getComponent<Position>(entity3), isNull);
    });

    test('cascading deletion where one entity triggers deletion of others', () {
      final cascadingSystem = CascadingDestructionSystem();
      final world = _createDestructionTestWorld([cascadingSystem]);

      final entity1 = world.createEntity({
        Position(0, 0),
        Tag('normal'),
      });
      final entity2 = world.createEntity({
        Position(10, 10),
        Tag('destroy_all'),
      });
      final entity3 = world.createEntity({
        Position(20, 20),
        Tag('normal'),
      });

      world.process();

      expect(world.getComponent<Position>(entity1), isNull);
      expect(world.getComponent<Position>(entity2), isNull);
      expect(world.getComponent<Position>(entity3), isNull);
    });

    test('entity deletion across different archetypes during iteration', () {
      final destructionSystem = DestructionSystem();
      final world = _createDestructionTestWorld([destructionSystem]);

      final entity1 = world.createEntity({
        Position(0, 0),
        Health(0),
      });
      final entity2 = world.createEntity({
        Position(10, 10),
        Health(100),
        Velocity(1, 1),
      });
      final entity3 = world.createEntity({
        Position(20, 20),
        Health(0),
        Tag('test'),
      });

      world.process();

      expect(world.getComponent<Position>(entity1), isNull);
      expect(world.getComponent<Position>(entity2), isNotNull);
      expect(world.getComponent<Position>(entity3), isNull);
    });

    test('deleting all entities during iteration', () {
      final destructionSystem = DestructionSystem();
      final world = _createDestructionTestWorld([destructionSystem]);

      final entities = <Entity>[];
      for (var i = 0; i < 5; i++) {
        entities.add(world.createEntity({
          Position(i.toDouble(), i.toDouble()),
          Health(0),
        }));
      }

      world.process();

      for (final entity in entities) {
        expect(world.getComponent<Position>(entity), isNull);
      }
    });

    test('entity deletion with multiple systems processing same entities', () {
      final destructionSystem = DestructionSystem();
      final movementSystem = MovementSystem();
      final countingSystem = CountingSystem();
      final world = _createDestructionTestWorld([
        movementSystem,
        destructionSystem,
        countingSystem,
      ]);

      final entity1 = world.createEntity({
        Position(0, 0),
        Velocity(1, 1),
        Health(0),
      });
      final entity2 = world.createEntity({
        Position(10, 10),
        Velocity(1, 1),
        Health(100),
      });

      world.process();

      expect(countingSystem.processedCount, equals(1));
      expect(world.getComponent<Position>(entity1), isNull);
      expect(world.getComponent<Position>(entity2), isNotNull);
    });

    test('entity recycling works correctly after deletion during iteration',
        () {
      final destructionSystem = DestructionSystem();
      final world = _createDestructionTestWorld([destructionSystem]);

      final entity1 = world.createEntity({
        Position(0, 0),
        Health(0),
      });

      world.process();
      expect(world.getComponent<Position>(entity1), isNull);

      final recycledEntity = world.createEntity({
        Position(100, 100),
        Health(100),
      });
      world.process();

      expect(recycledEntity, equals(entity1));
      expect(world.getComponent<Position>(recycledEntity), isNotNull);
      final position = world.getComponent<Position>(recycledEntity);
      expect(position?.x, equals(100));
      expect(position?.y, equals(100));
    });

    test('sequential deletions across multiple process cycles', () {
      final destructionSystem = DestructionSystem();
      final world = _createDestructionTestWorld([destructionSystem]);

      final entities = <Entity>[];
      for (var i = 0; i < 5; i++) {
        entities.add(world.createEntity({
          Position(i.toDouble(), i.toDouble()),
          Health(100 - i * 25),
        }));
      }

      for (var cycle = 0; cycle < 5; cycle++) {
        world.process();

        for (final entity in entities) {
          final health = world.getComponent<Health>(entity);
          if (health != null) {
            health.hp -= 25;
          }
        }
      }

      for (final entity in entities) {
        expect(world.getComponent<Position>(entity), isNull);
      }
    });

    test('view remains consistent after entity deletion during iteration', () {
      final destructionSystem = DestructionSystem();
      final world = _createDestructionTestWorld([destructionSystem]);

      final entity1 = world.createEntity({
        Position(0, 0),
        Health(100),
      });
      final entity2 = world.createEntity({
        Position(10, 10),
        Health(100),
      });

      final view = world.viewForTypes({Position});
      world.process();
      final initialCount = view.length;
      expect(initialCount, equals(2));

      final health1 = world.getComponent<Health>(entity1);
      health1?.hp = 0;

      world.process();

      final afterDeletionCount = view.length;
      expect(afterDeletionCount, equals(1));
      expect(view.contains(entity1), isFalse);
      expect(view.contains(entity2), isTrue);
    });

    test('destroying entities with complex component combinations', () {
      final destructionSystem = DestructionSystem();
      final world = _createDestructionTestWorld([destructionSystem]);

      final entity1 = world.createEntity({
        Position(0, 0),
        Health(0),
        Velocity(1, 1),
        Tag('test1'),
      });
      final entity2 = world.createEntity({
        Position(10, 10),
        Health(100),
        Velocity(2, 2),
        Tag('test2'),
      });
      final entity3 = world.createEntity({
        Position(20, 20),
        Health(0),
        Tag('test3'),
      });

      world.process();

      expect(world.getComponent<Position>(entity1), isNull);
      expect(world.getComponent<Velocity>(entity1), isNull);
      expect(world.getComponent<Tag>(entity1), isNull);

      expect(world.getComponent<Position>(entity2), isNotNull);
      expect(world.getComponent<Velocity>(entity2), isNotNull);
      expect(world.getComponent<Tag>(entity2), isNotNull);

      expect(world.getComponent<Position>(entity3), isNull);
      expect(world.getComponent<Tag>(entity3), isNull);
    });
  });
}
