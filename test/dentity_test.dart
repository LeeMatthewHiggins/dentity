import 'package:dentity/dentity.dart';
import 'package:test/test.dart';

void main() {
  group(
    'Test Functionality',
    () {
      test(
        'Test an example system runs only on entities it should',
        () {
          final world = createBasicExampleWorld();
          final testEntity = world.createEntity(
            [
              Position(0, 0),
              Velocity(1, 1),
            ],
          );
          final controlEntity = world.createEntity(
            [
              Position(0, 0),
              OtherComponent(),
            ],
          );

          world.process();

          final position = world.getComponent<Position>(testEntity);
          expect(position!.x, 1);
          expect(position.y, 1);

          final controlPosition = world.getComponent<Position>(controlEntity);
          expect(controlPosition!.x, 0);
          expect(controlPosition.y, 0);
        },
      );

      test(
        'Test an example system runs multiple times correctly',
        () {
          const runTimes = 10;
          final world = createBasicExampleWorld();
          final testEntity = world.createEntity(
            [
              Position(0, 0),
              Velocity(1, 1),
            ],
          );

          for (var i = 0; i < runTimes; i++) {
            world.process();
          }

          final position = world.getComponent<Position>(testEntity);
          expect(position!.x, runTimes);
          expect(position.y, runTimes);
        },
      );

      test(
        'Test system does not process entities without required components',
        () {
          final world = createBasicExampleWorld();
          final entityWithoutVelocity = world.createEntity([Position(0, 0)]);

          world.process();

          final position = world.getComponent<Position>(entityWithoutVelocity);
          expect(position!.x, 0);
          expect(position.y, 0);
        },
      );

      test(
        'Test system processes multiple entities correctly',
        () {
          final world = createBasicExampleWorld();

          final entity1 = world.createEntity([Position(0, 0), Velocity(1, 1)]);
          final entity2 =
              world.createEntity([Position(10, 10), Velocity(-1, -1)]);

          world.process();

          final position1 = world.getComponent<Position>(entity1);
          expect(position1!.x, 1);
          expect(position1.y, 1);

          final position2 = world.getComponent<Position>(entity2);
          expect(position2!.x, 9);
          expect(position2.y, 9);
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

          final entity = world.createEntity([Position(0, 0), Velocity(1, 1)]);
          world.process();

          world.destroyEntity(entity);
          world.process();

          // Ensure the entity is removed
          final position = world.getComponent<Position>(entity);
          expect(position, isNull);
        },
      );

      test('Reuse of entities', () {
        final world = createBasicExampleWorld();
        world.createEntity([Position(0, 0), Velocity(1, 1)]);
        final positionOnly = world.createEntity([Position(0, 0)]);
        final entity2 = world.createEntity([Position(0, 0), Velocity(1, 1)]);
        world.destroyEntity(positionOnly);
        world.destroyEntity(entity2);
        final recycledPositionOnly = world.createEntity([Position(0, 0)]);
        expect(recycledPositionOnly, equals(positionOnly));
        final newPositionOnly = world.createEntity([Position(0, 0)]);
        expect(newPositionOnly, isNot(recycledPositionOnly));
      });

      test('test mutation of entity', () {
        final world = createBasicExampleWorld();
        final entity1 = world.createEntity({Position(0, 0), Velocity(1, 1)});
        final entity2 = world.createEntity({Position(0, 0), Velocity(1, 1)});
        world.removeComponents(entity1, {Position});
        world.addComponents(entity2, {OtherComponent()});
        final position = world.getComponent<Position>(entity1);
        expect(position, isNull);
        final velocity = world.getComponent<Velocity>(entity1);
        expect(velocity, isNotNull);

        final otherComponent = world.getComponent<OtherComponent>(entity2);
        expect(otherComponent, isNotNull);
      });
    },
  );

  group('Test Performance', () {
    const runTimes = 120; // 120fps
    const entityCount =
        2000; // runtimes * entityCount is number of entity process ops
    test('Creation', () {
      final world = createBasicExampleWorld();
      final sw = Stopwatch()..start();
      for (var i = 0; i < entityCount; i++) {
        world.createEntity([Position(0, 0), Velocity(1, 1)]);
      }
      sw.stop();
      print('Creation benchmark took ${sw.elapsedMilliseconds}ms');
      expect(sw.elapsedMilliseconds, lessThan(32));
    });

    test('Processing', () {
      final world = createBasicExampleWorld();
      for (var i = 0; i < entityCount; i++) {
        world.createEntity([Position(0, 0), Velocity(1, 1)]);
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < runTimes; i++) {
        world.process();
      }
      sw.stop();
      print('Processing benchmark took ${sw.elapsedMilliseconds}ms');
      expect(sw.elapsedMilliseconds, lessThan(16));
    });

    test('Removal', () {
      final world = createBasicExampleWorld();
      final entities = <Entity>[];
      for (var i = 0; i < entityCount; i++) {
        entities.add(world.createEntity([Position(0, 0), Velocity(1, 1)]));
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < entityCount; i++) {
        world.destroyEntity(entities[i]);
      }
      sw.stop();
      print('Removal benchmark took ${sw.elapsedMilliseconds}ms');
      expect(sw.elapsedMilliseconds, lessThan(32));
    });
  });
}
