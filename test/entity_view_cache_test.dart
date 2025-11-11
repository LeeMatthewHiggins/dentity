import 'package:dentity/dentity.dart';
import 'package:dentity/dentity_examples.dart';
import 'package:test/test.dart';

World createTestWorld() {
  final componentManager = ComponentManager(
    archetypeManagerFactory: (types) => ArchetypeManagerBigInt(types),
    componentArrayFactories: {
      Position: () => ContiguousSparseList<Position>(),
      Velocity: () => ContiguousSparseList<Velocity>(),
      OtherComponent: () => ContiguousSparseList<OtherComponent>(),
    },
  );
  final entityManager = EntityManager(componentManager);
  return World(componentManager, entityManager, []);
}

void main() {
  group('EntityView Cache', () {
    test('viewForTypes returns same instance for same types', () {
      final world = createTestWorld();

      final view1 = world.viewForTypes({Position, Velocity});
      final view2 = world.viewForTypes({Position, Velocity});

      expect(identical(view1, view2), isTrue);
    });

    test('view returns same instance for same archetype', () {
      final world = createTestWorld();
      final archetype = world.entityManager.componentManager.archetypeManager
          .getArchetype({Position, Velocity});

      final view1 = world.view(archetype);
      final view2 = world.view(archetype);

      expect(identical(view1, view2), isTrue);
    });

    test('different types create different cached views', () {
      final world = createTestWorld();

      final view1 = world.viewForTypes({Position, Velocity});
      final view2 = world.viewForTypes({Position});
      final view3 = world.viewForTypes({Position, Velocity, OtherComponent});

      expect(identical(view1, view2), isFalse);
      expect(identical(view1, view3), isFalse);
      expect(identical(view2, view3), isFalse);
    });

    test('clearViewCache clears all cached views', () {
      final world = createTestWorld();

      final view1 = world.viewForTypes({Position, Velocity});
      world.entityManager.clearViewCache();
      final view2 = world.viewForTypes({Position, Velocity});

      expect(identical(view1, view2), isFalse);
    });

    test('cached views reflect entity changes', () {
      final world = createTestWorld();

      final view = world.viewForTypes({Position, Velocity});
      expect(view.length, 0);

      final entity1 = world.createEntity({Position(1, 1), Velocity(1, 1)});
      final entity2 = world.createEntity({Position(2, 2), Velocity(2, 2)});
      world.process();

      expect(view.length, 2);
      expect(view, contains(entity1));
      expect(view, contains(entity2));

      world.destroyEntity(entity1);
      world.entityManager.processDeletionQueue();

      expect(view.length, 1);
      expect(view, isNot(contains(entity1)));
      expect(view, contains(entity2));
    });

    test('cached views work correctly across multiple systems', () {
      final world = createTestWorld();

      final entity = world.createEntity({Position(0, 0), Velocity(5, 5)});
      world.process();

      final systemView = world.viewForTypes({Position, Velocity});
      final manualView = world.viewForTypes({Position, Velocity});

      expect(identical(systemView, manualView), isTrue);
      expect(systemView.length, 1);

      final position = systemView.getComponent<Position>(entity);
      expect(position?.x, 0);
      expect(position?.y, 0);
    });

    test('EntityManager extension methods use cache', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      final view1 = entityManager.viewForTypes({Position, Velocity});
      final view2 = entityManager.viewForTypes({Position, Velocity});

      expect(identical(view1, view2), isTrue);
    });
  });

  group('Memory Leak Detection', () {
    test('no view leak with repeated view creation', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      const iterations = 1000;
      final views = <EntityView>[];

      for (var i = 0; i < iterations; i++) {
        views.add(entityManager.viewForTypes({Position, Velocity}));
      }

      final uniqueViews = views.toSet();
      expect(uniqueViews.length, 1);
    });

    test('no view leak with multiple different view types', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      final typeSets = [
        {Position},
        {Velocity},
        {Position, Velocity},
        {Position, OtherComponent},
        {Velocity, OtherComponent},
        {Position, Velocity, OtherComponent},
      ];

      final viewMap = <Set<Type>, List<EntityView>>{};

      for (var typeSet in typeSets) {
        viewMap[typeSet] = [];
        for (var i = 0; i < 100; i++) {
          viewMap[typeSet]!.add(entityManager.viewForTypes(typeSet));
        }
      }

      for (var entry in viewMap.entries) {
        final uniqueViews = entry.value.toSet();
        expect(
          uniqueViews.length,
          1,
        );
      }

      expect(entityManager.viewCacheSize, typeSets.length);
    });

    test('cache size matches unique archetype count', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      entityManager.viewForTypes({Position});
      entityManager.viewForTypes({Velocity});
      entityManager.viewForTypes({Position, Velocity});
      entityManager.viewForTypes({Position});
      entityManager.viewForTypes({Velocity});

      expect(entityManager.viewCacheSize, 3);
    });

    test('no leak after entity creation and destruction cycles', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      final view = entityManager.viewForTypes({Position, Velocity});

      const cycles = 100;
      for (var i = 0; i < cycles; i++) {
        final entity = world.createEntity(
            {Position(i.toDouble(), i.toDouble()), Velocity(1, 1)});
        world.process();
        world.destroyEntity(entity);
        entityManager.processDeletionQueue();
      }

      final view2 = entityManager.viewForTypes({Position, Velocity});
      expect(identical(view, view2), isTrue);
      expect(view.length, 0);
      expect(entityManager.entities.length, 0);
    });

    test('no leak with archetype changes', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      final view1 = entityManager.viewForTypes({Position});
      final view2 = entityManager.viewForTypes({Position, Velocity});
      final view3 =
          entityManager.viewForTypes({Position, Velocity, OtherComponent});

      final entity = world.createEntity({Position(0, 0), Velocity(1, 1)});
      entityManager.processCreationQueue();

      expect(entityManager.viewCacheSize, 3);

      world.addComponents(entity, {OtherComponent()});

      final view1b = entityManager.viewForTypes({Position});
      final view2b = entityManager.viewForTypes({Position, Velocity});
      final view3b =
          entityManager.viewForTypes({Position, Velocity, OtherComponent});

      expect(identical(view1, view1b), isTrue);
      expect(identical(view2, view2b), isTrue);
      expect(identical(view3, view3b), isTrue);

      expect(entityManager.viewCacheSize, 3);
    });

    test('cache clears completely without residual references', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      entityManager.viewForTypes({Position});
      entityManager.viewForTypes({Velocity});
      entityManager.viewForTypes({Position, Velocity});

      expect(entityManager.viewCacheSize, 3);

      entityManager.clearViewCache();

      expect(entityManager.viewCacheSize, 0);

      entityManager.viewForTypes({Position});
      expect(entityManager.viewCacheSize, 1);
    });

    test('large scale view creation performance', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      final stopwatch = Stopwatch()..start();

      const iterations = 10000;
      for (var i = 0; i < iterations; i++) {
        entityManager.viewForTypes({Position, Velocity});
      }

      stopwatch.stop();

      expect(entityManager.viewCacheSize, 1);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('entity recycling works correctly with cached views', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      final view = entityManager.viewForTypes({Position, Velocity});

      final entity1 = world.createEntity({Position(10, 10), Velocity(1, 1)});
      entityManager.processCreationQueue();

      expect(view.length, 1);
      expect(view, contains(entity1));

      world.destroyEntity(entity1);
      entityManager.processDeletionQueue();

      expect(view.length, 0);

      final entity2 = world.createEntity({Position(20, 20), Velocity(2, 2)});
      entityManager.processCreationQueue();

      expect(entity2, entity1);
      expect(view.length, 1);
      expect(view, contains(entity2));

      final position = view.getComponent<Position>(entity2);
      expect(position?.x, 20);
      expect(position?.y, 20);
    });

    test('cache performs well with thousands of entities', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      const entityCount = 5000;
      final entities = <int>[];

      final view = entityManager.viewForTypes({Position, Velocity});

      for (var i = 0; i < entityCount; i++) {
        entities.add(world.createEntity({
          Position(i.toDouble(), i.toDouble()),
          Velocity(1, 1),
        }));
      }

      entityManager.processCreationQueue();

      expect(view.length, entityCount);
      expect(entityManager.viewCacheSize, 1);

      final view2 = entityManager.viewForTypes({Position, Velocity});
      expect(identical(view, view2), isTrue);

      var count = 0;
      for (final entity in view) {
        final position = view.getComponent<Position>(entity);
        expect(position, isNotNull);
        count++;
      }
      expect(count, entityCount);
    });

    test('multiple views with thousands of entities', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      const positionOnlyCount = 1000;
      const velocityOnlyCount = 1500;
      const bothCount = 2000;

      for (var i = 0; i < positionOnlyCount; i++) {
        world.createEntity({Position(i.toDouble(), i.toDouble())});
      }

      for (var i = 0; i < velocityOnlyCount; i++) {
        world.createEntity({Velocity(i.toDouble(), i.toDouble())});
      }

      for (var i = 0; i < bothCount; i++) {
        world.createEntity({
          Position(i.toDouble(), i.toDouble()),
          Velocity(i.toDouble(), i.toDouble()),
        });
      }

      entityManager.processCreationQueue();

      final positionView = entityManager.viewForTypes({Position});
      final velocityView = entityManager.viewForTypes({Velocity});
      final bothView = entityManager.viewForTypes({Position, Velocity});

      expect(positionView.length, positionOnlyCount + bothCount);
      expect(velocityView.length, velocityOnlyCount + bothCount);
      expect(bothView.length, bothCount);

      expect(entityManager.viewCacheSize, 3);

      final positionView2 = entityManager.viewForTypes({Position});
      final velocityView2 = entityManager.viewForTypes({Velocity});
      final bothView2 = entityManager.viewForTypes({Position, Velocity});

      expect(identical(positionView, positionView2), isTrue);
      expect(identical(velocityView, velocityView2), isTrue);
      expect(identical(bothView, bothView2), isTrue);
    });

    test('recycling thousands of entities with cached views', () {
      final world = createTestWorld();
      final entityManager = world.entityManager;

      const entityCount = 3000;
      final view = entityManager.viewForTypes({Position, Velocity});

      for (var cycle = 0; cycle < 3; cycle++) {
        final entities = <int>[];

        for (var i = 0; i < entityCount; i++) {
          entities.add(world.createEntity({
            Position(i.toDouble() * cycle, i.toDouble() * cycle),
            Velocity(cycle.toDouble(), cycle.toDouble()),
          }));
        }

        entityManager.processCreationQueue();
        expect(view.length, entityCount);

        for (final entity in entities) {
          world.destroyEntity(entity);
        }

        entityManager.processDeletionQueue();
        expect(view.length, 0);
      }

      expect(entityManager.viewCacheSize, 1);
      expect(view.length, 0);
    });
  });
}
