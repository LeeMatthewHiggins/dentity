import 'test_helpers.dart';
import 'package:test/test.dart';

void main() {
  group('WorldStats', () {
    test('stats are collected when enabled', () {
      final world = createBasicExampleWorld(enableStats: true);

      expect(world.stats, isNotNull);
      expect(world.stats!.entities.activeCount, equals(0));
      expect(world.stats!.frameCount, equals(0));

      world.createEntity({Position(0, 0), Velocity(1, 1)});
      world.createEntity({Position(1, 1), Velocity(2, 2)});

      world.process();

      expect(world.stats!.entities.totalCreated, equals(2));
      expect(world.stats!.entities.activeCount, equals(2));
      expect(world.stats!.frameCount, equals(1));
      expect(world.stats!.entities.peakCount, equals(2));
    });

    test('stats are not collected when disabled', () {
      final world = createBasicExampleWorld(enableStats: false);

      expect(world.stats, isNull);
    });

    test('entity recycling is tracked', () {
      final world = createBasicExampleWorld(enableStats: true);

      final entity1 = world.createEntity({Position(0, 0)});
      world.process();

      world.destroyEntity(entity1);
      world.process();

      final entity2 = world.createEntity({Position(1, 1)});
      world.process();

      expect(world.stats!.entities.recycledCount, equals(1));
      expect(entity2, equals(entity1));
    });

    test('deletion and creation queues are tracked', () {
      final world = createBasicExampleWorld(enableStats: true);

      world.createEntity({Position(0, 0)});
      world.createEntity({Position(1, 1)});

      expect(world.stats!.entities.creationQueueSize, equals(2));

      world.process();

      expect(world.stats!.entities.creationQueueSize, equals(0));
      expect(world.stats!.entities.activeCount, equals(2));

      world.destroyEntity(0);
      world.destroyEntity(1);

      expect(world.stats!.entities.deletionQueueSize, equals(2));

      world.process();

      expect(world.stats!.entities.deletionQueueSize, equals(0));
      expect(world.stats!.entities.activeCount, equals(0));
    });

    test('system stats are tracked', () {
      final world = createBasicExampleWorld(enableStats: true);

      for (var i = 0; i < 10; i++) {
        world.createEntity({Position(0, 0), Velocity(1, 1)});
      }

      world.process();
      world.process();
      world.process();

      expect(world.stats!.systems.length, greaterThan(0));

      final movementSystem = world.stats!.systems.firstWhere(
        (s) => s.name.contains('MovementSystem'),
      );

      expect(movementSystem.callCount, equals(3));
      expect(movementSystem.averageTimeMs, greaterThan(0));
      expect(movementSystem.minTime.inMicroseconds, greaterThan(0));
      expect(movementSystem.maxTime.inMicroseconds, greaterThan(0));
    });

    test('archetype stats are tracked', () {
      final world = createBasicExampleWorld(enableStats: true);

      world.createEntity({Position(0, 0), Velocity(1, 1)});
      world.createEntity({Position(1, 1), Velocity(2, 2)});
      world.createEntity({Position(2, 2)});

      world.process();

      expect(world.stats!.archetypes.totalArchetypes, greaterThan(0));
      expect(world.stats!.archetypes.totalEntities, equals(3));

      final mostUsed = world.stats!.archetypes.getMostUsedArchetypes();
      expect(mostUsed.length, greaterThan(0));
      expect(mostUsed.first.count, equals(2));
    });

    test('peak entity count is tracked', () {
      final world = createBasicExampleWorld(enableStats: true);

      for (var i = 0; i < 5; i++) {
        world.createEntity({Position(0, 0)});
      }
      world.process();

      expect(world.stats!.entities.peakCount, equals(5));

      world.destroyEntity(0);
      world.destroyEntity(1);
      world.process();

      expect(world.stats!.entities.activeCount, equals(3));
      expect(world.stats!.entities.peakCount, equals(5));

      for (var i = 0; i < 10; i++) {
        world.createEntity({Position(0, 0)});
      }
      world.process();

      expect(world.stats!.entities.peakCount, equals(13));
    });

    test('stats snapshot captures current state', () {
      final world = createBasicExampleWorld(enableStats: true);

      world.createEntity({Position(0, 0)});
      world.process();

      final snapshot1 = world.stats!.snapshot();

      world.createEntity({Position(1, 1)});
      world.process();

      final snapshot2 = world.stats!.snapshot();

      expect(snapshot1.entities.activeCount, equals(1));
      expect(snapshot2.entities.activeCount, equals(2));
      expect(snapshot1.frameCount, equals(1));
      expect(snapshot2.frameCount, equals(2));

      final diff = snapshot2.entities.diff(snapshot1.entities);
      expect(diff.totalCreated, equals(1));
      expect(diff.activeCount, equals(1));
    });

    test('stats can be reset', () {
      final world = createBasicExampleWorld(enableStats: true);

      for (var i = 0; i < 5; i++) {
        world.createEntity({Position(0, 0)});
      }
      world.process();
      world.process();

      expect(world.stats!.entities.totalCreated, equals(5));
      expect(world.stats!.frameCount, equals(2));

      world.stats!.reset();

      expect(world.stats!.entities.totalCreated, equals(0));
      expect(world.stats!.entities.activeCount, equals(0));
      expect(world.stats!.frameCount, equals(0));
    });

    test('recycle bin size is tracked', () {
      final world = createBasicExampleWorld(enableStats: true);

      final entity1 = world.createEntity({Position(0, 0)});
      final entity2 = world.createEntity({Position(1, 1)});
      world.process();

      world.destroyEntity(entity1);
      world.destroyEntity(entity2);
      world.process();

      expect(world.stats!.archetypes.totalInRecycleBin, equals(2));
    });
  });
}
