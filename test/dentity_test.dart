import 'dart:convert';

import 'package:dentity/dentity.dart';
import 'package:dentity/dentity_examples.dart';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'dentity_test.mocks.dart';

@GenerateMocks([EntityManagerListener])

World createWorldWithoutSystems() {
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
  group(
    'Test Functionality',
    () {
      test(
        'Test an example system runs only on entities it should',
        () {
          final world = createBasicExampleWorld();
          final testEntity = world.createEntity(
            {
              Position(0, 0),
              Velocity(1, 1),
            },
          );
          final controlEntity = world.createEntity(
            {
              Position(0, 0),
              OtherComponent(),
            },
          );

          world.process();

          final position = world.getComponent<Position>(testEntity);
          expect(position?.x, 1);
          expect(position?.y, 1);

          final controlPosition = world.getComponent<Position>(controlEntity);
          expect(controlPosition?.x, 0);
          expect(controlPosition?.y, 0);
        },
      );

      test(
        'Test an example system runs multiple times correctly',
        () {
          const runTimes = 10;
          final world = createBasicExampleWorld();
          final testEntity = world.createEntity(
            {
              Position(0, 0),
              Velocity(1, 1),
            },
          );

          for (var i = 0; i < runTimes; i++) {
            world.process();
          }

          final position = world.getComponent<Position>(testEntity);
          expect(position?.x, runTimes);
          expect(position?.y, runTimes);
        },
      );

      test(
        'Test system does not process entities without required components',
        () {
          final world = createBasicExampleWorld();
          final entityWithoutVelocity = world.createEntity({Position(0, 0)});
          final complexEntity = world.createEntity([
            Position(0, 0),
            Velocity(1, 1),
            ...allOtherTypesInstances,
          ]);

          world.process();

          final position = world.getComponent<Position>(entityWithoutVelocity);
          expect(position?.x, 0);
          expect(position?.y, 0);

          final complexEntityLastComponent =
              world.getComponent<OtherComponent65>(complexEntity);

          expect(complexEntityLastComponent, isNotNull);
        },
      );

      test(
        'Test system processes multiple entities correctly',
        () {
          final world = createBasicExampleWorld();

          final entity1 = world.createEntity({
            Position(0, 0),
            Velocity(1, 1),
          });
          final entity2 = world.createEntity({
            Position(10, 10),
            Velocity(-1, -1),
          });

          world.process();

          final position1 = world.getComponent<Position>(entity1);
          expect(position1?.x, 1);
          expect(position1?.y, 1);

          final position2 = world.getComponent<Position>(entity2);
          expect(position2?.x, 9);
          expect(position2?.y, 9);
        },
      );

      test(
        'Test system does not fail with no entities',
        () {
          final world = createBasicExampleWorld();
          // No entities created
          world.process();
          // No assertions needed, just ensuring no exceptions are thrown
        },
      );

      test(
        'Test system handles an entity removal correctly',
        () {
          final world = createBasicExampleWorld();

          final entity = world.createEntity({
            Position(0, 0),
            Velocity(1, 1),
          });
          world.process();

          world.destroyEntity(entity);
          world.process();

          // Ensure the entity is removed
          final position = world.getComponent<Position>(entity);
          expect(position, isNull);
        },
      );

      test(
        'Reuse of entities',
        () {
          final world = createBasicExampleWorld();
          world.createEntity({
            Position(0, 0),
            Velocity(1, 1),
          });
          final positionOnly = world.createEntity({
            Position(0, 0),
          });
          final entity2 = world.createEntity({
            Position(0, 0),
            Velocity(1, 1),
          });
          world.process();
          world.destroyEntity(positionOnly);
          world.destroyEntity(entity2);
          world.process();
          final recycledPositionOnly = world.createEntity({Position(0, 0)});
          world.process();
          expect(recycledPositionOnly, equals(positionOnly));
          final newPositionOnly = world.createEntity({Position(0, 0)});
          expect(newPositionOnly, isNot(recycledPositionOnly));
        },
      );

      test(
        'test mutation of entity',
        () {
          final world = createBasicExampleWorld();
          final entity1 = world.createEntity({Position(0, 0), Velocity(1, 1)});
          final entity2 = world.createEntity({Position(0, 0), Velocity(1, 1)});
          world.process();
          world.removeComponents(entity1, {Position});
          world.addComponents(entity2, {OtherComponent()});
          final position = world.getComponent<Position>(entity1);
          expect(position, isNull);
          final velocity = world.getComponent<Velocity>(entity1);
          expect(velocity, isNotNull);
          final otherComponent = world.getComponent<OtherComponent>(entity2);
          expect(otherComponent, isNotNull);
        },
      );

      test('test entity clone', () {
        final world = createWorldWithoutSystems();
        final entity1 = world.createEntity({Position(0, 0), Velocity(1, 1)});
        final entity2 = world.cloneEntity(entity1);
        world.process();
        final position1 = world.getComponent<Position>(entity1);
        final position2 = world.getComponent<Position>(entity2);
        expect(position1?.x, position2?.x);
        expect(position1?.y, position2?.y);
        final velocity1 = world.getComponent<Velocity>(entity1);
        final velocity2 = world.getComponent<Velocity>(entity2);
        expect(velocity1?.x, velocity2?.x);
        expect(velocity1?.y, velocity2?.y);
        position1?.x = 10;
        position1?.y = 10;
        expect(position2, isNot(position1));
        expect(position2?.x, 0);
        expect(position2?.y, 0);
        expect(position1?.x, 10);
        expect(position1?.y, 10);
      });

      test(
        'test view updates correctly',
        () {
          final world = createBasicExampleWorld();
          final entity1 = world.createEntity({
            Position(0, 0),
            Velocity(10, 10),
          });
          final entity2 = world.createEntity({
            Position(1, 1),
            Velocity(20, 20),
          });
          final view = world.viewForTypes({
            Position,
            Velocity,
          });
          world.process();

          final position1 = view.getComponent<Position>(entity1);
          expect(position1?.x, 10);
          expect(position1?.y, 10);
          final position2 = view.getComponent<Position>(entity2);
          expect(position2?.x, 21);
          expect(position2?.y, 21);
        },
      );
      test('Test Observers work correctly', () {
        final world = createBasicExampleWorld();
        final observer = MockEntityManagerListener();
        world.entityManager.addObserver(observer);
        final entity = world.createEntity({Position(0, 0), Velocity(1, 1)});

        world.addComponents(entity, {OtherComponent()});
        world.process();
        world.destroyEntity(entity);
        world.process();

        verify(observer.onEntityCreated(entity)).called(1);
        verify(observer.onEntityWillDestroy(entity)).called(1);
        verify(observer.onEntityArchetypeChanged(entity, any, any)).called(1);
      });

      test(
        'test entity factory creates entites correctly',
        () {
          final world = createWorldWithoutSystems();
          const prefabName = 'prefab1';
          final prefab1 = EntityPrefab(
            name: prefabName,
            components: {
              Position(0, 0),
              Velocity(10, 10),
            },
          );
          final factory = EntityFactory(prefabs: {prefab1});
          final entity = factory.fabricate(prefabName, world);
          world.process();
          final position = world.getComponent<Position>(entity);
          expect(position?.x, 0);
          expect(position?.y, 0);
          final velocity = world.getComponent<Velocity>(entity);
          expect(velocity?.x, 10);
          expect(velocity?.y, 10);

          final entity2 = factory.fabricate(prefabName, world);
          world.process();
          final position2 = world.getComponent<Position>(entity2);
          expect(entity2, isNot(entity));
          expect(position2?.x, 0);
          expect(position2?.y, 0);
        },
      );

      test(
        'test entity factory works with systems',
        () {
          final world = createBasicExampleWorld();
          const prefabName = 'prefab1';
          final prefab1 = EntityPrefab(
            name: prefabName,
            components: {
              Position(0, 0),
              Velocity(10, 10),
            },
          );
          final factory = EntityFactory(prefabs: {prefab1});
          final entity = factory.fabricate(prefabName, world);
          world.process();

          final positionAfterProcess = world.getComponent<Position>(entity);
          expect(positionAfterProcess?.x, 10);
          expect(positionAfterProcess?.y, 10);
        },
      );

      test(
        'test view filters correctly',
        () {
          final world = createWorldWithoutSystems();
          final entity1 = world.createEntity({
            Position(0, 0),
            Velocity(10, 10),
          });
          final entity2 = world.createEntity({
            Position(1, 1),
            Velocity(20, 20),
            OtherComponent(),
          });
          final entity3 = world.createEntity({
            Position(2, 2),
            Velocity(30, 30),
          });
          final entity4 = world.createEntity({Velocity(0, 0)});
          final entity5 = world.createEntity({
            OtherComponent(),
          });
          final positionView = world.viewForTypes({
            Position,
          });
          final positionVelocityView = world.viewForTypes({
            Position,
            Velocity,
          });
          world.process();

          expect(positionView, contains(entity1));
          expect(positionView, contains(entity2));
          expect(positionView, contains(entity3));
          expect(positionView, isNot(contains(entity4)));
          expect(positionView, isNot(contains(entity5)));

          expect(positionVelocityView, contains(entity1));
          expect(positionVelocityView, contains(entity2));
          expect(positionVelocityView, contains(entity3));
          expect(positionVelocityView, isNot(contains(entity4)));
          expect(positionVelocityView, isNot(contains(entity5)));

          final position1 = positionView.getComponent<Position>(entity1);
          expect(position1?.x, 0);
          expect(position1?.y, 0);
          final position2 = positionView.getComponent<Position>(entity2);
          expect(position2?.x, 1);
          expect(position2?.y, 1);
        },
      );

      test('test serialization works', () {
        final world = createWorldWithoutSystems();
        world.createEntity({
          Position(0, 0),
          Velocity(10, 10),
        });
        world.createEntity({
          Position(1, 1),
          Velocity(20, 20),
        });
        world.process();

        final EntitySerialiser entitySerialiser = EntitySerialiserJson(
          world.entityManager,
          {
            Position: PositionJsonSerializer(),
            Velocity: VelocityJsonSerializer(),
            OtherComponent: OtherComponentJsonSerializer(),
          },
        );

        final WorldSerialiser worldSerialiser = WorldSerialiserJson(
          world,
          entitySerialiser,
        );

        final json = worldSerialiser.serialize();
        expect(json, isNotNull);
        expect(json, isMap);
        final jsonMap = json as Map<String, dynamic>;
        expect(jsonMap[WorldSerialiserJson.entitiesField], isList);

        final first = jsonMap[WorldSerialiserJson.entitiesField].first;

        expect(first[EntitySerialiserJson.componentsField], isMap);
        final components =
            first[EntitySerialiserJson.componentsField] as Map<String, Object>;
        expect(components, isMap);
        final position = components['Position'] as Map<String, dynamic>;
        expect(position['x'], 0);
        expect(position['y'], 0);
        expect(components['Velocity'], isMap);
        final velocity = components['Velocity'] as Map<String, dynamic>;
        expect(velocity['x'], 10);
        expect(velocity['y'], 10);

        final jsonString = jsonEncode(json);
        expect(jsonString, isNotEmpty);

        final decoded = jsonDecode(jsonString);
        expect(decoded, isMap);

        final deserialized = worldSerialiser.deserialize(decoded);
        expect(deserialized, isNotEmpty);
        world.process();

        final deserializedPosition =
            world.getComponent<Position>(deserialized.first);

        expect(deserializedPosition?.x, 0);
        expect(deserializedPosition?.y, 0);

        final deserializedVelocity =
            world.getComponent<Velocity>(deserialized.first);

        expect(deserializedVelocity?.x, 10);
        expect(deserializedVelocity?.y, 10);
      });
    },
  );

  group(
    'Test Performance',
    () {
      const smallCount = BenchmarkConstants.smallEntityCount;
      const runTimes = BenchmarkConstants.defaultRunTimes;

      test(
        'Creation',
        () {
          final result = Benchmarks.creation(entityCount: smallCount);
          print('Creation benchmark took ${result.durationMs}ms for ${result.entityCount} entities');
          expect(result.durationMs, lessThan(100));
        },
      );

      test(
        'Processing',
        () {
          final result = Benchmarks.processing(
            entityCount: smallCount,
            runTimes: runTimes,
          );
          print('Processing benchmark took ${result.durationMs}ms for ${result.operations} operations');
          expect(result.durationMs, lessThan(100));
        },
      );

      test(
        'Removal',
        () {
          final result = Benchmarks.removal(entityCount: smallCount);
          print('Removal benchmark took ${result.durationMs}ms for ${result.entityCount} entities');
          expect(result.durationMs, lessThan(100));
        },
      );

      test(
        'Stats collection overhead',
        () {
          final result = Benchmarks.statsOverhead(
            entityCount: smallCount,
            runTimes: runTimes,
          );

          print('Without stats: ${result.durationWithoutStatsMs}ms');
          print('With stats: ${result.durationWithStatsMs}ms');
          print('Overhead: ${result.durationMs}ms (${result.overheadPercent.toStringAsFixed(2)}%)');
          print('Operations: ${result.operations}');

          expect(result.overheadPercent, lessThan(150));
        },
      );

      test(
        'Entity recycling performance',
        () {
          final result = Benchmarks.recycling(entityCount: smallCount);

          print('Entity recycling benchmark took ${result.durationMs}ms for ${result.entityCount} entities');
          print('Entities recycled: ${result.stats!.entities.recycledCount}');

          expect(result.stats!.entities.recycledCount, equals(smallCount));
          expect(result.durationMs, lessThan(200));
        },
      );

      test(
        'Mixed workload with stats',
        () {
          final result = Benchmarks.mixedWorkload(runTimes: runTimes);

          print('Mixed workload benchmark took ${result.durationMs}ms');
          print('Total frames: ${result.stats!.frameCount}');
          print('Entities created: ${result.stats!.entities.totalCreated}');
          print('Entities destroyed: ${result.stats!.entities.totalDestroyed}');
          print('Active entities: ${result.stats!.entities.activeCount}');
          print('Peak entities: ${result.stats!.entities.peakCount}');
          print('Entities recycled: ${result.stats!.entities.recycledCount}');

          for (final systemStats in result.stats!.systems) {
            print('${systemStats.name}: ${systemStats.averageTimeMs.toStringAsFixed(3)}ms avg');
          }

          expect(result.durationMs, lessThan(200));
          expect(result.stats!.frameCount, equals(runTimes));
        },
      );

      test(
        'Archetype distribution analysis',
        () {
          final world = createBasicExampleWorld(enableStats: true);

          for (var i = 0; i < 500; i++) {
            world.createEntity({Position(0, 0), Velocity(1, 1)});
          }
          for (var i = 0; i < 300; i++) {
            world.createEntity({Position(0, 0)});
          }
          for (var i = 0; i < 200; i++) {
            world.createEntity({Position(0, 0), Velocity(1, 1), OtherComponent()});
          }

          world.process();

          final mostUsed = world.stats!.archetypes.getMostUsedArchetypes();

          print('Total archetypes: ${world.stats!.archetypes.totalArchetypes}');
          print('Total entities: ${world.stats!.archetypes.totalEntities}');
          print('Most used archetypes:');
          for (var i = 0; i < mostUsed.length && i < 5; i++) {
            print('  ${mostUsed[i].archetype}: ${mostUsed[i].count} entities');
          }

          expect(world.stats!.archetypes.totalArchetypes, equals(3));
          expect(world.stats!.archetypes.totalEntities, equals(1000));
          expect(mostUsed.first.count, equals(500));
        },
      );
    },
  );
}
